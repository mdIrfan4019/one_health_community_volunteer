import 'package:cohv/features/auth/domain/auth_models.dart';

class DetailedVolunteerProfile {
  final String fullName;
  final String volunteerId;
  final String designation;
  final String gender;
  final String dob;
  final String mobileNumber;
  final String email;
  final String village;
  final String panchayat;
  final String block;
  final String division;
  final String district;
  final String state;
  final String dateOfJoining;
  final String qualification;
  final String profession;
  final String supervisor;
  final String healthFacilityLinked;
  final String veterinaryInstitutionLinked;
  final String forestInstitutionLinked;
  final String preferredLanguage;
  final String status;
  final String lastLogin;
  final String registrationGps;
  final String? photoUrl;
  final int? stateLgdCode;
  final int? districtLgdCode;
  final int? blockLgdCode;
  final int? gramPanchayatLgdCode;
  final int? villageLgdCode;
  final int? supervisorId;
  final int? numericVolunteerId;

  DetailedVolunteerProfile({
    required this.fullName,
    required this.volunteerId,
    this.designation = 'COHV',
    required this.gender,
    required this.dob,
    required this.mobileNumber,
    required this.email,
    required this.village,
    required this.panchayat,
    required this.block,
    required this.division,
    required this.district,
    required this.state,
    required this.dateOfJoining,
    required this.qualification,
    required this.profession,
    required this.supervisor,
    this.healthFacilityLinked = 'CHC',
    this.veterinaryInstitutionLinked = '—',
    this.forestInstitutionLinked = '—',
    this.preferredLanguage = 'English',
    this.status = 'ACTIVE',
    required this.lastLogin,
    required this.registrationGps,
    this.photoUrl,
    this.stateLgdCode,
    this.districtLgdCode,
    this.blockLgdCode,
    this.gramPanchayatLgdCode,
    this.villageLgdCode,
    this.supervisorId,
    this.numericVolunteerId,
  });

  DetailedVolunteerProfile copyWith({
    String? fullName,
    String? volunteerId,
    String? designation,
    String? gender,
    String? dob,
    String? mobileNumber,
    String? email,
    String? village,
    String? panchayat,
    String? block,
    String? division,
    String? district,
    String? state,
    String? dateOfJoining,
    String? qualification,
    String? profession,
    String? supervisor,
    String? healthFacilityLinked,
    String? veterinaryInstitutionLinked,
    String? forestInstitutionLinked,
    String? preferredLanguage,
    String? status,
    String? lastLogin,
    String? registrationGps,
    String? photoUrl,
    int? stateLgdCode,
    int? districtLgdCode,
    int? blockLgdCode,
    int? gramPanchayatLgdCode,
    int? villageLgdCode,
    int? supervisorId,
    int? numericVolunteerId,
  }) {
    return DetailedVolunteerProfile(
      fullName: fullName ?? this.fullName,
      volunteerId: volunteerId ?? this.volunteerId,
      designation: designation ?? this.designation,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      village: village ?? this.village,
      panchayat: panchayat ?? this.panchayat,
      block: block ?? this.block,
      division: division ?? this.division,
      district: district ?? this.district,
      state: state ?? this.state,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      qualification: qualification ?? this.qualification,
      profession: profession ?? this.profession,
      supervisor: supervisor ?? this.supervisor,
      healthFacilityLinked: healthFacilityLinked ?? this.healthFacilityLinked,
      veterinaryInstitutionLinked: veterinaryInstitutionLinked ?? this.veterinaryInstitutionLinked,
      forestInstitutionLinked: forestInstitutionLinked ?? this.forestInstitutionLinked,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      registrationGps: registrationGps ?? this.registrationGps,
      photoUrl: photoUrl ?? this.photoUrl,
      stateLgdCode: stateLgdCode ?? this.stateLgdCode,
      districtLgdCode: districtLgdCode ?? this.districtLgdCode,
      blockLgdCode: blockLgdCode ?? this.blockLgdCode,
      gramPanchayatLgdCode: gramPanchayatLgdCode ?? this.gramPanchayatLgdCode,
      villageLgdCode: villageLgdCode ?? this.villageLgdCode,
      supervisorId: supervisorId ?? this.supervisorId,
      numericVolunteerId: numericVolunteerId ?? this.numericVolunteerId,
    );
  }

