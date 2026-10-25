import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
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
            final updatedSession = session.copyWith(
              volunteerId: mergedProfile.volunteerId,
              numericVolunteerId: mergedProfile.numericVolunteerId,
              fullName: mergedProfile.fullName,
              mobile: mergedProfile.mobileNumber,
              email: mergedProfile.email,
              sector: mergedProfile.designation,
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
  }) async {
    final token = await SessionManager.getToken();

    // 1. Resolve numeric volunteer ID
    int? volunteerId = updatedProfile.numericVolunteerId;
    if (volunteerId == null || volunteerId <= 0) {
      volunteerId = int.tryParse(updatedProfile.volunteerId);
    }
    if (volunteerId == null || volunteerId <= 0) {
      final session = await SessionManager.getUserSession();
      volunteerId = session?.numericVolunteerId ??
          (session != null ? int.tryParse(session.volunteerId) : null);
    }
    if (volunteerId == null || volunteerId <= 0) {
      volunteerId = await SessionManager.getNumericVolunteerId();
    }

    final targetUrl = (volunteerId != null && volunteerId > 0)
        ? ApiConstants.endpointVolunteer(volunteerId)
        : ApiConstants.endpointUpdateProfile;

    // 2. Immediately persist locally so changes are visible across the app
    await SessionManager.saveDetailedProfile(updatedProfile);

    // 3. Keep UserSession synchronized
    final currentSession = await SessionManager.getUserSession();
    if (currentSession != null) {
      final newSession = currentSession.copyWith(
        fullName: updatedProfile.fullName,
        mobile: updatedProfile.mobileNumber,
        email: updatedProfile.email,
        photoPath: updatedProfile.photoUrl,
        sector: updatedProfile.designation,
      );
      await SessionManager.saveSession(newSession);
    }

    // 4. Server sync via PUT /api/volunteers/{volunteer_id}
    try {
      final bodyMap = <String, dynamic>{
        if (volunteerId != null && volunteerId > 0) 'volunteer_id': volunteerId,
        'volunteer_name': updatedProfile.fullName,
        'mobile_no': updatedProfile.mobileNumber,
        if (updatedProfile.email.isNotEmpty && updatedProfile.email != '—')
          'email': updatedProfile.email,
        'gender': updatedProfile.gender.toUpperCase(),
        'date_of_birth': updatedProfile.rawDateOfBirth ?? updatedProfile.dob,
        if (updatedProfile.educationId != null && updatedProfile.educationId! > 0)
          'education_id': updatedProfile.educationId,
        if (updatedProfile.qualification.isNotEmpty && updatedProfile.qualification != '—')
          'education_name': updatedProfile.qualification,
        if (updatedProfile.professionId != null && updatedProfile.professionId! > 0)
          'profession_id': updatedProfile.professionId,
        if (updatedProfile.profession.isNotEmpty && updatedProfile.profession != '—')
          'profession_name': updatedProfile.profession,
        if (updatedProfile.departmentId != null && updatedProfile.departmentId! > 0)
          'department_id': updatedProfile.departmentId,
        if (updatedProfile.departmentName != null && updatedProfile.departmentName!.isNotEmpty)
          'department_name': updatedProfile.departmentName,
        if (updatedProfile.cohvType != null && updatedProfile.cohvType!.isNotEmpty)
          'cohv_type': updatedProfile.cohvType,
        if (updatedProfile.institutionTypeId != null && updatedProfile.institutionTypeId! > 0)
          'institution_type_id': updatedProfile.institutionTypeId,
        if (updatedProfile.institutionName != null && updatedProfile.institutionName!.isNotEmpty)
          'institution_name': updatedProfile.institutionName,
        'other_institution_name': updatedProfile.otherInstitutionName,
        'preferred_language': updatedProfile.preferredLanguage,
      };

      debugPrint('[PROFILE] PUT $targetUrl: ${jsonEncode(bodyMap)}');

      final response = await http
          .put(
            Uri.parse(targetUrl),
            headers: ApiConstants.defaultHeaders(token: token),
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[PROFILE] PUT update response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final serverSaved = DetailedVolunteerProfile.fromVolunteerProfileJson(decoded);
          final merged = serverSaved.merge(updatedProfile);
          await SessionManager.saveDetailedProfile(merged);
        }
        return true;
      }
    } catch (e) {
      debugPrint('[PROFILE] Network error during profile update (local save retained): $e');
    }

    return true;
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
