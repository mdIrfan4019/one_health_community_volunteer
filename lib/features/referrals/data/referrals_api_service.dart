import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/referral_models.dart';

class ReferralsApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointReferrals = ApiConstants.endpointReferrals;
  static const String endpointReferralsAll = ApiConstants.endpointReferralsAll;
  static const String endpointReferralFacilities =
      ApiConstants.endpointReferralFacilities;

  final http.Client _client;
  final SyncRepository _syncRepository;
  final AuthApiService _authApiService;

  ReferralsApiService({
    http.Client? client,
    SyncRepository? syncRepository,
    AuthApiService? authApiService,
  })  : _client = client ?? http.Client(),
        _syncRepository = syncRepository ?? SyncRepository(),
        _authApiService = authApiService ?? AuthApiService();

  /// Fetch logged-in volunteer's profile via /api/auth/me (or cached session)
  Future<UserSession> fetchUserProfile() async {
    // 1. Try local cached session first for instant load
    final cached = await SessionManager.getUserSession();

    try {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        final liveSession = await _authApiService.getCurrentUser(token: token);
        return liveSession;
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Could not refresh profile via /api/auth/me: $e');
    }

    if (cached != null) {
      return cached;
    }

    // Fallback default session if not logged in
    return UserSession(
      volunteerId: 'COHV-26-0001',
      fullName: 'Volunteer',
      mobile: '',
      sector: 'Public Health Department',
      status: 'ACTIVE',
      token: '',
      gramPanchayatLgdCode: 9000001,
      gramPanchayatName: 'Mannanur',
      villageLgdCode: 90000001,
      villageName: 'Mannanur',
    );
  }

  /// Fetch referral facilities for a given stream:
  /// GET /api/referrals/facilities?stream=HUMAN or ANIMAL
  Future<List<ReferralFacility>> fetchFacilities(String stream) async {
    final normalizedStream =
        stream.toUpperCase().contains('ANIMAL') ? 'ANIMAL' : 'HUMAN';
    final url = Uri.parse(
      ApiConstants.endpointReferralFacilitiesForStream(normalizedStream),
    );

    debugPrint('[REFERRALS_API] GET $url');

    try {
      final token = await SessionManager.getToken();
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[REFERRALS_API] /api/referrals/facilities status: ${response.statusCode}, '
        'body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => ReferralFacility.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Error fetching facilities: $e');
    }

    // Fallback seed facilities if offline or error
    return _getFallbackFacilities(normalizedStream);
  }

  /// Fetch list of villages for volunteer's gram panchayat:
  /// GET /api/locations/villages?gram_panchayat_lgd_code=
  Future<List<VillageModel>> fetchVillagesForPanchayat(
    int gramPanchayatLgdCode,
  ) async {
    try {
      final villages = await DemographicRepository.fetchVillagesFromApi(
        gramPanchayatLgdCode.toString(),
      );
      if (villages.isNotEmpty) {
        return villages;
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Error fetching villages from API: $e');
    }

    // Fallback villages
    return [
      VillageModel(
        villageName: 'Mannanur',
        villageLgdCode: '90000001',
        gramPanchayatLgdCode: gramPanchayatLgdCode.toString(),
      ),
      VillageModel(
        villageName: 'Amrabad',
        villageLgdCode: '90000004',
        gramPanchayatLgdCode: gramPanchayatLgdCode.toString(),
      ),
      VillageModel(
        villageName: 'Macharam',
        villageLgdCode: '90000005',
        gramPanchayatLgdCode: gramPanchayatLgdCode.toString(),
      ),
    ];
  }

  /// Submit a referral to backend API: POST /api/referrals (multipart/form-data)
  Future<ReferralCreateResult> submitReferral(
    ReferralCreateRequest request, {
    bool allowOfflineFallback = true,
  }) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointReferrals);

    debugPrint(
      '[REFERRALS_API] POST $url (multipart/form-data) with Bearer token: '
      '${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final multipart = http.MultipartRequest('POST', url);

      // Authorization headers
      if (token != null && token.isNotEmpty) {
        multipart.headers['Authorization'] = 'Bearer $token';
      }
      multipart.headers['Accept'] = 'application/json';

      // 1. Required numeric and string form fields matching Swagger schema
      multipart.fields['volunteer_id'] = request.volunteerId.toString();

      if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
        multipart.fields['client_ref'] = request.clientRef!.trim();
      }

      if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
        multipart.fields['device_id'] = request.deviceId!.trim();
      }

      final normalizedStream = request.referralStream.toUpperCase().contains('ANIMAL')
          ? 'ANIMAL'
          : 'HUMAN';
      multipart.fields['referral_stream'] = normalizedStream;
      multipart.fields['referral_facility_id'] =
          request.referralFacilityId.toString();

      if (request.eventReportId != null) {
        multipart.fields['event_report_id'] = request.eventReportId.toString();
      }

      multipart.fields['village_lgd_code'] = request.villageLgdCode.toString();

      // Dates (YYYY-MM-DD)
      final eventDateFormatted =
          '${request.eventDate.year.toString().padLeft(4, '0')}-${request.eventDate.month.toString().padLeft(2, '0')}-${request.eventDate.day.toString().padLeft(2, '0')}';
      multipart.fields['event_date'] = eventDateFormatted;

      final referralDateFormatted =
          '${request.referralDate.year.toString().padLeft(4, '0')}-${request.referralDate.month.toString().padLeft(2, '0')}-${request.referralDate.day.toString().padLeft(2, '0')}';
      multipart.fields['referral_date'] = referralDateFormatted;

      // Optional text fields
      if (request.reason != null && request.reason!.trim().isNotEmpty) {
        multipart.fields['reason'] = request.reason!.trim();
      }

      // Geolocation Coordinates
      if (request.latitude != null && request.longitude != null) {
        multipart.fields['latitude'] = request.latitude!.toString();
        multipart.fields['longitude'] = request.longitude!.toString();
        if (request.gpsAccuracyM != null) {
          multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
        }
      } else if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.trim().isNotEmpty) {
        multipart.fields['gps_unavailable_reason'] =
            request.gpsUnavailableReason!.trim();
      }

      // Timestamp with timezone
      if (request.capturedAt != null) {
        multipart.fields['captured_at'] =
            request.capturedAt!.toUtc().toIso8601String();
      }

      // Flag
      multipart.fields['is_followed_up'] =
          request.isFollowedUp ? 'true' : 'false';

      // 2. Attach Photos
      for (final filePath in request.photos) {
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'photos',
            file.path,
          );
          multipart.files.add(multipartFile);
        }
      }

      // 3. Attach Videos
      for (final filePath in request.videos) {
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'videos',
            file.path,
          );
          multipart.files.add(multipartFile);
        }
      }

      // 4. Attach Documents
      for (final filePath in request.documents) {
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'documents',
            file.path,
          );
          multipart.files.add(multipartFile);
        }
      }

      // 4. Send request
      final streamedResponse = await _client
          .send(multipart)
          .timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '[REFERRALS_API] POST /api/referrals response status: ${response.statusCode}, '
        'body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ReferralCreateResult.fromJson(decoded);
      }

      // Parse error
      String errorMsg = 'Server returned error status ${response.statusCode}';
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (errJson is Map) {
          if (errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is String) {
              errorMsg = detail;
            } else if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              final fieldLoc = first['loc'] is List
                  ? (first['loc'] as List).last
                  : 'Validation';
              errorMsg = '$fieldLoc: ${first['msg']}';
            } else if (detail is Map && detail['message'] != null) {
              errorMsg = detail['message'].toString();
            }
          } else if (errJson['message'] != null) {
            errorMsg = errJson['message'].toString();
          }
        }
      } catch (_) {}

      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[REFERRALS_API] Error submitting referral: $e');

      // Offline fallback
      final isOffline = e is SocketException ||
          e is TimeoutException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException');

      if (allowOfflineFallback && isOffline) {
        final seq = DateTime.now().millisecondsSinceEpoch % 1000;
        final referralCode =
            'OFFLINE-REF-26-${seq.toString().padLeft(4, '0')}';

        await _syncRepository.enqueueRecord(
          entityType: 'REFERRAL',
          payload: {
            'referral_code': referralCode,
            ...request.toJson(),
          },
        );

        return ReferralCreateResult(
          referralId: seq,
          referralCode: referralCode,
          volunteerId: request.volunteerId,
          referralStream: request.referralStream,
          referralFacilityId: request.referralFacilityId,
          villageLgdCode: request.villageLgdCode,
          eventDate: request.eventDate,
          referralDate: request.referralDate,
          isFollowedUp: request.isFollowedUp,
          verificationStatus: 'PENDING_SYNC',
          createdAt: DateTime.now(),
          status: 'queued_offline',
        );
      }

      rethrow;
    }
  }

  /// Create and submit a new referral (Adapter for ReferralItem compatibility)
  Future<ReferralItem> createReferral(ReferralItem item) async {
    final volunteerId = int.tryParse(item.volunteerId) ?? 48;
    final req = ReferralCreateRequest(
      volunteerId: volunteerId,
      referralStream: item.stream,
      referralFacilityId: 1,
      villageLgdCode: 90000004,
      eventDate: item.eventDate,
      referralDate: item.referralDate,
      reason: item.reason,
      isFollowedUp: item.isFollowedUp,
      latitude: item.latitude,
      longitude: item.longitude,
      gpsAccuracyM: item.accuracy,
      deviceId: item.deviceId,
      photos: item.mediaFiles,
    );
    final res = await submitReferral(req);
    return ReferralItem(
      id: res.referralCode,
      facilityName: item.facilityName,
      stream: res.referralStream,
      referralType: item.referralType,
      village: item.village,
      eventDate: res.eventDate,
      referralDate: res.referralDate,
      reason: item.reason,
      isFollowedUp: res.isFollowedUp,
      status: res.status,
      mediaFiles: item.mediaFiles,
      mediaCaption: item.mediaCaption,
      latitude: item.latitude,
      longitude: item.longitude,
      accuracy: item.accuracy,
      volunteerId: item.volunteerId,
      deviceId: item.deviceId,
    );
  }

  /// Fetch list of referrals for the volunteer:
  /// Tries GET /api/referrals/all (or GET /api/referrals?page=1&page_size=50),
  /// and merges with locally queued offline/submitted referrals.
  Future<List<ReferralItem>> getReferrals([String? volunteerId]) async {
    String? token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      final session = await SessionManager.getUserSession();
      token = session?.token;
    }

    List<ReferralItem> remoteReferrals = [];

    if (token != null && token.isNotEmpty) {
      try {
        final allUrl = Uri.parse(endpointReferralsAll);
        debugPrint('[REFERRALS_API] GET $allUrl');
        final response = await _client
            .get(allUrl, headers: ApiConstants.defaultHeaders(token: token))
            .timeout(const Duration(seconds: 15));

        debugPrint(
          '[REFERRALS_API] GET /api/referrals/all status: ${response.statusCode}, '
          'body length: ${response.body.length}',
        );

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map && decoded['data'] is List) {
            final list = decoded['data'] as List;
            remoteReferrals = list
                .whereType<Map>()
                .map(
                  (item) => ReferralItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList();
          }
        } else if (response.statusCode == 404 || response.statusCode == 405) {
          // Fallback 1: Try singular /api/referral/all
          final singularUrl = Uri.parse(ApiConstants.endpointReferralAll);
          final singResponse = await _client
              .get(singularUrl, headers: ApiConstants.defaultHeaders(token: token))
              .timeout(const Duration(seconds: 15));

          if (singResponse.statusCode == 200) {
            final dynamic decoded = jsonDecode(utf8.decode(singResponse.bodyBytes));
            if (decoded is Map && decoded['data'] is List) {
              final list = decoded['data'] as List;
              remoteReferrals = list
                  .whereType<Map>()
                  .map(
                    (item) => ReferralItem.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList();
            }
          } else {
            // Fallback 2: Try paginated endpoint
            final listUrl = Uri.parse('$endpointReferrals?page=1&page_size=50');
            final pageResponse = await _client
                .get(listUrl, headers: ApiConstants.defaultHeaders(token: token))
                .timeout(const Duration(seconds: 15));

            if (pageResponse.statusCode == 200) {
              final dynamic decoded = jsonDecode(utf8.decode(pageResponse.bodyBytes));
              if (decoded is Map &&
                  decoded['data'] is Map &&
                  decoded['data']['items'] is List) {
                final list = decoded['data']['items'] as List;
                remoteReferrals = list
                    .whereType<Map>()
                    .map(
                      (item) => ReferralItem.fromJson(
                        Map<String, dynamic>.from(item),
                      ),
                    )
                    .toList();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[REFERRALS_API] Error fetching remote referrals: $e');
      }
    }

    // Persist remote referrals if fetched successfully
    if (remoteReferrals.isNotEmpty) {
      await SessionManager.saveSubmittedReferralsList(remoteReferrals);
    }

    // Merge with any locally stored/submitted referrals
    try {
      final localStored = await SessionManager.getSubmittedReferrals();
      if (localStored.isNotEmpty) {
        final existingIds = remoteReferrals.map((r) => r.id).toSet();
        for (final local in localStored) {
          if (!existingIds.contains(local.id)) {
            remoteReferrals.insert(0, local);
          }
        }
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Error merging local referrals: $e');
    }

    if (remoteReferrals.isNotEmpty) {
      return remoteReferrals;
    }

    return _getFallbackReferrals(volunteerId ?? 'COHV-26-0001');
  }

  List<ReferralItem> _getFallbackReferrals(String volunteerId) {
    return [
      ReferralItem(
        id: 'REF-26-0003',
        facilityName: 'Sub-Centre / HWC',
        stream: 'HUMAN',
        referralType: 'Sub-Centre / HWC',
        village: 'Amrabad',
        eventDate: DateTime(2026, 10, 24),
        referralDate: DateTime(2026, 10, 24),
        reason: 'Severe persistent fever cluster',
        isFollowedUp: true,
        status: 'SUBMITTED',
        latitude: 16.3752,
        longitude: 78.8354,
        accuracy: 16,
        volunteerId: volunteerId,
        deviceId: 'DEV-C0YBZ9WK',
      ),
    ];
  }

  List<ReferralFacility> _getFallbackFacilities(String stream) {
    if (stream == 'ANIMAL') {
      return const [
        ReferralFacility(
          facilityId: 9,
          stream: 'ANIMAL',
          facilityName: 'Veterinary Dispensary',
        ),
        ReferralFacility(
          facilityId: 10,
          stream: 'ANIMAL',
          facilityName: 'Veterinary Hospital',
        ),
        ReferralFacility(
          facilityId: 11,
          stream: 'ANIMAL',
          facilityName: 'Veterinary Polyclinic',
        ),
        ReferralFacility(
          facilityId: 12,
          stream: 'ANIMAL',
          facilityName: 'Other',
          isOther: true,
        ),
      ];
    }

    return const [
      ReferralFacility(
        facilityId: 1,
        stream: 'HUMAN',
        facilityName: 'Sub-Centre / HWC',
      ),
      ReferralFacility(
        facilityId: 2,
        stream: 'HUMAN',
        facilityName: 'PHC',
      ),
      ReferralFacility(
        facilityId: 3,
        stream: 'HUMAN',
        facilityName: 'CHC',
      ),
      ReferralFacility(
        facilityId: 4,
        stream: 'HUMAN',
        facilityName: 'District Hospital',
      ),
      ReferralFacility(
        facilityId: 5,
        stream: 'HUMAN',
        facilityName: 'Medical College / Tertiary Facility',
      ),
      ReferralFacility(
        facilityId: 6,
        stream: 'HUMAN',
        facilityName: 'Mobile Health Unit',
      ),
      ReferralFacility(
        facilityId: 7,
        stream: 'HUMAN',
        facilityName: 'Emergency Referral',
      ),
      ReferralFacility(
        facilityId: 8,
        stream: 'HUMAN',
        facilityName: 'Other',
        isOther: true,
      ),
    ];
  }

  /// Fetch a single referral record by referral ID:
  /// GET /api/referrals/{referral_id}
  Future<ReferralItem?> fetchReferralDetail(int referralId) async {
    String? token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      final session = await SessionManager.getUserSession();
      token = session?.token;
    }

    final url = Uri.parse(ApiConstants.endpointReferralDetail(referralId));
    debugPrint('[REFERRALS_API] GET $url');

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[REFERRALS_API] GET /api/referrals/$referralId status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final data = decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : Map<String, dynamic>.from(decoded);
          return ReferralItem.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint(
        '[REFERRALS_API] Error fetching referral detail ($referralId): $e',
      );
    }
    return null;
  }
}
