import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';

import '../domain/auth_models.dart';

class AuthApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointLogin = ApiConstants.endpointLogin;
  static const String endpointLoginWithPin = ApiConstants.endpointLoginWithPin;
  static const String endpointMe = ApiConstants.endpointMe;
  static const String endpointLogout = ApiConstants.endpointLogout;
  static const String endpointSendOtp = ApiConstants.endpointSendOtp;
  static const String endpointForgotPin = ApiConstants.endpointForgotPin;
  static const String endpointVerifyOtp = ApiConstants.endpointVerifyOtp;
  static const String endpointRegister = ApiConstants.endpointRegister;

  /// Sign in with Volunteer ID or Mobile and PIN (POST /api/auth/login)
  Future<UserSession> loginWithPin(
    SignInWithPinRequest request, {
    http.Client? client,
  }) async {
    final identifier = request.identifier.trim();
    final pin = request.pin.trim();

    if (identifier.isEmpty || pin.isEmpty) {
      throw Exception('Identifier and PIN are required.');
    }

    final uri = Uri.parse(endpointLoginWithPin);
    final payload = jsonEncode(request.toJson());

    debugPrint('[AUTH] POST $uri with payload: $payload');

    final httpClient = client ?? http.Client();
    final http.Response response;
    try {
      response = await httpClient
          .post(uri, headers: ApiConstants.defaultHeaders(), body: payload)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[AUTH] Network error during login: $e');
      throw Exception(
        'Could not connect to authentication server ($uri). Check your network.',
      );
    }

    debugPrint(
      '[AUTH] Login response status: ${response.statusCode}, body: ${response.body}',
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : {};
      final session = UserSession.fromJson(data);
      // Persist session to SharedPreferences for auto-login / session restoration
      await SessionManager.saveSession(session);

      // Automatically record dynamic login event in audit history
      try {
        final now = DateTime.now();
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final formattedTime =
            '${now.day} ${months[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        await SessionManager.addLoginHistoryEntry(
          LoginHistoryEntry(
            timestamp: formattedTime,
            authMethod: 'PIN',
            deviceId: request.deviceId ?? 'DEV-C0YBZ9WK',
          ),
        );
      } catch (e) {
        debugPrint('[AUTH] Could not record login history: $e');
      }

      return session;
    } else {
      String errorMessage = 'Login failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('detail')) {
            final detail = decoded['detail'];
            if (detail is String) {
              errorMessage = detail;
            } else if (detail is List) {
              final messages = <String>[];
              for (final item in detail) {
                if (item is Map && item['msg'] != null) {
                  final locList = item['loc'] is List
                      ? (item['loc'] as List)
                      : [];
                  final field = locList.isNotEmpty
                      ? locList.last.toString()
                      : '';
                  messages.add(
                    field.isNotEmpty
                        ? '$field: ${item['msg']}'
                        : '${item['msg']}',
                  );
                } else {
                  messages.add(item.toString());
                }
              }
              if (messages.isNotEmpty) {
                errorMessage = messages.join('\n');
              }
            }
          } else if (decoded.containsKey('message')) {
            errorMessage = decoded['message'].toString();
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }

  /// Use Case 1, 2, 3: Fetch Current Authenticated Volunteer Profile (GET /api/auth/me)
  /// Uses Access Token in Authorization Bearer Header
  Future<UserSession> getCurrentUser({
    String? token,
    http.Client? client,
  }) async {
    final effectiveToken = token ?? await SessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw AuthException(
        'No authentication token found. Please sign in.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse(endpointMe);
    debugPrint('[AUTH] GET $uri with Bearer token');

    final httpClient = client ?? http.Client();
    final http.Response response;
    try {
      response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders(token: effectiveToken))
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      debugPrint('[AUTH] Network error during GET /api/auth/me: $e');
      throw Exception(
        'Could not connect to authentication server ($uri). Check your network.',
      );
    }

    debugPrint(
      '[AUTH] /api/auth/me response status: ${response.statusCode}, body: ${response.body}',
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : {};
      final session = UserSession.fromJson(data, token: effectiveToken);
      // Update local cache with freshest volunteer profile details
      await SessionManager.saveSession(session);
      return session;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Token expired or invalid: Clear local session cache
      await SessionManager.clearSession();
      throw AuthException(
        'Session expired or invalid. Please sign in again.',
        statusCode: response.statusCode,
      );
    } else {
      String errorMessage =
          'Failed to load user profile (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['detail'] != null) {
            errorMessage = decoded['detail'].toString();
          } else if (decoded['message'] != null) {
            errorMessage = decoded['message'].toString();
          }
        }
      } catch (_) {}
      throw AuthException(errorMessage, statusCode: response.statusCode);
    }
  }

  /// Use Case 4: Token Validation Guard
  /// Verifies that current token is still valid before performing sensitive operations
  /// (e.g. submitting offline sync batches or event reports)
  Future<bool> validateTokenGuard({String? token}) async {
    try {
      await getCurrentUser(token: token);
      return true;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        await SessionManager.clearSession();
      }
      return false;
    } catch (e) {
      debugPrint('[AUTH] Token validation guard network bypass: $e');
      // If offline/network error, allow if local token exists
      final localToken = token ?? await SessionManager.getToken();
      return localToken != null && localToken.isNotEmpty;
    }
  }

  /// Bind Logout API (POST /api/auth/logout)
  /// Uses Access Token in Authorization Header and clears local session
  Future<bool> logout({String? token, http.Client? client}) async {
    final effectiveToken = token ?? await SessionManager.getToken();
    final uri = Uri.parse(endpointLogout);

    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      final httpClient = client ?? http.Client();
      try {
        debugPrint('[AUTH] POST $uri with Bearer token for logout');
        var response = await httpClient
            .post(
              uri,
              headers: ApiConstants.defaultHeaders(token: effectiveToken),
            )
            .timeout(const Duration(seconds: 15));

        // If backend defined logout as GET endpoint, fallback gracefully
        if (response.statusCode == 405) {
          debugPrint(
            '[AUTH] 405 Method Not Allowed on POST logout, retrying GET $uri',
          );
          response = await httpClient
              .get(
                uri,
                headers: ApiConstants.defaultHeaders(token: effectiveToken),
              )
              .timeout(const Duration(seconds: 15));
        }

        debugPrint('[AUTH] Logout response status: ${response.statusCode}');
      } catch (e) {
        debugPrint('[AUTH] Error during logout API call: $e');
      }
    }

    // Always clear local SharedPreferences session upon logout
    await SessionManager.clearSession();
    return true;
  }

  /// Request OTP for registered mobile number
  Future<bool> sendOtp(SendOtpRequest request) async {
    // -----------------------------------------------------------------------
    // TODO: Replace with real HTTP POST call when API is ready:
    // final response = await http.post(
    //   Uri.parse(endpointSendOtp),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(request.toJson()),
    // );
    // return response.statusCode == 200;
    // -----------------------------------------------------------------------

    await Future.delayed(const Duration(milliseconds: 1000));

    if (request.mobileNumber.length != 10) {
      throw Exception('Enter a valid 10-digit mobile number.');
    }

    return true;
  }

  /// Request PIN Reset / Recovery for registered mobile number
  Future<String> requestForgotPin(String mobileNumber) async {
    // -----------------------------------------------------------------------
    // TODO: Replace with real HTTP POST call when API is ready:
    // final response = await http.post(
    //   Uri.parse(endpointForgotPin),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'mobile_number': mobileNumber}),
    // );
    // if (response.statusCode == 200) {
    //   return 'A reset OTP has been sent to your registered mobile.';
    // } else {
    //   throw Exception('Mobile number not found in field registry.');
    // }
    // -----------------------------------------------------------------------

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Simulated success response
    return 'Password/PIN reset instructions sent to $mobileNumber';
  }

  /// Verify 6-digit OTP and establish session
  Future<UserSession> verifyOtp(VerifyOtpRequest request) async {
    // =========================================================================
    // 🔌 REAL API INTEGRATION:
    // When your backend API is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointVerifyOtp),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(request.toJson()),
    // );
    //
    // if (response.statusCode == 200) {
    //   return UserSession.fromJson(jsonDecode(response.body));
    // } else {
    //   final errorData = jsonDecode(response.body);
    //   throw Exception(errorData['message'] ?? 'Invalid or expired OTP. Please try again.');
    // }
    // =========================================================================

    // Simulated network delay (1 second) for realistic UX testing
    await Future.delayed(const Duration(milliseconds: 1000));

    // Prototype validation rule: must be exactly 6 digits
    if (request.otp.trim().length != 6) {
      throw Exception('Please enter a valid 6-digit OTP.');
    }

    // Mock active session creation for prototype testing
    return UserSession(
      volunteerId: 'COHV-26-0001',
      fullName: 'Field Volunteer',
      mobile: request.mobileNumber,
      sector: 'human',
      status: 'active',
      token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Register new Volunteer (Sends multipart/form-data to POST /api/volunteers/register)
  Future<RegistrationResult> registerVolunteer(
    VolunteerRegistrationRequest request, {
    http.Client? client,
  }) async {
    final uri = Uri.parse(endpointRegister);
    final multipartRequest = http.MultipartRequest('POST', uri);

    // Format ISO Date: YYYY-MM-DD
    String formatDate(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    // Required fields:
    multipartRequest.fields['volunteer_name'] = request.volunteerName;
    multipartRequest.fields['gender'] = request.gender;
    multipartRequest.fields['date_of_birth'] = formatDate(request.dateOfBirth);
    multipartRequest.fields['mobile_no'] = request.mobileNo;
    multipartRequest.fields['email'] = request.email;
    multipartRequest.fields['cohv_type'] = request.cohvType;
    multipartRequest.fields['state_lgd_code'] = request.stateLgdCode.toString();
    multipartRequest.fields['district_lgd_code'] = request.districtLgdCode
        .toString();
    multipartRequest.fields['block_lgd_code'] = request.blockLgdCode.toString();
    multipartRequest.fields['gram_panchayat_lgd_code'] = request
        .gramPanchayatLgdCode
        .toString();
    multipartRequest.fields['village_lgd_code'] = request.villageLgdCode
        .toString();
    multipartRequest.fields['date_of_joining'] = formatDate(
      request.dateOfJoining,
    );
    multipartRequest.fields['education_id'] = request.educationId.toString();
    multipartRequest.fields['profession_id'] = request.professionId.toString();
    multipartRequest.fields['pin'] = request.pin;

    // Optional fields:
    if (request.supervisorId != null && request.supervisorId! > 0) {
      multipartRequest.fields['supervisor_id'] = request.supervisorId
          .toString();
    }
    if (request.latitude != null) {
      multipartRequest.fields['latitude'] = request.latitude.toString();
    }
    if (request.longitude != null) {
      multipartRequest.fields['longitude'] = request.longitude.toString();
    }
    if (request.gpsAccuracyM != null && request.gpsAccuracyM! >= 0) {
      multipartRequest.fields['gps_accuracy_m'] = request.gpsAccuracyM
          .toString();
    }
    if (request.gpsUnavailableReason != null &&
        request.gpsUnavailableReason!.isNotEmpty) {
      multipartRequest.fields['gps_unavailable_reason'] =
          request.gpsUnavailableReason!;
    }
    if (request.deviceId != null && request.deviceId!.isNotEmpty) {
      multipartRequest.fields['device_id'] = request.deviceId!;
    }

    // Institution / Department Payload Fields:
    if (request.departmentId != null && request.departmentId! > 0) {
      multipartRequest.fields['department_id'] = request.departmentId.toString();
    }
    if (request.institutionTypeId != null && request.institutionTypeId! > 0) {
      multipartRequest.fields['institution_type_id'] =
          request.institutionTypeId.toString();
    }
    // The backend uses other_institution_name for custom entries when "Other" is chosen
    if (request.customInstitutionName != null &&
        request.customInstitutionName!.trim().isNotEmpty) {
      multipartRequest.fields['other_institution_name'] =
          request.customInstitutionName!.trim();
      multipartRequest.fields['custom_institution_name'] =
          request.customInstitutionName!.trim();
    }
    if (request.institutionName != null &&
        request.institutionName!.trim().isNotEmpty) {
      multipartRequest.fields['institution_name'] =
          request.institutionName!.trim();
    }


    // Profile photograph file upload
    if (request.photoPath != null && request.photoPath!.isNotEmpty) {
      final file = File(request.photoPath!);
      if (await file.exists()) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath('photo', request.photoPath!),
        );
      }
    }

    debugPrint(
      '[AUTH] POST $uri (multipart/form-data) with ${multipartRequest.fields.length} fields, ${multipartRequest.files.length} files',
    );

    final httpClient = client ?? http.Client();
    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await httpClient
          .send(multipartRequest)
          .timeout(const Duration(seconds: 40));
    } catch (e) {
      debugPrint('[AUTH] Network error during registration: $e');
      throw Exception(
        'Could not connect to registration server ($uri). Check your network.',
      );
    }

    final response = await http.Response.fromStream(streamedResponse);
    debugPrint(
      '[AUTH] Registration response status: ${response.statusCode}, body: ${response.body}',
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : {};
      return RegistrationResult.fromJson(
        data,
        fullName: request.volunteerName,
        supervisorStatus:
            (request.supervisorId != null && request.supervisorId! > 0)
            ? 'Assigned'
            : 'Assigned on approval',
      );
    } else {
      String errorMessage = 'Registration failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('detail')) {
            final detail = decoded['detail'];
            if (detail is String) {
              errorMessage = detail;
            } else if (detail is List) {
              final messages = <String>[];
              for (final item in detail) {
                if (item is Map && item['msg'] != null) {
                  final locList = item['loc'] is List
                      ? (item['loc'] as List)
                      : [];
                  final field = locList.isNotEmpty
                      ? locList.last.toString()
                      : '';
                  messages.add(
                    field.isNotEmpty
                        ? '$field: ${item['msg']}'
                        : '${item['msg']}',
                  );
                } else {
                  messages.add(item.toString());
                }
              }
              if (messages.isNotEmpty) {
                errorMessage = messages.join('\n');
              }
            }
          } else if (decoded.containsKey('message')) {
            errorMessage = decoded['message'].toString();
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }
}
