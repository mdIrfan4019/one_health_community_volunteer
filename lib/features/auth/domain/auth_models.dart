import 'package:cohv/core/models/geo_location_data.dart';

enum AuthMode { pin, otp }

class SignInWithPinRequest {
  final String identifier; // Volunteer ID or 10-digit mobile
  final String pin;
  final String? deviceId;

  SignInWithPinRequest({
    required this.identifier,
    required this.pin,
    this.deviceId,
  });

  String get login => identifier;

  Map<String, dynamic> toJson() => {
    'login': identifier,
    'pin': pin,
    if (deviceId != null && deviceId!.isNotEmpty) 'device_id': deviceId,
  };
}

class SendOtpRequest {
  final String mobileNumber;

  SendOtpRequest({required this.mobileNumber});

  Map<String, dynamic> toJson() => {'mobile_number': mobileNumber};
}

class UserSession {
  final String volunteerId; // Volunteer Code e.g. "COHV-26-0004"
  final int? numericVolunteerId;
  final String fullName;
  final String mobile;
  final String sector; // cohv_type or department_name e.g. "Animal Husbandry Department"
  final int? departmentId;
  final String? departmentName;
  final String status; // "ACTIVE"
  final String token; // Bearer token
  final String tokenType; // "bearer"
  final int expiresIn;
  final String? email;
  final String? photoPath;
  final int? stateLgdCode;
  final String? stateName;
  final int? districtLgdCode;
  final String? districtName;
  final int? blockLgdCode;
  final String? blockName;
  final int? gramPanchayatLgdCode;
  final String? gramPanchayatName;
  final int? villageLgdCode;
  final String? villageName;
  final int? supervisorId;
  final String? supervisorName;

  UserSession({
    required this.volunteerId,
    this.numericVolunteerId,
    required this.fullName,
    required this.mobile,
    required this.sector,
    this.departmentId,
    this.departmentName,
    required this.status,
    required this.token,
    this.tokenType = 'bearer',
    this.expiresIn = 0,
    this.email,
    this.photoPath,
    this.stateLgdCode,
    this.stateName,
    this.districtLgdCode,
    this.districtName,
    this.blockLgdCode,
    this.blockName,
    this.gramPanchayatLgdCode,
    this.gramPanchayatName,
    this.villageLgdCode,
    this.villageName,
    this.supervisorId,
    this.supervisorName,
  });

