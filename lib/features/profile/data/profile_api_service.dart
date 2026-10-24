import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
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

  /// Fetch full detailed volunteer profile using GET /api/volunteers/profile
  ///
  /// Removes old /api/auth/me binding and retrieves complete profile schema
  /// including location hierarchy, supervisor info, activity metrics, and photos.
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
          } else if (currentSession.numericVolunteerId != null) {
            volunteerId = currentSession.numericVolunteerId;
          }
        }
      }

      // 2. Build URL for GET /api/volunteers/profile
      final requestUrl = ApiConstants.endpointVolunteerProfileQuery(
        volunteerCode: volunteerCode,
        volunteerId: volunteerId,
      );

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
          final fetchedProfile =
              DetailedVolunteerProfile.fromVolunteerProfileJson(decoded);
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
      debugPrint('[PROFILE] Error fetching /api/volunteers/profile: $e');

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

  /// Update volunteer profile (POST/PUT /api/volunteer/update)
  Future<bool> updateProfile(
    DetailedVolunteerProfile updatedProfile, {
    File? photoFile,
  }) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(endpointUpdateProfile);

    // 1. Immediately persist locally so changes are visible across the app
    await SessionManager.saveDetailedProfile(updatedProfile);

    // 2. Also keep UserSession synchronized
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

    // 3. Attempt server sync
    if (token != null && token.isNotEmpty) {
      try {
        if (photoFile != null && await photoFile.exists()) {
          final request = http.MultipartRequest('POST', uri);
          request.headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          });
          request.fields['volunteer_id'] = updatedProfile.volunteerId;
          request.fields['volunteer_name'] = updatedProfile.fullName;
          request.fields['mobile_no'] = updatedProfile.mobileNumber;
          request.fields['email'] = updatedProfile.email;
          request.fields['gender'] = updatedProfile.gender;
          request.fields['date_of_birth'] = updatedProfile.dob;
          request.fields['education'] = updatedProfile.qualification;
          request.fields['profession'] = updatedProfile.profession;
          request.fields['preferred_language'] =
              updatedProfile.preferredLanguage;
          request.files.add(
            await http.MultipartFile.fromPath('photo', photoFile.path),
          );

          final streamedResponse =
              await request.send().timeout(const Duration(seconds: 25));
          final response = await http.Response.fromStream(streamedResponse);
          debugPrint(
            '[PROFILE] Multipart update response status: ${response.statusCode}',
          );
        } else {
          final response = await http
              .post(
                uri,
                headers: ApiConstants.defaultHeaders(token: token),
                body: jsonEncode({
                  'volunteer_id': updatedProfile.volunteerId,
                  'volunteer_name': updatedProfile.fullName,
                  'mobile_no': updatedProfile.mobileNumber,
                  'email': updatedProfile.email,
                  'gender': updatedProfile.gender,
                  'date_of_birth': updatedProfile.dob,
                  'education': updatedProfile.qualification,
                  'profession': updatedProfile.profession,
                  'preferred_language': updatedProfile.preferredLanguage,
                }),
              )
              .timeout(const Duration(seconds: 15));
          debugPrint(
            '[PROFILE] JSON update response status: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint(
          '[PROFILE] Network error during profile update (local save retained): $e',
        );
      }
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
