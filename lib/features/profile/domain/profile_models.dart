// Create file: lib/features/profile/domain/profile_models.dart

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
    this.status = 'Active',
    required this.lastLogin,
    required this.registrationGps,
    this.photoUrl,
  });

  factory DetailedVolunteerProfile.fromJson(Map<String, dynamic> json) {
    return DetailedVolunteerProfile(
      fullName: json['full_name'] ?? 'Test1',
      volunteerId: json['volunteer_id'] ?? 'COHV-26-0001',
      designation: json['designation'] ?? 'COHV',
      gender: json['gender'] ?? 'Male',
      dob: json['dob'] ?? '10 Jul 1997',
      mobileNumber: json['mobile_number'] ?? '9565897524',
      email: json['email'] ?? 'test1@gmail.com',
      village: json['village'] ?? 'Mannanur',
      panchayat: json['panchayat'] ?? 'Mannanur',
      block: json['block'] ?? 'Amrabad',
      division: json['division'] ?? 'Mahabubnagar Division',
      district: json['district'] ?? 'Nagarkurnool',
      state: json['state'] ?? 'Telangana',
      dateOfJoining: json['date_of_joining'] ?? '11 Oct 2026',
      qualification: json['qualification'] ?? 'Higher Secondary',
      profession: json['profession'] ?? 'Farmer',
      supervisor: json['supervisor'] ?? 'Assigned on approval',
      healthFacilityLinked: json['health_facility_linked'] ?? 'CHC',
      veterinaryInstitutionLinked: json['veterinary_institution_linked'] ?? '—',
      forestInstitutionLinked: json['forest_institution_linked'] ?? '—',
      preferredLanguage: json['preferred_language'] ?? 'English',
      status: json['status'] ?? 'Active',
      lastLogin: json['last_login'] ?? '14 Oct 2026, 10:23',
      registrationGps: json['registration_gps'] ?? '28.609306, 77.367452',
      photoUrl: json['photo_url'],
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

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      timestamp: json['timestamp'] ?? '',
      authMethod: json['auth_method'] ?? 'PIN',
      deviceId: json['device_id'] ?? 'DEV-C0YBZ9WK',
    );
  }
}
