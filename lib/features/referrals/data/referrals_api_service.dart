import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/referral_models.dart';
import 'package:cohv/core/models/geo_location_data.dart';

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

    // Dynamic session fallback if not logged in
    final savedVolunteerId = await SessionManager.getVolunteerId() ?? '';
    final savedNumericId = await SessionManager.getNumericVolunteerId();
    return UserSession(
      volunteerId: savedVolunteerId,
      numericVolunteerId: savedNumericId,
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
        multipart.fields['latitude'] =
            GeoLocationData.formatCoordinateString(request.latitude)!;
        multipart.fields['longitude'] =
            GeoLocationData.formatCoordinateString(request.longitude)!;
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
    final volunteerId = item.numericVolunteerId ??
        int.tryParse(item.volunteerId) ??
        VolunteerOwnershipFilter.extractNumericSuffix(item.volunteerId) ??
        (await SessionManager.getNumericVolunteerId()) ??
        0;
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
      numericVolunteerId: volunteerId,
      deviceId: item.deviceId,
    );
  }

  /// Fetch list of referrals for the signed-in volunteer:
  /// Uses GET /api/referrals/all (or GET /api/referrals?page=1&page_size=50) with ?volunteer_id=...,
  /// and applies strict client-side ownership verification against the active volunteer.
  Future<List<ReferralItem>> getReferrals([
    String? volunteerId,
    int? numericVolunteerId,
  ]) async {
    String? token = await SessionManager.getToken();
    final session = await SessionManager.getUserSession();
    if (token == null || token.isEmpty) {
      token = session?.token;
    }

    final effectiveVolunteerId =
        (volunteerId != null && volunteerId.trim().isNotEmpty)
            ? volunteerId.trim()
            : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');

    final effectiveNumericId =
        numericVolunteerId ??
        session?.numericVolunteerId ??
        await SessionManager.getNumericVolunteerId() ??
        VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);

    List<ReferralItem> remoteReferrals = [];

    if (token != null && token.isNotEmpty) {
      try {
        final queryParams = <String, String>{};
        if (effectiveNumericId != null && effectiveNumericId > 0) {
          queryParams['volunteer_id'] = effectiveNumericId.toString();
        }

        final allUri = Uri.parse(endpointReferralsAll).replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        debugPrint('[REFERRALS_API] GET $allUri');
        final response = await _client
            .get(allUri, headers: ApiConstants.defaultHeaders(token: token))
            .timeout(const Duration(seconds: 15));

        debugPrint(
          '[REFERRALS_API] GET /api/referrals/all status: ${response.statusCode}, '
          'body length: ${response.body.length}',
        );

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
          List<dynamic> rawList = [];
          if (decoded is Map && decoded['data'] is List) {
            rawList = decoded['data'] as List;
          } else if (decoded is List) {
            rawList = decoded;
          } else if (decoded is Map &&
              decoded['data'] is Map &&
              decoded['data']['items'] is List) {
            rawList = decoded['data']['items'] as List;
          }
          remoteReferrals = rawList
              .whereType<Map>()
              .map(
                (item) => ReferralItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where(
                (ref) => VolunteerOwnershipFilter.isOwnedByVolunteer(
                  itemOwnerId: ref.volunteerId,
                  itemNumericId: ref.numericVolunteerId,
                  activeVolunteerId: effectiveVolunteerId,
                  activeNumericId: effectiveNumericId,
                ),
              )
              .toList();
        } else if (response.statusCode == 404 || response.statusCode == 405) {
          // Fallback: Try paginated endpoint
          final pageParams = Map<String, String>.from(queryParams);
          pageParams['page'] = '1';
          pageParams['page_size'] = '50';
          final listUri = Uri.parse(endpointReferrals).replace(
            queryParameters: pageParams,
          );
          final pageResponse = await _client
              .get(listUri, headers: ApiConstants.defaultHeaders(token: token))
              .timeout(const Duration(seconds: 15));

          if (pageResponse.statusCode == 200) {
            final dynamic decoded =
                jsonDecode(utf8.decode(pageResponse.bodyBytes));
            List<dynamic> rawList = [];
            if (decoded is Map &&
                decoded['data'] is Map &&
                decoded['data']['items'] is List) {
              rawList = decoded['data']['items'] as List;
            } else if (decoded is Map && decoded['data'] is List) {
              rawList = decoded['data'] as List;
            }
            remoteReferrals = rawList
                .whereType<Map>()
                .map(
                  (item) => ReferralItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (ref) => VolunteerOwnershipFilter.isOwnedByVolunteer(
                    itemOwnerId: ref.volunteerId,
                    itemNumericId: ref.numericVolunteerId,
                    activeVolunteerId: effectiveVolunteerId,
                    activeNumericId: effectiveNumericId,
                  ),
                )
                .toList();
          }
        }
      } catch (e) {
        debugPrint('[REFERRALS_API] Error fetching remote referrals: $e');
      }
    }

    // Persist remote referrals if fetched successfully into volunteer-scoped cache
    if (remoteReferrals.isNotEmpty) {
      await SessionManager.saveSubmittedReferralsList(
        remoteReferrals,
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
    }

    // Merge with any locally stored/submitted referrals scoped to this volunteer
    try {
      final localStored = await SessionManager.getSubmittedReferrals(
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
      if (localStored.isNotEmpty) {
        final existingIds = remoteReferrals.map((r) => r.id).toSet();
        for (final local in localStored) {
          if (!existingIds.contains(local.id) &&
              VolunteerOwnershipFilter.isOwnedByVolunteer(
                itemOwnerId: local.volunteerId,
                itemNumericId: local.numericVolunteerId,
                activeVolunteerId: effectiveVolunteerId,
                activeNumericId: effectiveNumericId,
              )) {
            remoteReferrals.insert(0, local);
          }
        }
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Error merging local referrals: $e');
    }

    // Final fail-closed safety filter on returned list
    return remoteReferrals
        .where(
          (ref) => VolunteerOwnershipFilter.isOwnedByVolunteer(
            itemOwnerId: ref.volunteerId,
            itemNumericId: ref.numericVolunteerId,
            activeVolunteerId: effectiveVolunteerId,
            activeNumericId: effectiveNumericId,
          ),
        )
        .toList();
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
