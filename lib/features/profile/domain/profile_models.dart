import 'package:cohv/features/auth/domain/auth_models.dart';

class DetailedVolunteerProfile {
  final String fullName;
  final String volunteerId; // Volunteer Code (e.g., COHV-26-0005)
  final String designation; // COHV Type or Department Name
  final String gender;
  final String dob;
  final String? rawDateOfBirth;
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
  final String? institutionFieldLabel;

  // LGD Location Codes
  final int? stateLgdCode;
  final int? districtLgdCode;
  final int? blockLgdCode;
  final int? gramPanchayatLgdCode;
  final int? villageLgdCode;

  // Identifiers & Master IDs
  final int? supervisorId;
  final int? numericVolunteerId;
  final int? departmentId;
  final String? departmentName;
  final String? cohvType;
  final int? institutionTypeId;
  final String? institutionTypeName;
  final String? institutionName;
  final String? otherInstitutionName;
  final int? educationId;
  final int? professionId;

  // Supervisor contact
  final String? supervisorMobile;
  final String? supervisorEmail;

  // Status & Approval
  final String? statusRemarks;
  final int? approvedBy;
  final String? approvedByName;
  final String? approvedAt;

  // Device & GPS Metadata
  final String? regLatitude;
  final String? regLongitude;
  final int? regGpsAccuracyM;
  final String? regGpsUnavailableReason;
  final String? deviceId;
  final String? createdAt;
  final String? updatedAt;

  // Summary Activity Metrics
  final int totalVisits;
  final int alertsGenerated;
  final int referrals;
  final int awarenessActivities;

  DetailedVolunteerProfile({
    required this.fullName,
    required this.volunteerId,
    this.designation = 'COHV',
    required this.gender,
    required this.dob,
    this.rawDateOfBirth,
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
    this.institutionFieldLabel,
    this.stateLgdCode,
    this.districtLgdCode,
    this.blockLgdCode,
    this.gramPanchayatLgdCode,
    this.villageLgdCode,
    this.supervisorId,
    this.numericVolunteerId,
    this.departmentId,
    this.departmentName,
    this.cohvType,
    this.institutionTypeId,
    this.institutionTypeName,
    this.institutionName,
    this.otherInstitutionName,
    this.educationId,
    this.professionId,
    this.supervisorMobile,
    this.supervisorEmail,
    this.statusRemarks,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.regLatitude,
    this.regLongitude,
    this.regGpsAccuracyM,
    this.regGpsUnavailableReason,
    this.deviceId,
    this.createdAt,
    this.updatedAt,
    this.totalVisits = 0,
    this.alertsGenerated = 0,
    this.referrals = 0,
    this.awarenessActivities = 0,
  });