  /// Factory constructor to populate profile directly from /api/auth/me response
  factory DetailedVolunteerProfile.fromMeJson(Map<String, dynamic> json) {
    final vNumId = json['volunteer_id'] is int
        ? json['volunteer_id'] as int
        : int.tryParse(json['volunteer_id']?.toString() ?? '');

    final vCode = json['volunteer_code']?.toString() ??
        (vNumId != null && vNumId > 0 ? 'COHV-26-${vNumId.toString().padLeft(4, '0')}' : '');

    final primaryId = vCode.isNotEmpty ? vCode : (vNumId?.toString() ?? json['volunteer_id']?.toString() ?? 'COHV-26-0001');

    final supId = json['supervisor_id'] is int
        ? json['supervisor_id'] as int
        : int.tryParse(json['supervisor_id']?.toString() ?? '');
    final supName = json['supervisor_name']?.toString() ?? json['supervisor']?.toString();

    final stLgd = json['state_lgd_code'] is int
        ? json['state_lgd_code'] as int
        : int.tryParse(json['state_lgd_code']?.toString() ?? '');
    final distLgd = json['district_lgd_code'] is int
        ? json['district_lgd_code'] as int
        : int.tryParse(json['district_lgd_code']?.toString() ?? '');
    final blkLgd = json['block_lgd_code'] is int
        ? json['block_lgd_code'] as int
        : int.tryParse(json['block_lgd_code']?.toString() ?? '');
    final gpLgd = json['gram_panchayat_lgd_code'] is int
        ? json['gram_panchayat_lgd_code'] as int
        : int.tryParse(json['gram_panchayat_lgd_code']?.toString() ?? '');
    final vilLgd = json['village_lgd_code'] is int
        ? json['village_lgd_code'] as int
        : int.tryParse(json['village_lgd_code']?.toString() ?? '');

    final stateName = json['state_name']?.toString() ?? json['state']?.toString() ?? '—';
    final districtName = json['district_name']?.toString() ?? json['district']?.toString() ?? '—';
    final blockName = json['block_name']?.toString() ?? json['block']?.toString() ?? '—';
    final gpName = json['gram_panchayat_name']?.toString() ?? json['panchayat']?.toString() ?? '—';
    final vilName = json['village_name']?.toString() ?? json['village']?.toString() ?? '—';

    return DetailedVolunteerProfile(
      fullName: json['volunteer_name']?.toString() ?? json['full_name']?.toString() ?? 'Field Volunteer',
      volunteerId: primaryId,
      designation: json['cohv_type']?.toString() ?? json['designation']?.toString() ?? 'Public Health',
      gender: json['gender']?.toString() ?? '—',
      dob: json['dob']?.toString() ?? json['date_of_birth']?.toString() ?? '—',
      mobileNumber: json['mobile_no']?.toString() ?? json['mobile_number']?.toString() ?? '—',
      email: json['email']?.toString() ?? '—',
      village: vilName,
      panchayat: gpName,
      block: blockName,
      division: districtName != '—' ? '$districtName Division' : '—',
      district: districtName,
      state: stateName,
      dateOfJoining: json['date_of_joining']?.toString() ?? '—',
      qualification: json['qualification']?.toString() ?? json['education']?.toString() ?? '—',
      profession: json['profession']?.toString() ?? '—',
      supervisor: supName != null && supName.isNotEmpty
          ? (supId != null ? '$supName (ID: $supId)' : supName)
          : 'Assigned on approval',
      healthFacilityLinked: json['health_facility_linked']?.toString() ?? 'CHC',
      veterinaryInstitutionLinked: json['veterinary_institution_linked']?.toString() ?? '—',
      forestInstitutionLinked: json['forest_institution_linked']?.toString() ?? '—',
      preferredLanguage: json['preferred_language']?.toString() ?? 'English',
      status: json['status']?.toString() ?? 'ACTIVE',
      lastLogin: json['last_login']?.toString() ?? 'Active session verified',
      registrationGps: json['registration_gps']?.toString() ?? '—',
      photoUrl: json['photo_path']?.toString() ?? json['photo_url']?.toString(),
      stateLgdCode: stLgd,
      districtLgdCode: distLgd,
      blockLgdCode: blkLgd,
      gramPanchayatLgdCode: gpLgd,
      villageLgdCode: vilLgd,
      supervisorId: supId,
      numericVolunteerId: vNumId,
    );
  }

  factory DetailedVolunteerProfile.fromJson(Map<String, dynamic> json) =>
      DetailedVolunteerProfile.fromMeJson(json);

