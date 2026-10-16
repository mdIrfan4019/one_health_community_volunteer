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
  final String volunteerName;
  final String gender;
  final DateTime dateOfBirth;
  final String mobileNo;
  final String email;
  final String cohvType;
  final int stateLgdCode;
  final int districtLgdCode;
  final int blockLgdCode;
  final int gramPanchayatLgdCode;
  final int villageLgdCode;
  final DateTime dateOfJoining;
  final int educationId;
  final int professionId;
  final String pin;
  final int? supervisorId;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final String? deviceId;
  final String? photoPath;

  // Metadata / Display Names (Optional)
  final String? volunteerId;
  final String? stateName;
  final String? districtName;
  final String? blockName;
  final String? panchayatName;
  final String? villageName;
  final String? qualificationName;
  final String? professionName;

  VolunteerRegistrationRequest({
    required this.volunteerName,
    required this.gender,
    required this.dateOfBirth,
    required this.mobileNo,
    required this.email,
    required this.cohvType,
    required this.stateLgdCode,
    required this.districtLgdCode,
    required this.blockLgdCode,
    required this.gramPanchayatLgdCode,
    required this.villageLgdCode,
    required this.dateOfJoining,
    required this.educationId,
    required this.professionId,
    required this.pin,
    this.supervisorId,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.deviceId,
    this.photoPath,
    this.volunteerId,
    this.stateName,
    this.districtName,
    this.blockName,
    this.panchayatName,
    this.villageName,
    this.qualificationName,
    this.professionName,
  });

  // Backward compatibility getters
  String get fullName => volunteerName;
  String get mobileNumber => mobileNo;
  DateTime get dob => dateOfBirth;
  String get state => stateName ?? stateLgdCode.toString();
  String get district => districtName ?? districtLgdCode.toString();
  String get block => blockName ?? blockLgdCode.toString();
  String get panchayat => panchayatName ?? gramPanchayatLgdCode.toString();
  String get village => villageName ?? villageLgdCode.toString();
  String get qualification => qualificationName ?? educationId.toString();
  String get profession => professionName ?? professionId.toString();

  Map<String, dynamic> toJson() => {
    'volunteer_name': volunteerName,
    'gender': gender,
    'date_of_birth': '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
    'mobile_no': mobileNo,
    'email': email,
    'cohv_type': cohvType,
    'state_lgd_code': stateLgdCode,
    'district_lgd_code': districtLgdCode,
    'block_lgd_code': blockLgdCode,
    'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    'village_lgd_code': villageLgdCode,
    'date_of_joining': '${dateOfJoining.year.toString().padLeft(4, '0')}-${dateOfJoining.month.toString().padLeft(2, '0')}-${dateOfJoining.day.toString().padLeft(2, '0')}',
    'education_id': educationId,
    'profession_id': professionId,
    'pin': pin,
    if (supervisorId != null && supervisorId! > 0) 'supervisor_id': supervisorId,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null) 'gps_unavailable_reason': gpsUnavailableReason,
    if (deviceId != null) 'device_id': deviceId,
    if (photoPath != null) 'photo_path': photoPath,
  };
}

class RegistrationResult {
  final String volunteerId; // Usually the formatted volunteer_code e.g. "COHV-26-0002"
  final int numericVolunteerId;
  final String volunteerCode;
  final String status;
  final String message;
  final String? photoPath;
  final String fullName;
  final String supervisorStatus;
  final String accountStatus;

  RegistrationResult({
    required this.volunteerId,
    this.numericVolunteerId = 0,
    required this.volunteerCode,
    required this.status,
    required this.message,
    this.photoPath,
    required this.fullName,
    required this.supervisorStatus,
    required this.accountStatus,
  });

  factory RegistrationResult.fromJson(
    Map<String, dynamic> json, {
    String fullName = '',
    String supervisorStatus = '',
  }) {
    final vNumId = json['volunteer_id'] is int
        ? json['volunteer_id'] as int
        : int.tryParse(json['volunteer_id']?.toString() ?? '0') ?? 0;
    
    final vCode = json['volunteer_code']?.toString() ??
        (vNumId > 0 ? 'COHV-26-${vNumId.toString().padLeft(4, '0')}' : '');

    final primaryId = vCode.isNotEmpty ? vCode : vNumId.toString();
    final status = json['status']?.toString() ?? 'PENDING';
    final message = json['message']?.toString() ?? 'Registration submitted. Awaiting supervisor approval.';
    final photo = json['photo_path']?.toString();

    return RegistrationResult(
      volunteerId: primaryId,
      numericVolunteerId: vNumId,
      volunteerCode: vCode,
      status: status,
      message: message,
      photoPath: photo,
      fullName: fullName.isNotEmpty ? fullName : (json['full_name']?.toString() ?? ''),
      supervisorStatus: supervisorStatus.isNotEmpty
          ? supervisorStatus
          : (json['supervisor_status']?.toString() ?? 'Assigned on approval'),
      accountStatus: status == 'ACTIVE' ? 'Active' : 'Inactive',
    );
  }
}