  factory UserSession.fromJson(Map<String, dynamic> json, {String? token}) {
    // If backend returns LoginResponse containing 'volunteer' or 'data' map
    final volunteerMap = (json['volunteer'] is Map<String, dynamic>)
        ? json['volunteer'] as Map<String, dynamic>
        : (json['volunteer'] is Map
              ? Map<String, dynamic>.from(json['volunteer'] as Map)
              : (json['data'] is Map<String, dynamic>
                    ? json['data'] as Map<String, dynamic>
                    : (json['data'] is Map
                          ? Map<String, dynamic>.from(json['data'] as Map)
                          : json)));

    final explicitToken = token?.trim() ?? '';
    final parsedToken =
        json['access_token']?.toString() ?? json['token']?.toString() ?? '';
    final rawToken = parsedToken.isNotEmpty ? parsedToken : explicitToken;
    final tokenType = json['token_type']?.toString() ?? 'bearer';
    final expiresIn = json['expires_in'] is int
        ? json['expires_in'] as int
        : int.tryParse(json['expires_in']?.toString() ?? '0') ?? 0;

    final numId = volunteerMap['volunteer_id'] is int
        ? volunteerMap['volunteer_id'] as int
        : int.tryParse(volunteerMap['volunteer_id']?.toString() ?? '');

    final vCode =
        volunteerMap['volunteer_code']?.toString() ??
        (numId != null && numId > 0
            ? 'COHV-26-${numId.toString().padLeft(4, '0')}'
            : '');

    final primaryId = vCode.isNotEmpty
        ? vCode
        : (numId?.toString() ?? volunteerMap['volunteer_id']?.toString() ?? '');

    final deptId = volunteerMap['department_id'] is int
        ? volunteerMap['department_id'] as int
        : int.tryParse(volunteerMap['department_id']?.toString() ?? '');

    final deptName = volunteerMap['department_name']?.toString()?.trim();
    final cohvType = volunteerMap['cohv_type']?.toString()?.trim();
    final rawSector = volunteerMap['sector']?.toString()?.trim();

    // Derive sector strictly from server identity without hardcoded fallbacks
    final resolvedSector = (deptName != null && deptName.isNotEmpty)
        ? deptName
        : ((cohvType != null && cohvType.isNotEmpty)
            ? cohvType
            : (rawSector ?? ''));

    return UserSession(
      volunteerId: primaryId,
      numericVolunteerId: numId,
      fullName:
          volunteerMap['volunteer_name']?.toString() ??
          volunteerMap['full_name']?.toString() ??
          'Field Volunteer',
      mobile:
          volunteerMap['mobile_no']?.toString() ??
          volunteerMap['mobile']?.toString() ??
          '',
      sector: resolvedSector,
      departmentId: deptId,
      departmentName: deptName ?? (cohvType?.isNotEmpty == true ? cohvType : null),
      status: volunteerMap['status']?.toString() ?? 'ACTIVE',
      token: rawToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      email: volunteerMap['email']?.toString(),
      photoPath:
          volunteerMap['photo_path']?.toString() ??
          volunteerMap['photo_url']?.toString() ??
          volunteerMap['photo']?.toString(),
      stateLgdCode: volunteerMap['state_lgd_code'] is int
          ? volunteerMap['state_lgd_code'] as int
          : int.tryParse(volunteerMap['state_lgd_code']?.toString() ?? ''),
      stateName: volunteerMap['state_name']?.toString(),
      districtLgdCode: volunteerMap['district_lgd_code'] is int
          ? volunteerMap['district_lgd_code'] as int
          : int.tryParse(volunteerMap['district_lgd_code']?.toString() ?? ''),
      districtName: volunteerMap['district_name']?.toString(),
      blockLgdCode: volunteerMap['block_lgd_code'] is int
          ? volunteerMap['block_lgd_code'] as int
          : int.tryParse(volunteerMap['block_lgd_code']?.toString() ?? ''),
      blockName: volunteerMap['block_name']?.toString(),
      gramPanchayatLgdCode: volunteerMap['gram_panchayat_lgd_code'] is int
          ? volunteerMap['gram_panchayat_lgd_code'] as int
          : int.tryParse(
              volunteerMap['gram_panchayat_lgd_code']?.toString() ?? '',
            ),
      gramPanchayatName: volunteerMap['gram_panchayat_name']?.toString(),
      villageLgdCode: volunteerMap['village_lgd_code'] is int
          ? volunteerMap['village_lgd_code'] as int
          : int.tryParse(volunteerMap['village_lgd_code']?.toString() ?? ''),
      villageName: volunteerMap['village_name']?.toString(),
      supervisorId: volunteerMap['supervisor_id'] is int
          ? volunteerMap['supervisor_id'] as int
          : int.tryParse(volunteerMap['supervisor_id']?.toString() ?? ''),
      supervisorName: volunteerMap['supervisor_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'volunteer_id': numericVolunteerId ?? int.tryParse(volunteerId),
    'volunteer_code': volunteerId,
    'volunteer_name': fullName,
    'full_name': fullName,
    'mobile_no': mobile,
    'mobile': mobile,
    'department_id': departmentId,
    'department_name': departmentName ?? sector,
    'cohv_type': sector,
    'sector': sector,
    'status': status,
    'access_token': token,
    'token': token,
    'token_type': tokenType,
    'expires_in': expiresIn,
    'email': email,
    'photo_path': photoPath,
    'state_lgd_code': stateLgdCode,
    'state_name': stateName,
    'district_lgd_code': districtLgdCode,
    'district_name': districtName,
    'block_lgd_code': blockLgdCode,
    'block_name': blockName,
    'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    'gram_panchayat_name': gramPanchayatName,
    'village_lgd_code': villageLgdCode,
    'village_name': villageName,
    'supervisor_id': supervisorId,
    'supervisor_name': supervisorName,
  };

  UserSession copyWith({
    String? volunteerId,
    int? numericVolunteerId,
    String? fullName,
    String? mobile,
    String? sector,
    int? departmentId,
    String? departmentName,
    String? status,
    String? token,
    String? tokenType,
    int? expiresIn,
    String? email,
    String? photoPath,
    int? stateLgdCode,
    String? stateName,
    int? districtLgdCode,
    String? districtName,
    int? blockLgdCode,
    String? blockName,
    int? gramPanchayatLgdCode,
    String? gramPanchayatName,
    int? villageLgdCode,
    String? villageName,
    int? supervisorId,
    String? supervisorName,
  }) {
    return UserSession(
      volunteerId: volunteerId ?? this.volunteerId,
      numericVolunteerId: numericVolunteerId ?? this.numericVolunteerId,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      sector: sector ?? this.sector,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      status: status ?? this.status,
      token: token ?? this.token,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      stateLgdCode: stateLgdCode ?? this.stateLgdCode,
      stateName: stateName ?? this.stateName,
      districtLgdCode: districtLgdCode ?? this.districtLgdCode,
      districtName: districtName ?? this.districtName,
      blockLgdCode: blockLgdCode ?? this.blockLgdCode,
      blockName: blockName ?? this.blockName,
      gramPanchayatLgdCode: gramPanchayatLgdCode ?? this.gramPanchayatLgdCode,
      gramPanchayatName: gramPanchayatName ?? this.gramPanchayatName,
      villageLgdCode: villageLgdCode ?? this.villageLgdCode,
      villageName: villageName ?? this.villageName,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
    );
  }

  /// Geographic location breadcrumb (e.g. "Amrabad · Amrabad · Nagarkurnool")
  String get locationBreadcrumb {
    final parts = [
      villageName,
      blockName,
      districtName,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }
    return stateName ?? '';
  }
}

/// Authentication specific exception with HTTP status code details
class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, {this.statusCode = 400});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

// Append to: lib/features/auth/domain/auth_models.dart

class VerifyOtpRequest {
  final String mobileNumber;
  final String otp;