  /// Map directly from an authenticated UserSession instance
  factory DetailedVolunteerProfile.fromUserSession(UserSession session) {
    final stateName = session.stateName ?? '—';
    final distName = session.districtName ?? '—';
    final blkName = session.blockName ?? '—';
    final gpName = session.gramPanchayatName ?? '—';
    final vilName = session.villageName ?? '—';

    return DetailedVolunteerProfile(
      fullName: session.fullName,
      volunteerId: session.volunteerId,
      designation: session.sector.isNotEmpty ? session.sector : 'Public Health',
      gender: '—',
      dob: '—',
      mobileNumber: session.mobile,
      email: session.email != null && session.email!.isNotEmpty ? session.email! : '—',
      village: vilName,
      panchayat: gpName,
      block: blkName,
      division: distName != '—' ? '$distName Division' : '—',
      district: distName,
      state: stateName,
      dateOfJoining: '—',
      qualification: '—',
      profession: '—',
      supervisor: session.supervisorName != null && session.supervisorName!.isNotEmpty
          ? (session.supervisorId != null
              ? '${session.supervisorName} (ID: ${session.supervisorId})'
              : session.supervisorName!)
          : 'Assigned on approval',
      healthFacilityLinked: 'CHC',
      veterinaryInstitutionLinked: '—',
      forestInstitutionLinked: '—',
      preferredLanguage: 'English',
      status: session.status.isNotEmpty ? session.status : 'ACTIVE',
      lastLogin: 'Active session verified',
      registrationGps: '—',
      photoUrl: session.photoPath,
      stateLgdCode: session.stateLgdCode,
      districtLgdCode: session.districtLgdCode,
      blockLgdCode: session.blockLgdCode,
      gramPanchayatLgdCode: session.gramPanchayatLgdCode,
      villageLgdCode: session.villageLgdCode,
      supervisorId: session.supervisorId,
      numericVolunteerId: session.numericVolunteerId,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'volunteer_id': volunteerId,
    'designation': designation,
    'gender': gender,
    'dob': dob,
    'mobile_number': mobileNumber,
    'email': email,
    'village': village,
    'panchayat': panchayat,
    'block': block,
    'division': division,
    'district': district,
    'state': state,
    'date_of_joining': dateOfJoining,
    'qualification': qualification,
    'profession': profession,
    'supervisor': supervisor,
    'health_facility_linked': healthFacilityLinked,
    'veterinary_institution_linked': veterinaryInstitutionLinked,
    'forest_institution_linked': forestInstitutionLinked,
    'preferred_language': preferredLanguage,
    'status': status,
    'last_login': lastLogin,
    'registration_gps': registrationGps,
    'photo_url': photoUrl,
    'state_lgd_code': stateLgdCode,
    'district_lgd_code': districtLgdCode,
    'block_lgd_code': blockLgdCode,
    'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    'village_lgd_code': villageLgdCode,
    'supervisor_id': supervisorId,
    'numeric_volunteer_id': numericVolunteerId,
  };

  /// Merges user-edited fields into fetched profile so edits aren't replaced by '—'
  DetailedVolunteerProfile merge(DetailedVolunteerProfile? other) {
    if (other == null) return this;
    return copyWith(
      gender: other.gender != '—' && other.gender.isNotEmpty ? other.gender : gender,
      dob: other.dob != '—' && other.dob.isNotEmpty ? other.dob : dob,
      qualification: other.qualification != '—' && other.qualification.isNotEmpty ? other.qualification : qualification,
      profession: other.profession != '—' && other.profession.isNotEmpty ? other.profession : profession,
      dateOfJoining: other.dateOfJoining != '—' && other.dateOfJoining.isNotEmpty ? other.dateOfJoining : dateOfJoining,
      preferredLanguage: other.preferredLanguage != '—' && other.preferredLanguage.isNotEmpty ? other.preferredLanguage : preferredLanguage,
      registrationGps: other.registrationGps != '—' && other.registrationGps.isNotEmpty ? other.registrationGps : registrationGps,
      photoUrl: (photoUrl != null && photoUrl!.trim().isNotEmpty && photoUrl != '—')
          ? photoUrl
          : ((other.photoUrl != null && other.photoUrl!.trim().isNotEmpty && other.photoUrl != '—')
              ? other.photoUrl
              : photoUrl),
      mobileNumber: other.mobileNumber != '—' && other.mobileNumber.isNotEmpty ? other.mobileNumber : mobileNumber,
      email: other.email != '—' && other.email.isNotEmpty ? other.email : email,
    );
  }
}

class LoginHistoryEntry {
  final String timestamp;
  final String authMethod;
  final String deviceId;

  LoginHistoryEntry({
    required this.timestamp,
    this.authMethod = 'PIN',
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'auth_method': authMethod,
    'device_id': deviceId,
  };

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      timestamp: json['timestamp']?.toString() ?? '',
      authMethod: json['auth_method']?.toString() ?? 'PIN',
      deviceId: json['device_id']?.toString() ?? 'DEV-C0YBZ9WK',
    );
  }
}
