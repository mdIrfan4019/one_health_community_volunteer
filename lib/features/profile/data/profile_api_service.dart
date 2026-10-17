import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import '../domain/profile_models.dart';

class ProfileApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointProfileDetails = ApiConstants.endpointProfileDetails;
  static const String endpointLoginHistory = ApiConstants.endpointLoginHistory;
  static const String endpointUpdateProfile = ApiConstants.endpointUpdateProfile;

  final AuthApiService _authApiService = AuthApiService();

  /// Use Case 3: Refreshing Profile Information
  /// Fetch full detailed volunteer profile using GET /api/auth/me
  Future<DetailedVolunteerProfile> getDetailedProfile(String volunteerId) async {
    final localDetailed = await SessionManager.getDetailedProfile();
    try {
      final userSession = await _authApiService.getCurrentUser();
      final fetchedProfile = DetailedVolunteerProfile.fromUserSession(userSession);
      final mergedProfile = fetchedProfile.merge(localDetailed);
      await SessionManager.saveDetailedProfile(mergedProfile);
      return mergedProfile;
    } catch (e) {
      if (localDetailed != null) {
        return localDetailed;
      }
      // If network is offline, attempt using locally cached UserSession
      final cached = await SessionManager.getUserSession();
      if (cached != null) {
        return DetailedVolunteerProfile.fromUserSession(cached);
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
          request.fields['preferred_language'] = updatedProfile.preferredLanguage;
          request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

          final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
          final response = await http.Response.fromStream(streamedResponse);
          debugPrint('[PROFILE] Multipart update response status: ${response.statusCode}');
        } else {
          final response = await http.post(
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
          ).timeout(const Duration(seconds: 15));
          debugPrint('[PROFILE] JSON update response status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('[PROFILE] Network error during profile update (local save retained): $e');
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
        final response = await http.get(
          Uri.parse('$endpointLoginHistory?volunteer_id=$volunteerId'),
          headers: ApiConstants.defaultHeaders(token: token),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            final remoteEntries = decoded
                .map((e) => LoginHistoryEntry.fromJson(e as Map<String, dynamic>))
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

    // 2. Return dynamically recorded login history from local storage (NO static dummy data)
    return await SessionManager.getLoginHistory();
  }
}