  VerifyOtpRequest({required this.mobileNumber, required this.otp});

  Map<String, dynamic> toJson() => {'mobile_number': mobileNumber, 'otp': otp};
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
  final int? departmentId;
  final int? institutionTypeId;
  final String? institutionName;
  final String? customInstitutionName;

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
    this.departmentId,
    this.institutionTypeId,
    this.institutionName,
    this.customInstitutionName,
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
    'date_of_birth':
        '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
    'mobile_no': mobileNo,
    'email': email,
    'cohv_type': cohvType,
    'state_lgd_code': stateLgdCode,
    'district_lgd_code': districtLgdCode,
    'block_lgd_code': blockLgdCode,
    'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    'village_lgd_code': villageLgdCode,
    'date_of_joining':
        '${dateOfJoining.year.toString().padLeft(4, '0')}-${dateOfJoining.month.toString().padLeft(2, '0')}-${dateOfJoining.day.toString().padLeft(2, '0')}',
    'education_id': educationId,
    'profession_id': professionId,
    'pin': pin,
    if (supervisorId != null && supervisorId! > 0)
      'supervisor_id': supervisorId,
    if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null)
      'gps_unavailable_reason': gpsUnavailableReason,
    if (deviceId != null) 'device_id': deviceId,
    if (photoPath != null) 'photo_path': photoPath,
    if (departmentId != null) 'department_id': departmentId,
    if (institutionTypeId != null) 'institution_type_id': institutionTypeId,
    if (institutionName != null && institutionName!.isNotEmpty)
      'institution_name': institutionName,
    if (customInstitutionName != null && customInstitutionName!.isNotEmpty)
      'custom_institution_name': customInstitutionName,
  };
}

class RegistrationResult {
  final String
  volunteerId; // Usually the formatted volunteer_code e.g. "COHV-26-0002"
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

    final vCode =
        json['volunteer_code']?.toString() ??
        (vNumId > 0 ? 'COHV-26-${vNumId.toString().padLeft(4, '0')}' : '');

    final primaryId = vCode.isNotEmpty ? vCode : vNumId.toString();
    final status = json['status']?.toString() ?? 'PENDING';
    final message =
        json['message']?.toString() ??
        'Registration submitted. Awaiting supervisor approval.';
    final photo = json['photo_path']?.toString();

    return RegistrationResult(
      volunteerId: primaryId,
      numericVolunteerId: vNumId,
      volunteerCode: vCode,
      status: status,
      message: message,
      photoPath: photo,
      fullName: fullName.isNotEmpty
          ? fullName
          : (json['full_name']?.toString() ?? ''),
      supervisorStatus: supervisorStatus.isNotEmpty
          ? supervisorStatus
          : (json['supervisor_status']?.toString() ?? 'Assigned on approval'),
      accountStatus: status == 'ACTIVE' ? 'Active' : 'Inactive',
    );
  }
}
