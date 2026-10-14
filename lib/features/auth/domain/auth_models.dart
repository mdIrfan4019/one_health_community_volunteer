enum AuthMode { pin, otp }

class SignInWithPinRequest {
  final String identifier; // Volunteer ID or 10-digit mobile
  final String pin;

  SignInWithPinRequest({
    required this.identifier,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'pin': pin,
  };
}

class SendOtpRequest {
  final String mobileNumber;

  SendOtpRequest({required this.mobileNumber});

  Map<String, dynamic> toJson() => {
    'mobile_number': mobileNumber,
  };
}

class UserSession {
  final String volunteerId;
  final String fullName;
  final String mobile;
  final String sector; // human, animal, wildlife, environment
  final String status; // active, inactive (supervisor gate)
  final String token;

  UserSession({
    required this.volunteerId,
    required this.fullName,
    required this.mobile,
    required this.sector,
    required this.status,
    required this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      volunteerId: json['volunteer_id'] ?? '',
      fullName: json['full_name'] ?? '',
      mobile: json['mobile'] ?? '',
      sector: json['sector'] ?? 'human',
      status: json['status'] ?? 'inactive',
      token: json['token'] ?? '',
    );
  }
}


// Append to: lib/features/auth/domain/auth_models.dart

class VerifyOtpRequest {
  final String mobileNumber;
  final String otp;

  VerifyOtpRequest({
    required this.mobileNumber,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    'mobile_number': mobileNumber,
    'otp': otp,
  };
}


// Append to: lib/features/auth/domain/auth_models.dart

class VolunteerRegistrationRequest {
  final String fullName;
  final String gender;
  final DateTime dob;
  final String mobileNumber;
  final String email;
  final String cohvType;
  final String state;
  final String district;
  final String block;
  final String panchayat;
  final String village;
  final DateTime dateOfJoining;
  final String qualification;
  final String profession;
  final String pin;
  final String volunteerId;
  final String? photoPath;
  final double latitude;
  final double longitude;

  VolunteerRegistrationRequest({
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.mobileNumber,
    required this.email,
    required this.cohvType,
    required this.state,
    required this.district,
    required this.block,
    required this.panchayat,
    required this.village,
    required this.dateOfJoining,
    required this.qualification,
    required this.profession,
    required this.pin,
    required this.volunteerId,
    this.photoPath,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'gender': gender,
    'dob': dob.toIso8601String(),
    'mobile_number': mobileNumber,
    'email': email,
    'cohv_type': cohvType,
    'state': state,
    'district': district,
    'block': block,
    'panchayat': panchayat,
    'village': village,
    'date_of_joining': dateOfJoining.toIso8601String(),
    'qualification': qualification,
    'profession': profession,
    'pin': pin,
    'volunteer_id': volunteerId,
    'photo_path': photoPath,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class RegistrationResult {
  final String volunteerId;
  final String fullName;
  final String supervisorStatus;
  final String accountStatus; // 'Inactive' until approved

  RegistrationResult({
    required this.volunteerId,
    required this.fullName,
    required this.supervisorStatus,
    required this.accountStatus,
  });

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      volunteerId: json['volunteer_id'] ?? '',
      fullName: json['full_name'] ?? '',
      supervisorStatus: json['supervisor_status'] ?? 'Assigned on approval',
      accountStatus: json['account_status'] ?? 'Inactive',
    );
  }
}
