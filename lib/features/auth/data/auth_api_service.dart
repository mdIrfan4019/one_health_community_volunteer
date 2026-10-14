import '../domain/auth_models.dart';

class AuthApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION
  // Replace these URLs and implement your HTTP call when your API is ready.
  // =========================================================================
  static const String baseUrl = 'https://api.yourserver.org/api/v1';
  static const String endpointLoginWithPin = '$baseUrl/auth/login-pin';
  static const String endpointSendOtp = '$baseUrl/auth/send-otp';
  static const String endpointForgotPin = '$baseUrl/auth/forgot-pin'; 
  static const String endpointVerifyOtp = '$baseUrl/auth/verify-otp'; // 👈 OTP Verification endpoint
    static const String endpointRegister = '$baseUrl/auth/register'; // 👈 Volunteer Registration endpoint



  /// Sign in with Volunteer ID / Mobile and PIN
  Future<UserSession> loginWithPin(SignInWithPinRequest request) async {
    // -----------------------------------------------------------------------
    // TODO: Replace with real HTTP POST call when API is ready:
    // final response = await http.post(
    //   Uri.parse(endpointLoginWithPin),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(request.toJson()),
    // );
    // return UserSession.fromJson(jsonDecode(response.body));
    // -----------------------------------------------------------------------

    await Future.delayed(const Duration(milliseconds: 1000));

    if (request.identifier.isEmpty || request.pin.isEmpty) {
      throw Exception('Identifier and PIN are required.');
    }

    return UserSession(
      volunteerId: request.identifier.startsWith('COHV')
          ? request.identifier
          : 'COHV-26-0001',
      fullName: 'Field Volunteer',
      mobile: request.identifier.length == 10 ? request.identifier : '9876543210',
      sector: 'human',
      status: 'active',
      token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );
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

    /// Register new Volunteer (Establishes 'Inactive' status awaiting supervisor approval)
  Future<RegistrationResult> registerVolunteer(VolunteerRegistrationRequest request) async {
    // =========================================================================
    // 🔌 REAL API INTEGRATION:
    // When backend API is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointRegister),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(request.toJson()),
    // );
    //
    // if (response.statusCode == 201 || response.statusCode == 200) {
    //   return RegistrationResult.fromJson(jsonDecode(response.body));
    // } else {
    //   final err = jsonDecode(response.body);
    //   throw Exception(err['message'] ?? 'Registration failed. Please check details.');
    // }
    // =========================================================================

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Spec compliance: new accounts register with 'Inactive' status until supervisor approves
    return RegistrationResult(
      volunteerId: request.volunteerId,
      fullName: request.fullName,
      supervisorStatus: 'Assigned on approval',
      accountStatus: 'Inactive',
    );
  }


}
