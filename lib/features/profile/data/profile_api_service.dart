import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import '../domain/profile_models.dart';

class ProfileApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String endpointVolunteersProfile =
      ApiConstants.endpointVolunteersProfile;
  static const String endpointLoginHistory = ApiConstants.endpointLoginHistory;
  static const String endpointUpdateProfile = ApiConstants.endpointUpdateProfile;

  /// Fetch full detailed volunteer profile using GET /api/volunteers/{volunteer_id}
  /// or GET /api/volunteers/profile?volunteer_code=...
  Future<DetailedVolunteerProfile> getDetailedProfile([
    String? volunteerIdentifier,
  ]) async {
    final localDetailed = await SessionManager.getDetailedProfile();
    final token = await SessionManager.getToken();

    try {
      // 1. Resolve volunteer_code or volunteer_id from identifier or cached session
      String? volunteerCode;
      int? volunteerId;

      final ident = volunteerIdentifier?.trim() ?? '';
      if (ident.isNotEmpty) {
        if (RegExp(r'^\d+$').hasMatch(ident)) {
          volunteerId = int.tryParse(ident);
        } else {
          volunteerCode = ident;
        }
      }

      if (volunteerCode == null && volunteerId == null) {
        final currentSession = await SessionManager.getUserSession();
        if (currentSession != null) {
          if (currentSession.volunteerId.isNotEmpty) {
            if (RegExp(r'^\d+$').hasMatch(currentSession.volunteerId)) {
              volunteerId = int.tryParse(currentSession.volunteerId);
            } else {
              volunteerCode = currentSession.volunteerId;
            }
          }
          if (volunteerId == null && currentSession.numericVolunteerId != null && currentSession.numericVolunteerId! > 0) {
            volunteerId = currentSession.numericVolunteerId;
          }
        }
      }

      if (volunteerId == null) {
        final cachedNumId = await SessionManager.getNumericVolunteerId();
        if (cachedNumId != null && cachedNumId > 0) {
          volunteerId = cachedNumId;
        }
      }

      // 2. Build URL: Prioritize GET /api/volunteers/{id}
      final String requestUrl;
      if (volunteerId != null && volunteerId > 0) {
        requestUrl = ApiConstants.endpointVolunteer(volunteerId);
      } else {
        requestUrl = ApiConstants.endpointVolunteerProfileQuery(
          volunteerCode: volunteerCode,
          volunteerId: volunteerId,
        );
      }

      debugPrint('[PROFILE] GET $requestUrl (token: ${token != null && token.isNotEmpty ? "present" : "none"})');

      final response = await http
          .get(
            Uri.parse(requestUrl),
            headers: ApiConstants.defaultHeaders(token: token),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[PROFILE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          var fetchedProfile =
              DetailedVolunteerProfile.fromVolunteerProfileJson(decoded);

          // Dynamically fetch institution metadata for the volunteer's department
          if (fetchedProfile.departmentId != null && fetchedProfile.departmentId! > 0) {
            try {
              final institutions = await DemographicRepository.fetchInstitutionsFromApi(
                fetchedProfile.departmentId!,
              );
              if (institutions.isNotEmpty) {
                final matched = institutions.firstWhere(
                  (i) => i.institutionTypeId == fetchedProfile.institutionTypeId,
                  orElse: () => institutions.first,
                );
                final fieldLabel = institutions.first.fieldLabel;
                fetchedProfile = fetchedProfile.copyWith(
                  institutionFieldLabel: fieldLabel,
                  institutionTypeName:
                      fetchedProfile.institutionTypeId == matched.institutionTypeId
                          ? matched.optionName
                          : fetchedProfile.institutionTypeName,
                );
              }
            } catch (err) {
              debugPrint('[PROFILE] Could not load institution metadata: $err');
            }
          }

          final mergedProfile = fetchedProfile.merge(localDetailed);

          // Persist latest profile to local cache for instant offline access
          await SessionManager.saveDetailedProfile(mergedProfile);

          // Keep cached UserSession in sync across the app (dashboard, drawer, etc.)
          final session = await SessionManager.getUserSession();
          if (session != null) {
            final resolvedDept = (mergedProfile.departmentName != null &&
                    mergedProfile.departmentName!.trim().isNotEmpty)
                ? mergedProfile.departmentName!.trim()
                : (mergedProfile.cohvType != null &&
                        mergedProfile.cohvType!.trim().isNotEmpty
                    ? mergedProfile.cohvType!.trim()
                    : session.sector);

            final updatedSession = session.copyWith(
              volunteerId: mergedProfile.volunteerId,
              numericVolunteerId: mergedProfile.numericVolunteerId,
              fullName: mergedProfile.fullName,
              mobile: mergedProfile.mobileNumber,
              email: mergedProfile.email,
              sector: resolvedDept,
              departmentId: mergedProfile.departmentId ?? session.departmentId,
              departmentName: mergedProfile.departmentName ?? session.departmentName,
              status: mergedProfile.status,
              photoPath: mergedProfile.photoUrl,
              stateName: mergedProfile.state,
              districtName: mergedProfile.district,
              blockName: mergedProfile.block,
              gramPanchayatName: mergedProfile.panchayat,
              villageName: mergedProfile.village,
              supervisorName: mergedProfile.supervisor,
              supervisorId: mergedProfile.supervisorId,
            );
            await SessionManager.saveSession(updatedSession);
          }

          return mergedProfile;
        } else {
          throw Exception('Unexpected response format from volunteer profile API.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(
          'Session expired. Please sign in again.',
          statusCode: response.statusCode,
        );
      } else {
        throw Exception(
          'Failed to load volunteer profile (HTTP ${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[PROFILE] Error fetching volunteer profile: $e');

      if (e is AuthException) {
        rethrow;
      }

      // Fallback 1: Return locally cached DetailedVolunteerProfile
      if (localDetailed != null) {
        debugPrint('[PROFILE] Serving locally cached DetailedVolunteerProfile');
        return localDetailed;
      }

      // Fallback 2: Return cached UserSession
      final cachedSession = await SessionManager.getUserSession();
      if (cachedSession != null) {
        debugPrint('[PROFILE] Serving fallback from cached UserSession');
        return DetailedVolunteerProfile.fromUserSession(cachedSession);
      }

      rethrow;
    }
  }

  /// Update volunteer profile using PUT /api/volunteers/{volunteer_id}
  Future<bool> updateProfile(
    DetailedVolunteerProfile updatedProfile, {
    File? photoFile,
    http.Client? client,
  }) async {
    final token = await SessionManager.getToken();

    // 1. Resolve numeric volunteer ID
    int? volunteerId = updatedProfile.numericVolunteerId;
    if (volunteerId == null || volunteerId <= 0) {
      volunteerId = int.tryParse(updatedProfile.volunteerId);
    }
    if (volunteerId == null || volunteerId <= 0) {
      final match = RegExp(r'\d+$').firstMatch(updatedProfile.volunteerId);
      if (match != null) {
        volunteerId = int.tryParse(match.group(0)!);
      }
    }
    if (volunteerId == null || volunteerId <= 0) {
      final session = await SessionManager.getUserSession();
      volunteerId = session?.numericVolunteerId ??
          (session != null ? int.tryParse(session.volunteerId) : null);
      if ((volunteerId == null || volunteerId <= 0) && session != null) {
        final match = RegExp(r'\d+$').firstMatch(session.volunteerId);
        if (match != null) {
          volunteerId = int.tryParse(match.group(0)!);
        }
      }
    }
    if (volunteerId == null || volunteerId <= 0) {
      volunteerId = await SessionManager.getNumericVolunteerId();
    }

    if (volunteerId == null || volunteerId <= 0) {
      throw Exception('Unable to resolve numeric volunteer ID for profile update.');
    }

    final targetUrl = ApiConstants.endpointVolunteer(volunteerId);

    // 2. Resolve LGD location codes
    final session = await SessionManager.getUserSession();
    final stateLgd = updatedProfile.stateLgdCode ?? session?.stateLgdCode;
    final districtLgd = updatedProfile.districtLgdCode ?? session?.districtLgdCode;
    final blockLgd = updatedProfile.blockLgdCode ?? session?.blockLgdCode;
    final gpLgd = updatedProfile.gramPanchayatLgdCode ?? session?.gramPanchayatLgdCode;
    final villageLgd = updatedProfile.villageLgdCode ?? session?.villageLgdCode;

    // 3. Immediately persist locally so changes are visible across the app
    final localSavedProfile = updatedProfile.copyWith(
      numericVolunteerId: volunteerId,
      stateLgdCode: stateLgd,
      districtLgdCode: districtLgd,
      blockLgdCode: blockLgd,
      gramPanchayatLgdCode: gpLgd,
      villageLgdCode: villageLgd,
    );
    await SessionManager.saveDetailedProfile(localSavedProfile);

    // 4. Keep UserSession synchronized
    final currentSession = await SessionManager.getUserSession();
    if (currentSession != null) {
      final resolvedDept = (updatedProfile.departmentName != null &&
              updatedProfile.departmentName!.trim().isNotEmpty)
          ? updatedProfile.departmentName!.trim()
          : (updatedProfile.cohvType != null &&
                  updatedProfile.cohvType!.trim().isNotEmpty
              ? updatedProfile.cohvType!.trim()
              : currentSession.sector);

      final newSession = currentSession.copyWith(
        fullName: updatedProfile.fullName,
        mobile: updatedProfile.mobileNumber,
        email: updatedProfile.email,
        photoPath: updatedProfile.photoUrl,
        sector: resolvedDept,
        departmentId: updatedProfile.departmentId ?? currentSession.departmentId,
        departmentName: updatedProfile.departmentName ?? currentSession.departmentName,
        numericVolunteerId: volunteerId,
      );
      await SessionManager.saveSession(newSession);
    }

    // 5. Server sync via multipart/form-data PUT /api/volunteers/{volunteer_id}
    try {
      final uri = Uri.parse(targetUrl);
      final multipartRequest = http.MultipartRequest('PUT', uri);

      if (token != null && token.isNotEmpty) {
        multipartRequest.headers['Authorization'] = 'Bearer $token';
      }
      multipartRequest.headers['Accept'] = 'application/json';

      multipartRequest.fields['volunteer_name'] = updatedProfile.fullName.trim();
      multipartRequest.fields['gender'] = updatedProfile.gender;
      final formattedDob = updatedProfile.formattedIsoDateOfBirth;
      multipartRequest.fields['date_of_birth'] = formattedDob.isNotEmpty
          ? formattedDob
          : (updatedProfile.rawDateOfBirth ?? updatedProfile.dob);
      multipartRequest.fields['mobile_no'] = updatedProfile.mobileNumber.trim();

      if (updatedProfile.email.isNotEmpty && updatedProfile.email != '—') {
        multipartRequest.fields['email'] = updatedProfile.email.trim();
      }
      if (updatedProfile.institutionTypeId != null &&
          updatedProfile.institutionTypeId! > 0) {
        multipartRequest.fields['institution_type_id'] =
            updatedProfile.institutionTypeId.toString();
      }
      if (updatedProfile.institutionName != null &&
          updatedProfile.institutionName!.isNotEmpty) {
        multipartRequest.fields['institution_name'] =
            updatedProfile.institutionName!;
      }
      if (updatedProfile.otherInstitutionName != null &&
          updatedProfile.otherInstitutionName!.trim().isNotEmpty) {
        multipartRequest.fields['other_institution_name'] =
            updatedProfile.otherInstitutionName!.trim();
      }
      if (updatedProfile.educationId != null &&
          updatedProfile.educationId! > 0) {
        multipartRequest.fields['education_id'] =
            updatedProfile.educationId.toString();
      }
      if (updatedProfile.professionId != null &&
          updatedProfile.professionId! > 0) {
        multipartRequest.fields['profession_id'] =
            updatedProfile.professionId.toString();
      }
      if (stateLgd != null) {
        multipartRequest.fields['state_lgd_code'] = stateLgd.toString();
      }
      if (districtLgd != null) {
        multipartRequest.fields['district_lgd_code'] = districtLgd.toString();
      }
      if (blockLgd != null) {
        multipartRequest.fields['block_lgd_code'] = blockLgd.toString();
      }
      if (gpLgd != null) {
        multipartRequest.fields['gram_panchayat_lgd_code'] = gpLgd.toString();
      }
      if (villageLgd != null) {
        multipartRequest.fields['village_lgd_code'] = villageLgd.toString();
      }

      // Attach file to 'photo' multipart field if a new photo was selected
      File? fileToUpload = photoFile;
      if (fileToUpload == null &&
          updatedProfile.photoUrl != null &&
          (updatedProfile.photoUrl!.startsWith('/') ||
              updatedProfile.photoUrl!.contains('\\') ||
              updatedProfile.photoUrl!.startsWith('file:'))) {
        final cleanPath =
            updatedProfile.photoUrl!.replaceFirst('file://', '');
        final candidate = File(cleanPath);
        if (candidate.existsSync()) {
          fileToUpload = candidate;
        }
      }

      if (fileToUpload != null && await fileToUpload.exists()) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath('photo', fileToUpload.path),
        );
      }

      debugPrint(
        '[PROFILE] PUT $targetUrl (multipart/form-data) with ${multipartRequest.fields.length} fields, ${multipartRequest.files.length} files',
      );

      final httpClient = client ?? AuthenticatedHttpClient.instance;
      final streamedResponse = await httpClient
          .send(multipartRequest)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[PROFILE] PUT update response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        DetailedVolunteerProfile savedProfile = localSavedProfile;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final serverData = decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded;
            final serverSaved =
                DetailedVolunteerProfile.fromVolunteerProfileJson(serverData);
            savedProfile = serverSaved.merge(savedProfile);
          }
        } catch (_) {}

        await SessionManager.saveDetailedProfile(savedProfile);
        return true;
      } else {
        String errorMessage = 'Server error (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            errorMessage = decoded['detail']?.toString() ??
                decoded['message']?.toString() ??
                response.body;
          }
        } catch (_) {
          errorMessage = response.body;
        }
        debugPrint('[PROFILE] PUT update failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      debugPrint('[PROFILE] Offline: Network unavailable; profile changes saved locally: $e');
      return true;
    } on TimeoutException catch (e) {
      debugPrint('[PROFILE] Offline: Request timed out; profile changes saved locally: $e');
      return true;
    }
  }

  /// Fetch Section 2 shared handset login history (dynamically recorded on logins)
  Future<List<LoginHistoryEntry>> getLoginHistory(String volunteerId) async {
    // 1. Attempt to fetch from backend if endpoint is available
    try {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await http
            .get(
              Uri.parse('$endpointLoginHistory?volunteer_id=$volunteerId'),
              headers: ApiConstants.defaultHeaders(token: token),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            final remoteEntries = decoded
                .map(
                  (e) => LoginHistoryEntry.fromJson(e as Map<String, dynamic>),
                )
                .toList();
            if (remoteEntries.isNotEmpty) {
              return remoteEntries;
            }
          }
        }
      }
    } catch (_) {
      // Backend endpoint optional or offline
    }

    // 2. Return dynamically recorded login history from local storage
    return await SessionManager.getLoginHistory();
  }
}