  DetailedVolunteerProfile copyWith({
    String? fullName,
    String? volunteerId,
    String? designation,
    String? gender,
    String? dob,
    String? rawDateOfBirth,
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
    String? institutionFieldLabel,
    int? stateLgdCode,
    int? districtLgdCode,
    int? blockLgdCode,
    int? gramPanchayatLgdCode,
    int? villageLgdCode,
    int? supervisorId,
    int? numericVolunteerId,
    int? departmentId,
    String? departmentName,
    String? cohvType,
    int? institutionTypeId,
    String? institutionTypeName,
    String? institutionName,
    String? otherInstitutionName,
    int? educationId,
    int? professionId,
    String? supervisorMobile,
    String? supervisorEmail,
    String? statusRemarks,
    int? approvedBy,
    String? approvedByName,
    String? approvedAt,
    String? regLatitude,
    String? regLongitude,
    int? regGpsAccuracyM,
    String? regGpsUnavailableReason,
    String? deviceId,
    String? createdAt,
    String? updatedAt,
    int? totalVisits,
    int? alertsGenerated,
    int? referrals,
    int? awarenessActivities,
  }) {
    return DetailedVolunteerProfile(
      fullName: fullName ?? this.fullName,
      volunteerId: volunteerId ?? this.volunteerId,
      designation: designation ?? this.designation,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      rawDateOfBirth: rawDateOfBirth ?? this.rawDateOfBirth,
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
      healthFacilityLinked:
          healthFacilityLinked ?? this.healthFacilityLinked,
      veterinaryInstitutionLinked:
          veterinaryInstitutionLinked ?? this.veterinaryInstitutionLinked,
      forestInstitutionLinked:
          forestInstitutionLinked ?? this.forestInstitutionLinked,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      registrationGps: registrationGps ?? this.registrationGps,
      photoUrl: photoUrl ?? this.photoUrl,
      institutionFieldLabel:
          institutionFieldLabel ?? this.institutionFieldLabel,
      stateLgdCode: stateLgdCode ?? this.stateLgdCode,
      districtLgdCode: districtLgdCode ?? this.districtLgdCode,
      blockLgdCode: blockLgdCode ?? this.blockLgdCode,
      gramPanchayatLgdCode:
          gramPanchayatLgdCode ?? this.gramPanchayatLgdCode,
      villageLgdCode: villageLgdCode ?? this.villageLgdCode,
      supervisorId: supervisorId ?? this.supervisorId,
      numericVolunteerId: numericVolunteerId ?? this.numericVolunteerId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      cohvType: cohvType ?? this.cohvType,
      institutionTypeId: institutionTypeId ?? this.institutionTypeId,
      institutionTypeName:
          institutionTypeName ?? this.institutionTypeName,
      institutionName: institutionName ?? this.institutionName,
      otherInstitutionName:
          otherInstitutionName ?? this.otherInstitutionName,
      educationId: educationId ?? this.educationId,
      professionId: professionId ?? this.professionId,
      supervisorMobile: supervisorMobile ?? this.supervisorMobile,
      supervisorEmail: supervisorEmail ?? this.supervisorEmail,
      statusRemarks: statusRemarks ?? this.statusRemarks,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      regLatitude: regLatitude ?? this.regLatitude,
      regLongitude: regLongitude ?? this.regLongitude,
      regGpsAccuracyM: regGpsAccuracyM ?? this.regGpsAccuracyM,
      regGpsUnavailableReason:
          regGpsUnavailableReason ?? this.regGpsUnavailableReason,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalVisits: totalVisits ?? this.totalVisits,
      alertsGenerated: alertsGenerated ?? this.alertsGenerated,
      referrals: referrals ?? this.referrals,
      awarenessActivities: awarenessActivities ?? this.awarenessActivities,
    );
  }

