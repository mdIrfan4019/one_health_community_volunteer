import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/database/offline_outbox_service.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/sync/data/sync_repository.dart';
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

    if (!SyncRepository().getSummary().isOnline && localDetailed != null) {
      debugPrint('[PROFILE] App connection override is offline — returning cached DetailedVolunteerProfile');
      return localDetailed;
    }

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
          .timeout(const Duration(seconds: 6));

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

          // 1. Persist latest profile to SessionManager for instant offline access
          await SessionManager.saveDetailedProfile(mergedProfile);

          // 2. Persist to SQLite table cached_records
          final effectiveVid = mergedProfile.volunteerId.isNotEmpty
              ? mergedProfile.volunteerId
              : (mergedProfile.numericVolunteerId?.toString() ?? 'CURRENT_USER');
          try {
            await AppDatabase.instance.cacheRecordsList(
              entityType: 'VOLUNTEER_PROFILE',
              volunteerId: effectiveVid,
              records: [mergedProfile.toJson()],
              idExtractor: (r) => effectiveVid,
            );
          } catch (dbErr) {
            debugPrint('[PROFILE] Error saving profile to SQLite: $dbErr');
          }

          // 3. Keep cached UserSession in sync across the app (dashboard, drawer, etc.)
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
              gender: mergedProfile.gender != '—' ? mergedProfile.gender : session.gender,
              dob: mergedProfile.rawDateOfBirth ?? (mergedProfile.dob != '—' ? mergedProfile.dob : session.dob),
              qualification: mergedProfile.qualification != '—' ? mergedProfile.qualification : session.qualification,
              profession: mergedProfile.profession != '—' ? mergedProfile.profession : session.profession,
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

      // Fallback 1: Return locally cached DetailedVolunteerProfile from SessionManager
      if (localDetailed != null) {
        debugPrint('[PROFILE] Serving locally cached DetailedVolunteerProfile from SessionManager');
        return localDetailed;
      }

      // Fallback 2: Check SQLite cached_records table
      final cachedSession = await SessionManager.getUserSession();
      final effectiveVid = volunteerIdentifier?.trim().isNotEmpty == true
          ? volunteerIdentifier!.trim()
          : (cachedSession?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');
      if (effectiveVid.isNotEmpty) {
        try {
          final cachedRecords = await AppDatabase.instance.getCachedRecordsList(
            entityType: 'VOLUNTEER_PROFILE',
            volunteerId: effectiveVid,
          );
          if (cachedRecords.isNotEmpty) {
            debugPrint('[PROFILE] Serving profile from SQLite cached_records');
            final profile =
                DetailedVolunteerProfile.fromVolunteerProfileJson(cachedRecords.first);
            await SessionManager.saveDetailedProfile(profile);
            return profile;
          }
        } catch (dbErr) {
          debugPrint('[PROFILE] SQLite fallback read error: $dbErr');
        }
      }

      // Fallback 3: Return cached UserSession
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
    bool allowOfflineFallback = true,
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

    // 3. Copy photo to vault so it persists permanently in offline storage
    String? permanentPhotoPath;
    if (photoFile != null && await photoFile.exists()) {
      try {
        final savedPaths = await OfflineOutboxService.instance.copyFilesToVault(
          filePaths: [photoFile.path],
          subDirectory: 'profile_photos',
        );
        if (savedPaths.isNotEmpty) {
          permanentPhotoPath = savedPaths.first;
        }
      } catch (copyErr) {
        debugPrint('[PROFILE] Error copying photo to vault: $copyErr');
        permanentPhotoPath = photoFile.path;
      }
    }

    // 4. Immediately persist locally so changes are visible across the app
    final localSavedProfile = updatedProfile.copyWith(
      numericVolunteerId: volunteerId,
      photoUrl: permanentPhotoPath ?? updatedProfile.photoUrl,
      stateLgdCode: stateLgd,
      districtLgdCode: districtLgd,
      blockLgdCode: blockLgd,
      gramPanchayatLgdCode: gpLgd,
      villageLgdCode: villageLgd,
    );
    await SessionManager.saveDetailedProfile(localSavedProfile);

    // 5. Keep UserSession synchronized
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
        photoPath: permanentPhotoPath ?? updatedProfile.photoUrl,
        sector: resolvedDept,
        departmentId: updatedProfile.departmentId ?? currentSession.departmentId,
        departmentName: updatedProfile.departmentName ?? currentSession.departmentName,
        numericVolunteerId: volunteerId,
      );
      await SessionManager.saveSession(newSession);
    }

    // Persist to SQLite cached_records
    try {
      final effectiveVid = localSavedProfile.volunteerId.isNotEmpty
          ? localSavedProfile.volunteerId
          : (localSavedProfile.numericVolunteerId?.toString() ?? 'CURRENT_USER');
      await AppDatabase.instance.cacheRecordsList(
        entityType: 'VOLUNTEER_PROFILE',
        volunteerId: effectiveVid,
        records: [localSavedProfile.toJson()],
        idExtractor: (r) => effectiveVid,
      );
    } catch (_) {}

    // Fast path: if allowOfflineFallback is true and app is offline by override
    if (allowOfflineFallback && !SyncRepository().getSummary().isOnline) {
      debugPrint('[PROFILE] App is in offline mode — queuing directly without waiting.');
      final clientRef = 'OFFLINE-PROFILE-$volunteerId';
      final photos = (permanentPhotoPath != null && permanentPhotoPath.isNotEmpty)
          ? [permanentPhotoPath]
          : (photoFile != null ? [photoFile.path] : <String>[]);

      try {
        await OfflineOutboxService.instance.enqueueSubmission(
          entityType: 'PROFILE',
          clientRef: clientRef,
          payload: {
            'volunteer_id': volunteerId,
            'profile_json': localSavedProfile.toJson(),
            if (permanentPhotoPath != null) 'photo_path': permanentPhotoPath,
          },
          photos: photos,
        );
        await SyncRepository().refreshFromDatabase();
      } catch (dbErr) {
        debugPrint('[PROFILE] SQLite outbox enqueue error for profile: $dbErr');
      }
      return true;
    }

    // 6. Server sync via multipart/form-data PUT /api/volunteers/{volunteer_id}
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
      File? fileToUpload = photoFile ??
          (permanentPhotoPath != null ? File(permanentPhotoPath) : null);
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
          .timeout(const Duration(seconds: 15));
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
        try {
          final effectiveVid = savedProfile.volunteerId.isNotEmpty
              ? savedProfile.volunteerId
              : (savedProfile.numericVolunteerId?.toString() ?? 'CURRENT_USER');
          await AppDatabase.instance.cacheRecordsList(
            entityType: 'VOLUNTEER_PROFILE',
            volunteerId: effectiveVid,
            records: [savedProfile.toJson()],
            idExtractor: (r) => effectiveVid,
          );
          // Mark outbox record as SYNCED if previously queued
          await AppDatabase.instance.updateRecordStatus(
            clientRef: 'OFFLINE-PROFILE-$volunteerId',
            status: 'SYNCED',
          );
        } catch (_) {}
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
    } catch (e) {
      debugPrint('[PROFILE] Error during PUT update: $e');
      final isOffline = OfflineOutboxService.isNetworkException(e);
      if (allowOfflineFallback && isOffline) {
        debugPrint('[PROFILE] Queuing profile update into SQLite outbox (offline mode)');
        final clientRef = 'OFFLINE-PROFILE-$volunteerId';
        final photos = (permanentPhotoPath != null && permanentPhotoPath.isNotEmpty)
            ? [permanentPhotoPath]
            : (photoFile != null ? [photoFile.path] : <String>[]);

        try {
          await OfflineOutboxService.instance.enqueueSubmission(
            entityType: 'PROFILE',
            clientRef: clientRef,
            payload: {
              'volunteer_id': volunteerId,
              'profile_json': localSavedProfile.toJson(),
              if (permanentPhotoPath != null) 'photo_path': permanentPhotoPath,
            },
            photos: photos,
          );
          await SyncRepository().refreshFromDatabase();
        } catch (dbErr) {
          debugPrint('[PROFILE] SQLite outbox enqueue error for profile: $dbErr');
        }
        return true;
      }
      rethrow;
    }
  }

  /// Fetch Section 2 shared handset login history (dynamically recorded on logins)
  Future<List<LoginHistoryEntry>> getLoginHistory(String volunteerId) async {
    if (!SyncRepository().getSummary().isOnline) {
      return await SessionManager.getLoginHistory();
    }

    // 1. Attempt to fetch from backend if endpoint is available
    try {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await http
            .get(
              Uri.parse('$endpointLoginHistory?volunteer_id=$volunteerId'),
              headers: ApiConstants.defaultHeaders(token: token),
            )
            .timeout(const Duration(seconds: 2));

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
