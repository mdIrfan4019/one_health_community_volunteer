// Create file: lib/features/referrals/domain/referral_models.dart

class ReferralItem {
  final String id; // e.g. REF-26-0005
  final String facilityName; // e.g. CHC
  final String stream; // Human, Veterinary, Environmental
  final String referralType;
  final String village;
  final DateTime eventDate;
  final DateTime referralDate;
  final String? reason;
  final bool isFollowedUp;
  final String status; // 'synced' or 'pending'
  final List<String> mediaFiles;
  final String? mediaCaption;
  final double latitude;
  final double longitude;
  final int accuracy;
  final String volunteerId;
  final String deviceId;

  ReferralItem({
    required this.id,
    required this.facilityName,
    required this.stream,
    required this.referralType,
    required this.village,
    required this.eventDate,
    required this.referralDate,
    this.reason,
    required this.isFollowedUp,
    this.status = 'synced',
    this.mediaFiles = const [],
    this.mediaCaption,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.volunteerId,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'facility_name': facilityName,
    'stream': stream,
    'referral_type': referralType,
    'village': village,
    'event_date': eventDate.toIso8601String(),
    'referral_date': referralDate.toIso8601String(),
    'reason': reason,
    'is_followed_up': isFollowedUp,
    'status': status,
    'media_files': mediaFiles,
    'media_caption': mediaCaption,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'volunteer_id': volunteerId,
    'device_id': deviceId,
  };

  factory ReferralItem.fromJson(Map<String, dynamic> json) => ReferralItem(
    id: json['id'] ?? 'REF-26-0001',
    facilityName: json['facility_name'] ?? 'CHC',
    stream: json['stream'] ?? 'Human',
    referralType: json['referral_type'] ?? 'CHC',
    village: json['village'] ?? 'Amrabad',
    eventDate: DateTime.parse(json['event_date']),
    referralDate: DateTime.parse(json['referral_date']),
    reason: json['reason'],
    isFollowedUp: json['is_followed_up'] ?? false,
    status: json['status'] ?? 'synced',
    mediaFiles: List<String>.from(json['media_files'] ?? []),
    mediaCaption: json['media_caption'],
    latitude: (json['latitude'] as num?)?.toDouble() ?? 28.60928,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 77.367449,
    accuracy: (json['accuracy'] as num?)?.toInt() ?? 133,
    volunteerId: json['volunteer_id'] ?? 'COHV-26-0001',
    deviceId: json['device_id'] ?? 'DEV-C0YBZ9WK',
  );
}