  /// Calculated age in years if date of birth is known
  int? get age {
    final raw = rawDateOfBirth ?? dob;
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        final now = DateTime.now();
        int a = now.year - parsed.year;
        if (now.month < parsed.month ||
            (now.month == parsed.month && now.day < parsed.day)) {
          a--;
        }
        if (a >= 0 && a < 130) return a;
      }
    } catch (_) {}
    return null;
  }

  /// Formatted age and date of birth display, e.g. "25 yrs (24 Oct 2001)" or "24 Oct 2001"
  String get ageAndDobDisplay {
    if (dob == '—' || dob.isEmpty) return '—';
    final a = age;
    if (a != null && a > 0) {
      return '$a yrs ($dob)';
    }
    return dob;
  }

  /// Formatted ISO date (YYYY-MM-DD) for API payloads
  String get formattedIsoDateOfBirth {
    final raw = rawDateOfBirth?.trim();
    if (raw != null && raw.isNotEmpty && raw != '—') {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        return raw;
      }
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      }
    }
    final d = dob.trim();
    if (d.isNotEmpty && d != '—') {
      final parsed = DateTime.tryParse(d);
      if (parsed != null) {
        return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      }
      try {
        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        final parts = d.split(RegExp(r'[\s\-]+'));
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final mon = months[parts[1].toLowerCase()] ?? int.tryParse(parts[1]);
          final yr = int.tryParse(parts[2]);
          if (day != null && mon != null && yr != null) {
            return '${yr.toString().padLeft(4, '0')}-${mon.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          }
        }
      } catch (_) {}
    }
    return '';
  }

  /// Generates request body map matching Swagger PUT /api/volunteers/{volunteer_id} schema
  Map<String, dynamic> toUpdateJson({String? photoPayload}) {
    final isoDob = formattedIsoDateOfBirth;
    return <String, dynamic>{
      'volunteer_name': fullName.trim(),
      'gender': gender,
      'date_of_birth': isoDob.isNotEmpty ? isoDob : (rawDateOfBirth ?? dob),
      'mobile_no': mobileNumber.trim(),
      if (email.isNotEmpty && email != '—') 'email': email.trim(),
      if (institutionTypeId != null && institutionTypeId! > 0)
        'institution_type_id': institutionTypeId,
      if (institutionName != null && institutionName!.isNotEmpty)
        'institution_name': institutionName,
      'other_institution_name': otherInstitutionName,
      if (educationId != null && educationId! > 0)
        'education_id': educationId,
      if (professionId != null && professionId! > 0)
        'profession_id': professionId,
      if (stateLgdCode != null) 'state_lgd_code': stateLgdCode,
      if (districtLgdCode != null) 'district_lgd_code': districtLgdCode,
      if (blockLgdCode != null) 'block_lgd_code': blockLgdCode,
      if (gramPanchayatLgdCode != null)
        'gram_panchayat_lgd_code': gramPanchayatLgdCode,
      if (villageLgdCode != null) 'village_lgd_code': villageLgdCode,
      if (photoPayload != null && photoPayload.isNotEmpty)
        'photo': photoPayload,
    };
  }

  /// Dynamic institution display value
  String get institutionDisplay {
    if (otherInstitutionName != null &&
        otherInstitutionName!.trim().isNotEmpty) {
      return otherInstitutionName!.trim();
    }
    if (institutionName != null && institutionName!.trim().isNotEmpty) {
      return institutionName!.trim();
    }
    if (institutionTypeName != null &&
        institutionTypeName!.trim().isNotEmpty) {
      return institutionTypeName!.trim();
    }
    return healthFacilityLinked != '—' ? healthFacilityLinked : '—';
  }

  /// Helper to format ISO dates (YYYY-MM-DD) into user-friendly strings (DD Mon YYYY)
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr == '—') return '—';
    try {
      final parsed = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Helper to format ISO datetime into user-friendly localized strings
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr == '—') return '—';
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return dateStr;
    }
  }

  /// Factory constructor to populate profile directly from GET /api/volunteers/profile response
  factory DetailedVolunteerProfile.fromVolunteerProfileJson(
    Map<String, dynamic> json,
  ) {
    // 1. Volunteer codes and IDs
    final vNumId = json['volunteer_id'] is int
        ? json['volunteer_id'] as int
        : int.tryParse(json['volunteer_id']?.toString() ?? '');
    final vCode = json['volunteer_code']?.toString() ?? '';
    final primaryId = vCode.isNotEmpty
        ? vCode
        : (vNumId != null && vNumId > 0
            ? 'COHV-26-${vNumId.toString().padLeft(4, '0')}'
            : (json['volunteer_id']?.toString() ?? ''));

    // 2. Names and personal details
    final fullName = json['volunteer_name']?.toString() ??
        json['full_name']?.toString() ??
        'Field Volunteer';
    final rawGender = json['gender']?.toString() ?? '—';
    final gender = rawGender.length > 1
        ? '${rawGender[0].toUpperCase()}${rawGender.substring(1).toLowerCase()}'
        : rawGender;
    final rawDob = json['date_of_birth']?.toString() ??
        json['dob']?.toString() ??
        '—';
    final dob = formatDate(rawDob);
    final mobile = json['mobile_no']?.toString() ??
        json['mobile_number']?.toString() ??
        '—';
    final email = json['email']?.toString() ?? '—';

    // 3. Department and COHV Type
    final deptId = json['department_id'] is int
        ? json['department_id'] as int
        : int.tryParse(json['department_id']?.toString() ?? '');
    final deptName = json['department_name']?.toString();
    final cohvType = json['cohv_type']?.toString() ??
        deptName ??
        json['designation']?.toString() ??
        'Public Health Department';

    // 4. Institution details
    final instTypeId = json['institution_type_id'] is int
        ? json['institution_type_id'] as int
        : int.tryParse(json['institution_type_id']?.toString() ?? '');
    final instTypeName = json['institution_type_name']?.toString();
    final instName = json['institution_name']?.toString() ??
        json['other_institution_name']?.toString();
    final otherInstName = json['other_institution_name']?.toString();

    // 5. Locations
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

    final stateName = json['state_name']?.toString() ??
        json['state']?.toString() ??
        '—';
    final districtName = json['district_name']?.toString() ??
        json['district']?.toString() ??
        '—';
    final blockName = json['block_name']?.toString() ??
        json['block']?.toString() ??
        '—';
    final gpName = json['gram_panchayat_name']?.toString() ??
        json['panchayat']?.toString() ??
        '—';
    final vilName = json['village_name']?.toString() ??
        json['village']?.toString() ??
        '—';

    // 6. Dates, Education, Profession
    final rawDoj = json['date_of_joining']?.toString() ?? '—';
    final doj = formatDate(rawDoj);
    final eduId = json['education_id'] is int
        ? json['education_id'] as int
        : int.tryParse(json['education_id']?.toString() ?? '');
    final eduName = json['education_name']?.toString() ??
        json['education']?.toString() ??
        json['qualification']?.toString() ??
        '—';
    final profId = json['profession_id'] is int
        ? json['profession_id'] as int
        : int.tryParse(json['profession_id']?.toString() ?? '');
    final profName = json['profession_name']?.toString() ??
        json['profession']?.toString() ??
        '—';

    // 7. Supervisor
    final supId = json['supervisor_id'] is int
        ? json['supervisor_id'] as int
        : int.tryParse(json['supervisor_id']?.toString() ?? '');
    final supName = json['supervisor_name']?.toString() ??
        json['supervisor']?.toString();
    final supMobile = json['supervisor_mobile']?.toString();
    final supEmail = json['supervisor_email']?.toString();
    final supervisorDisplay = supName != null && supName.isNotEmpty
        ? (supId != null ? '$supName (ID: $supId)' : supName)
        : 'Assigned on approval';

    // 8. Photo, Status & GPS
    final photo = json['photo_path']?.toString() ??
        json['photo_url']?.toString();
    final rawStatus = json['status']?.toString() ?? 'ACTIVE';
    final status = rawStatus.isNotEmpty
        ? '${rawStatus[0].toUpperCase()}${rawStatus.substring(1).toLowerCase()}'
        : 'Active';

    final regLat = json['reg_latitude']?.toString();
    final regLong = json['reg_longitude']?.toString();
    final gpsAcc = json['reg_gps_accuracy_m'] is int
        ? json['reg_gps_accuracy_m'] as int
        : int.tryParse(json['reg_gps_accuracy_m']?.toString() ?? '');
    final gpsDisplay = (regLat != null &&
            regLong != null &&
            regLat.isNotEmpty &&
            regLong.isNotEmpty)
        ? '$regLat, $regLong'
        : (json['registration_gps']?.toString() ?? '—');

    // 9. Activity metrics
    final visits = json['total_visits'] is int
        ? json['total_visits'] as int
        : int.tryParse(json['total_visits']?.toString() ?? '') ?? 0;
    final alerts = json['alerts_generated'] is int
        ? json['alerts_generated'] as int
        : int.tryParse(json['alerts_generated']?.toString() ?? '') ?? 0;
    final refs = json['referrals'] is int
        ? json['referrals'] as int
        : int.tryParse(json['referrals']?.toString() ?? '') ?? 0;
    final awareness = json['awareness_activities'] is int
        ? json['awareness_activities'] as int
        : int.tryParse(json['awareness_activities']?.toString() ?? '') ?? 0;

    final rawLastLogin = json['last_login_at']?.toString() ??
        json['last_login']?.toString();
    final lastLoginFormatted = rawLastLogin != null && rawLastLogin.isNotEmpty
        ? formatDateTime(rawLastLogin)
        : 'Active session verified';

    final designationValue = profName.isNotEmpty && profName != '—'
        ? profName
        : (json['designation']?.toString() ?? 'COHV');

    final instFieldLabel = json['institution_field_label']?.toString() ??
        json['field_label']?.toString();

    return DetailedVolunteerProfile(
      fullName: fullName,
      volunteerId: primaryId,
      designation: designationValue,
      gender: gender,
      dob: dob,
      rawDateOfBirth: rawDob != '—' ? rawDob : null,
      mobileNumber: mobile,
      email: email,
      village: vilName,
      panchayat: gpName,
      block: blockName,
      division: districtName != '—' ? '$districtName Division' : '—',
      district: districtName,
      state: stateName,
      dateOfJoining: doj,
      qualification: eduName,
      profession: profName,
      supervisor: supervisorDisplay,
      healthFacilityLinked: instName ?? 'CHC',
      veterinaryInstitutionLinked: '—',
      forestInstitutionLinked: '—',
      preferredLanguage: json['preferred_language']?.toString() ?? 'English',
      status: status,
      lastLogin: lastLoginFormatted,
      registrationGps: gpsDisplay,
      photoUrl: photo,
      institutionFieldLabel: instFieldLabel,
      stateLgdCode: stLgd,
      districtLgdCode: distLgd,
      blockLgdCode: blkLgd,
      gramPanchayatLgdCode: gpLgd,
      villageLgdCode: vilLgd,
      supervisorId: supId,
      numericVolunteerId: vNumId,
      departmentId: deptId,
      departmentName: deptName,
      cohvType: cohvType,
      institutionTypeId: instTypeId,
      institutionTypeName: instTypeName,
      institutionName: instName,
      otherInstitutionName: otherInstName,
      educationId: eduId,
      professionId: profId,
      supervisorMobile: supMobile,
      supervisorEmail: supEmail,
      statusRemarks: json['status_remarks']?.toString(),
      approvedBy: json['approved_by'] is int
          ? json['approved_by'] as int
          : int.tryParse(json['approved_by']?.toString() ?? ''),
      approvedByName: json['approved_by_name']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      regLatitude: regLat,
      regLongitude: regLong,
      regGpsAccuracyM: gpsAcc,
      regGpsUnavailableReason: json['reg_gps_unavailable_reason']?.toString(),
      deviceId: json['device_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      totalVisits: visits,
      alertsGenerated: alerts,
      referrals: refs,
      awarenessActivities: awareness,
    );
  }

  factory DetailedVolunteerProfile.fromJson(Map<String, dynamic> json) =>
      DetailedVolunteerProfile.fromVolunteerProfileJson(json);

  factory DetailedVolunteerProfile.fromMeJson(Map<String, dynamic> json) =>
      DetailedVolunteerProfile.fromVolunteerProfileJson(json);

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
      designation: session.sector.isNotEmpty ? session.sector : 'COHV',
      gender: '—',
      dob: '—',
      mobileNumber: session.mobile,
      email: session.email != null && session.email!.isNotEmpty
          ? session.email!
          : '—',
      village: vilName,
      panchayat: gpName,
      block: blkName,
      division: distName != '—' ? '$distName Division' : '—',
      district: distName,
      state: stateName,
      dateOfJoining: '—',
      qualification: '—',
      profession: session.sector.isNotEmpty ? session.sector : '—',
      supervisor: session.supervisorName != null &&
              session.supervisorName!.isNotEmpty
          ? (session.supervisorId != null
              ? '${session.supervisorName} (ID: ${session.supervisorId})'
              : session.supervisorName!)
          : 'Assigned on approval',
      healthFacilityLinked: 'CHC',
      veterinaryInstitutionLinked: '—',
      forestInstitutionLinked: '—',
      preferredLanguage: 'English',
      status: session.status.isNotEmpty ? session.status : 'Active',
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
    'volunteer_name': fullName,
    'volunteer_id': numericVolunteerId ?? volunteerId,
    'volunteer_code': volunteerId,
    'designation': designation,
    'gender': gender,
    'dob': dob,
    'date_of_birth': rawDateOfBirth ?? dob,
    'mobile_number': mobileNumber,
    'mobile_no': mobileNumber,
    'email': email,
    'village': village,
    'village_name': village,
    'panchayat': panchayat,
    'gram_panchayat_name': panchayat,
    'block': block,
    'block_name': block,
    'division': division,
    'district': district,
    'district_name': district,
    'state': state,
    'state_name': state,
    'date_of_joining': dateOfJoining,
    'qualification': qualification,
    'education_name': qualification,
    'profession': profession,
    'profession_name': profession,
    'supervisor': supervisor,
    'health_facility_linked': healthFacilityLinked,
    'veterinary_institution_linked': veterinaryInstitutionLinked,
    'forest_institution_linked': forestInstitutionLinked,
    'institution_field_label': institutionFieldLabel,
    'preferred_language': preferredLanguage,
    'status': status,
    'last_login': lastLogin,
    'last_login_at': lastLogin,
    'registration_gps': registrationGps,
    'photo_url': photoUrl,
    'photo_path': photoUrl,
    'state_lgd_code': stateLgdCode,
    'district_lgd_code': districtLgdCode,
    'block_lgd_code': blockLgdCode,
    'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    'village_lgd_code': villageLgdCode,
    'supervisor_id': supervisorId,
    'numeric_volunteer_id': numericVolunteerId,
    'department_id': departmentId,
    'department_name': departmentName,
    'cohv_type': cohvType,
    'institution_type_id': institutionTypeId,
    'institution_type_name': institutionTypeName,
    'institution_name': institutionName,
    'other_institution_name': otherInstitutionName,
    'education_id': educationId,
    'profession_id': professionId,
    'supervisor_mobile': supervisorMobile,
    'supervisor_email': supervisorEmail,
    'status_remarks': statusRemarks,
    'approved_by': approvedBy,
    'approved_by_name': approvedByName,
    'approved_at': approvedAt,
    'reg_latitude': regLatitude,
    'reg_longitude': regLongitude,
    'reg_gps_accuracy_m': regGpsAccuracyM,
    'reg_gps_unavailable_reason': regGpsUnavailableReason,
    'device_id': deviceId,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'total_visits': totalVisits,
    'alerts_generated': alertsGenerated,
    'referrals': referrals,
    'awareness_activities': awarenessActivities,
  };

  /// Merges user-edited fields into fetched profile so edits aren't replaced by '—'
  DetailedVolunteerProfile merge(DetailedVolunteerProfile? other) {
    if (other == null) return this;
    return copyWith(
      gender: other.gender != '—' && other.gender.isNotEmpty
          ? other.gender
          : gender,
      dob: other.dob != '—' && other.dob.isNotEmpty ? other.dob : dob,
      rawDateOfBirth: other.rawDateOfBirth ?? rawDateOfBirth,
      qualification: other.qualification != '—' &&
              other.qualification.isNotEmpty
          ? other.qualification
          : qualification,
      profession: other.profession != '—' && other.profession.isNotEmpty
          ? other.profession
          : profession,
      designation: other.designation != '—' &&
              other.designation.isNotEmpty &&
              other.designation != 'COHV'
          ? other.designation
          : (other.profession != '—' && other.profession.isNotEmpty
              ? other.profession
              : (designation != '—' && designation.isNotEmpty && designation != 'COHV'
                  ? designation
                  : (profession != '—' && profession.isNotEmpty ? profession : designation))),
      dateOfJoining: other.dateOfJoining != '—' &&
              other.dateOfJoining.isNotEmpty
          ? other.dateOfJoining
          : dateOfJoining,
      preferredLanguage: other.preferredLanguage != '—' &&
              other.preferredLanguage.isNotEmpty
          ? other.preferredLanguage
          : preferredLanguage,
      registrationGps: other.registrationGps != '—' &&
              other.registrationGps.isNotEmpty
          ? other.registrationGps
          : registrationGps,
      photoUrl: (photoUrl != null &&
              photoUrl!.trim().isNotEmpty &&
              photoUrl != '—')
          ? photoUrl
          : ((other.photoUrl != null &&
                  other.photoUrl!.trim().isNotEmpty &&
                  other.photoUrl != '—')
              ? other.photoUrl
              : photoUrl),
      mobileNumber: other.mobileNumber != '—' && other.mobileNumber.isNotEmpty
          ? other.mobileNumber
          : mobileNumber,
      email: other.email != '—' && other.email.isNotEmpty ? other.email : email,
      institutionFieldLabel: other.institutionFieldLabel ?? institutionFieldLabel,
      institutionTypeId: other.institutionTypeId ?? institutionTypeId,
      institutionTypeName: other.institutionTypeName ?? institutionTypeName,
      institutionName: other.institutionName ?? institutionName,
      otherInstitutionName: other.otherInstitutionName ?? otherInstitutionName,
      professionId: other.professionId ?? professionId,
      educationId: other.educationId ?? educationId,
      departmentId: other.departmentId ?? departmentId,
      departmentName: other.departmentName ?? departmentName,
      cohvType: other.cohvType ?? cohvType,
      stateLgdCode: other.stateLgdCode ?? stateLgdCode,
      districtLgdCode: other.districtLgdCode ?? districtLgdCode,
      blockLgdCode: other.blockLgdCode ?? blockLgdCode,
      gramPanchayatLgdCode: other.gramPanchayatLgdCode ?? gramPanchayatLgdCode,
      villageLgdCode: other.villageLgdCode ?? villageLgdCode,
      numericVolunteerId: other.numericVolunteerId ?? numericVolunteerId,
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
