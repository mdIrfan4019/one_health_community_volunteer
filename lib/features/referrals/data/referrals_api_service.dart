import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';

import '../../sync/data/sync_repository.dart';
import '../domain/referral_models.dart';

import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/database/master_data_cache_service.dart';
import 'package:cohv/core/database/offline_outbox_service.dart';

class ReferralsApiService {
  static String baseUrl = ApiConstants.baseUrl;
  static String endpointReferrals = ApiConstants.endpointReferrals;
  static String endpointReferralsAll = ApiConstants.endpointReferralsAll;
  static String endpointReferralFacilities =
      ApiConstants.endpointReferralFacilities;

  final http.Client _client;
  final SyncRepository _syncRepository;
  final AuthApiService _authApiService;

  ReferralsApiService({
    http.Client? client,
    SyncRepository? syncRepository,
    AuthApiService? authApiService,
  }) : _client = client ?? http.Client(),
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
      debugPrint(
        '[REFERRALS_API] Could not refresh profile via /api/auth/me: $e',
      );
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
      sector: '',
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
    final normalizedStream = stream.toUpperCase().contains('ANIMAL')
        ? 'ANIMAL'
        : 'HUMAN';
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
          final facilities = decoded
              .whereType<Map>()
              .map(
                (item) =>
                    ReferralFacility.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();

          if (facilities.isNotEmpty) {
            unawaited(
              MasterDataCacheService.instance.saveReferralFacilities(
                normalizedStream,
                facilities,
              ),
            );
          }
          return facilities;
        }
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Error fetching facilities: $e');
    }

    // SQLite offline cache fallback
    try {
      final offline = await MasterDataCacheService.instance
          .getReferralFacilities(normalizedStream);
      if (offline.isNotEmpty) return offline;
    } catch (_) {}

    // Fallback seed facilities if offline or error
    return _getFallbackFacilities(normalizedStream);
  }

  /// Fetch list of villages for volunteer's gram panchayat:
  /// GET /api/locations/villages?gram_panchayat_lgd_code=
  Future<List<VillageModel>> fetchVillagesForPanchayat(
    int? gramPanchayatLgdCode,
  ) async {
    try {
      if (gramPanchayatLgdCode != null && gramPanchayatLgdCode > 0) {
        final villages = await DemographicRepository.fetchVillagesFromApi(
          gramPanchayatLgdCode.toString(),
        );
        if (villages.isNotEmpty) {
          await MasterDataCacheService.instance.saveVillages(
            gramPanchayatLgdCode,
            villages,
          );
          return villages;
        }
      }
    } catch (e) {
      debugPrint('[REFERRALS_API] Error fetching villages from API: $e');
    }

    return await MasterDataCacheService.instance.getVillagesForPanchayat(
      gramPanchayatLgdCode,
    );
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

      final normalizedStream =
          request.referralStream.toUpperCase().contains('ANIMAL')
          ? 'ANIMAL'
          : 'HUMAN';
      multipart.fields['referral_stream'] = normalizedStream;
      multipart.fields['referral_facility_id'] = request.referralFacilityId
          .toString();

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
        multipart.fields['latitude'] = GeoLocationData.formatCoordinateString(
          request.latitude,
        )!;
        multipart.fields['longitude'] = GeoLocationData.formatCoordinateString(
          request.longitude,
        )!;
        if (request.gpsAccuracyM != null) {
          multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
        }
      } else if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.trim().isNotEmpty) {
        multipart.fields['gps_unavailable_reason'] = request
            .gpsUnavailableReason!
            .trim();
      }

      // Timestamp with timezone
      if (request.capturedAt != null) {
        multipart.fields['captured_at'] = request.capturedAt!
            .toUtc()
            .toIso8601String();
      }

      // Flag
      multipart.fields['is_followed_up'] = request.isFollowedUp
          ? 'true'
          : 'false';

      // Description / caption
      if (request.mediaCaption != null &&
          request.mediaCaption!.trim().isNotEmpty) {
        final cap = request.mediaCaption!.trim();
        multipart.fields['media_caption'] = cap;
        multipart.fields['description'] = cap;
        multipart.fields['caption'] = cap;
      }

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

      ApiConstants.logRequest(
        module: 'Referrals',
        method: 'POST',
        url: url,
        body: multipart.fields,
      );

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
      final isOffline = OfflineOutboxService.isNetworkException(e);

      if (allowOfflineFallback && isOffline) {
        final seq = DateTime.now().millisecondsSinceEpoch % 1000;
        final referralCode = 'OFFLINE-REF-26-${seq.toString().padLeft(4, '0')}';

        await OfflineOutboxService.instance.enqueueSubmission(
          entityType: 'REFERRAL',
          clientRef: referralCode,
          payload: {'referral_code': referralCode, ...request.toJson()},
          photos: request.photos,
          documents: request.documents,
          videos: request.videos,
        );

        await _syncRepository.enqueueRecord(
          entityType: 'REFERRAL',
          payload: {'referral_code': referralCode, ...request.toJson()},
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

  /// Update an existing referral: PUT /api/referrals/{referral_id}
  Future<ReferralCreateResult> _saveReferralUpdateOffline(
    int referralId,
    ReferralCreateRequest request,
  ) async {
    final clientRef = request.clientRef?.isNotEmpty == true
        ? request.clientRef!
        : 'REF-$referralId';

    final payload = {
      ...request.toJson(),
      'is_update': true,
      'target_referral_id': referralId,
      'referral_id': referralId,
      'referral_code': clientRef,
    };

    await OfflineOutboxService.instance.enqueueSubmission(
      entityType: 'REFERRAL',
      clientRef: clientRef,
      payload: payload,
      photos: request.photos,
      documents: request.documents,
      videos: request.videos,
    );

    return ReferralCreateResult(
      referralId: referralId,
      referralCode: clientRef,
      volunteerId: request.volunteerId,
      referralStream: request.referralStream,
      referralFacilityId: request.referralFacilityId,
      villageLgdCode: request.villageLgdCode,
      eventDate: request.eventDate,
      referralDate: request.referralDate,
      isFollowedUp: request.isFollowedUp,
      verificationStatus: 'Edited',
      createdAt: DateTime.now(),
      status: 'queued_offline',
    );
  }

  Future<ReferralCreateResult> updateReferral(
    int referralId,
    ReferralCreateRequest request, {
    bool allowOfflineFallback = true,
  }) async {
    if (allowOfflineFallback && !_syncRepository.getSummary().isOnline) {
      debugPrint('[REFERRALS_API] Offline mode â€” queuing referral update');
      return await _saveReferralUpdateOffline(referralId, request);
    }

    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointReferralDetail(referralId));

    debugPrint('[REFERRALS_API] PUT $uri (referralId: $referralId)');

    try {
      final multipart = http.MultipartRequest('PUT', uri);

      if (token != null && token.isNotEmpty) {
        multipart.headers['Authorization'] = 'Bearer $token';
      }
      multipart.headers['Accept'] = 'application/json';

      // 1. Add Text Fields
      multipart.fields['volunteer_id'] = request.volunteerId.toString();
      if (request.clientRef != null && request.clientRef!.isNotEmpty) {
        multipart.fields['client_ref'] = request.clientRef!;
      }
      if (request.deviceId != null && request.deviceId!.isNotEmpty) {
        multipart.fields['device_id'] = request.deviceId!;
      }
      multipart.fields['referral_stream'] = request.referralStream;
      multipart.fields['referral_facility_id'] = request.referralFacilityId
          .toString();
      if (request.eventReportId != null) {
        multipart.fields['event_report_id'] = request.eventReportId.toString();
      }
      multipart.fields['village_lgd_code'] = request.villageLgdCode.toString();
      multipart.fields['event_date'] = request.eventDate
          .toIso8601String()
          .split('T')
          .first;
      multipart.fields['referral_date'] = request.referralDate
          .toIso8601String()
          .split('T')
          .first;
      if (request.reason != null && request.reason!.trim().isNotEmpty) {
        multipart.fields['reason'] = request.reason!.trim();
      }

      // GPS
      if (request.latitude != null) {
        multipart.fields['latitude'] = request.latitude.toString();
      }
      if (request.longitude != null) {
        multipart.fields['longitude'] = request.longitude.toString();
      }
      if (request.gpsAccuracyM != null) {
        multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
      }
      if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.isNotEmpty) {
        multipart.fields['gps_unavailable_reason'] =
            request.gpsUnavailableReason!;
      }
      if (request.capturedAt != null) {
        multipart.fields['captured_at'] = request.capturedAt!
            .toUtc()
            .toIso8601String();
      }

      // Flag
      multipart.fields['is_followed_up'] = request.isFollowedUp
          ? 'true'
          : 'false';

      // Description / caption
      if (request.mediaCaption != null &&
          request.mediaCaption!.trim().isNotEmpty) {
        final cap = request.mediaCaption!.trim();
        multipart.fields['media_caption'] = cap;
        multipart.fields['description'] = cap;
        multipart.fields['caption'] = cap;
      }

      // Photos
      for (final filePath in request.photos) {
        if (filePath.startsWith('http')) continue;
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'photos',
            file.path,
          );
          multipart.files.add(multipartFile);
        }
      }

      // Videos
      for (final filePath in request.videos) {
        if (filePath.startsWith('http')) continue;
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'videos',
            file.path,
          );
          multipart.files.add(multipartFile);
        }
      }

      // Documents
      for (final filePath in request.documents) {
        if (filePath.startsWith('http')) continue;
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'documents',
            file.path,
          );
          multipart.files.add(multipartFile);
        }
      }

      // Preserve existing attachments
      final existingPhotos = request.photos
          .where((p) => p.startsWith('http') || !File(p).existsSync())
          .toList();
      final existingVideos = request.videos
          .where((v) => v.startsWith('http') || !File(v).existsSync())
          .toList();
      final existingDocs = request.documents
          .where((d) => d.startsWith('http') || !File(d).existsSync())
          .toList();
      if (existingPhotos.isNotEmpty) {
        multipart.fields['existing_photos'] = jsonEncode(existingPhotos);
      }
      if (existingVideos.isNotEmpty) {
        multipart.fields['existing_videos'] = jsonEncode(existingVideos);
      }
      if (existingDocs.isNotEmpty) {
        multipart.fields['existing_documents'] = jsonEncode(existingDocs);
      }

      if (request.removedAttachmentIds.isNotEmpty) {
        multipart.fields['removed_attachment_ids'] = jsonEncode(
          request.removedAttachmentIds,
        );
      }

      ApiConstants.logRequest(
        module: 'Referrals',
        method: 'PUT',
        url: uri,
        body: multipart.fields,
      );

      final streamedResponse = await _client
          .send(multipart)
          .timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '[REFERRALS_API] PUT /api/referrals/$referralId response status: ${response.statusCode}, '
        'body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ReferralCreateResult.fromJson(decoded);
      }

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
      debugPrint('[REFERRALS_API] Error updating referral $referralId: $e');
      if (allowOfflineFallback && OfflineOutboxService.isNetworkException(e)) {
        return await _saveReferralUpdateOffline(referralId, request);
      }
      rethrow;
    }
  }

  /// Create and submit a new referral (Adapter for ReferralItem compatibility)
  Future<ReferralItem> createReferral(ReferralItem item) async {
    final volunteerId =
        item.numericVolunteerId ??
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

  /// Instant offline loader: retrieves cached referrals from SQLite and merges
  /// pending outbox items without performing any network call.
  Future<List<ReferralItem>> getCachedReferrals([
    String? volunteerId,
    int? numericVolunteerId,
  ]) async {
    try {
      final session = await SessionManager.getUserSession();
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

      List<ReferralItem> localReferrals = [];
      try {
        // 1. Load from SQLite cache
        if (effectiveVolunteerId.isNotEmpty) {
          final cachedRows = await AppDatabase.instance.getCachedRecordsList(
            entityType: 'REFERRAL',
            volunteerId: effectiveVolunteerId,
          );
          if (cachedRows.isNotEmpty) {
            localReferrals = cachedRows
                .map((r) => ReferralItem.fromJson(r))
                .toList();
          }
        }

        // 2. Merge pending outbox records from SQLite
        final pendingRows = await OfflineOutboxService.instance
            .getPendingByEntity('REFERRAL');
        for (final row in pendingRows) {
          final payload =
              jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
          final isUpdate = payload['is_update'] == true;
          final targetId = payload['target_referral_id'] ?? payload['referral_id'];
          final targetIdStr = targetId?.toString();
          final clientRef = row['client_ref']?.toString() ?? '';

          if (isUpdate && (targetIdStr != null || clientRef.isNotEmpty)) {
            final idx = localReferrals.indexWhere((r) =>
                r.id == clientRef ||
                (targetIdStr != null &&
                    (r.referralId?.toString() == targetIdStr ||
                        r.id == targetIdStr ||
                        r.id == 'REF-$targetIdStr' ||
                        r.id == 'REF-26-${targetIdStr.padLeft(4, '0')}')));
            if (idx != -1) {
              final existing = localReferrals[idx];
              final photos = payload['photos'] is List
                  ? (payload['photos'] as List).map((e) => e.toString()).toList()
                  : <String>[];
              final videos = payload['videos'] is List
                  ? (payload['videos'] as List).map((e) => e.toString()).toList()
                  : <String>[];
              final docs = payload['documents'] is List
                  ? (payload['documents'] as List).map((e) => e.toString()).toList()
                  : <String>[];
              final allMedia = [...photos, ...videos, ...docs];

              final removedIds = (payload['removed_attachment_ids'] is List)
                  ? (payload['removed_attachment_ids'] as List)
                        .map((e) => int.tryParse(e.toString()))
                        .whereType<int>()
                        .toSet()
                  : <int>{};
              final updatedAttachments = existing.attachments
                  .where((a) => !removedIds.contains(a.attachmentId))
                  .toList();

              for (final p in photos) {
                if (!updatedAttachments.any((a) => a.storagePath == p || a.fileUrl == p)) {
                  updatedAttachments.add(
                    ReferralAttachmentItem(
                      attachmentId: 0,
                      fileKind: 'IMAGE',
                      fileName: p.split(Platform.pathSeparator).last,
                      storagePath: p,
                      fileUrl: p.startsWith('http') ? p : null,
                    ),
                  );
                }
              }
              for (final v in videos) {
                if (!updatedAttachments.any((a) => a.storagePath == v || a.fileUrl == v)) {
                  updatedAttachments.add(
                    ReferralAttachmentItem(
                      attachmentId: 0,
                      fileKind: 'VIDEO',
                      fileName: v.split(Platform.pathSeparator).last,
                      storagePath: v,
                      fileUrl: v.startsWith('http') ? v : null,
                    ),
                  );
                }
              }
              for (final d in docs) {
                if (!updatedAttachments.any((a) => a.storagePath == d || a.fileUrl == d)) {
                  updatedAttachments.add(
                    ReferralAttachmentItem(
                      attachmentId: 0,
                      fileKind: 'DOCUMENT',
                      fileName: d.split(Platform.pathSeparator).last,
                      storagePath: d,
                      fileUrl: d.startsWith('http') ? d : null,
                    ),
                  );
                }
              }

              localReferrals[idx] = existing.copyWith(
                status: 'pending',
                verificationStatus: 'Edited',
                reason: payload['reason']?.toString() ?? existing.reason,
                stream: payload['referral_stream']?.toString() ?? existing.stream,
                facilityName: payload['referral_facility_name']?.toString() ??
                    payload['facility_name']?.toString() ??
                    existing.facilityName,
                village: payload['village_name']?.toString() ??
                    payload['village']?.toString() ??
                    existing.village,
                mediaCaption: payload['media_caption']?.toString() ??
                    payload['caption']?.toString() ??
                    payload['description']?.toString() ??
                    existing.mediaCaption,
                attachments: updatedAttachments,
                mediaFiles: allMedia.isNotEmpty
                    ? allMedia
                    : updatedAttachments
                          .map((a) => a.storagePath.isNotEmpty ? a.storagePath : (a.fileUrl ?? ''))
                          .toList(),
              );
            }
            continue;
          }

          final code = clientRef.isNotEmpty
              ? clientRef
              : (payload['referral_code']?.toString() ?? 'PENDING');
          if (!localReferrals.any((r) => r.id == code)) {
            final rowStatus =
                row['status']?.toString().toUpperCase() ?? 'PENDING';
            final isFail = rowStatus == 'FAILED';
            localReferrals.insert(
              0,
              ReferralItem.fromJson({
                ...payload,
                'id': code,
                'status': isFail ? 'failed' : 'pending',
                'verification_status': isFail ? 'SYNC_FAILED' : 'PENDING_SYNC',
                'volunteer_id': effectiveVolunteerId,
                'numeric_volunteer_id': effectiveNumericId,
              }),
            );
          }
        }
      } catch (_) {}

      // 3. Merge with SessionManager
      try {
        final stored = await SessionManager.getSubmittedReferrals(
          volunteerId: effectiveVolunteerId,
          numericVolunteerId: effectiveNumericId,
        );
        if (stored.isNotEmpty) {
          for (final local in stored) {
            if (local.id == 'REF-26-0001') continue;
            final idx = localReferrals.indexWhere(
              (r) =>
                  r.id == local.id ||
                  (local.referralId != null &&
                      local.referralId! > 0 &&
                      r.referralId == local.referralId),
            );
            if (idx != -1) {
              final isPending = local.status.toLowerCase() == 'pending' ||
                  local.verificationStatus?.toLowerCase() == 'edited';
              if (isPending) {
                localReferrals[idx] = local;
              }
            } else {
              localReferrals.insert(0, local);
            }
          }
        }
      } catch (_) {}

      return localReferrals;
    } catch (e) {
      debugPrint('[REFERRALS_API] Error reading cached referrals: $e');
      return [];
    }
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
        : (session?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');

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

        final allUri = Uri.parse(
          endpointReferralsAll,
        ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
        debugPrint('[REFERRALS_API] GET $allUri');
        final response = await _client
            .get(allUri, headers: ApiConstants.defaultHeaders(token: token))
            .timeout(const Duration(seconds: 6));

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
                (item) =>
                    ReferralItem.fromJson(Map<String, dynamic>.from(item)),
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
          final listUri = Uri.parse(endpointReferrals)
              .replace(queryParameters: pageParams);
          final pageResponse = await _client
              .get(listUri, headers: ApiConstants.defaultHeaders(token: token))
              .timeout(const Duration(seconds: 6));

          if (pageResponse.statusCode == 200) {
            final dynamic decoded = jsonDecode(
              utf8.decode(pageResponse.bodyBytes),
            );
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
                  (item) =>
                      ReferralItem.fromJson(Map<String, dynamic>.from(item)),
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

    // Cache remote referrals in SQLite without overwriting local pending items
    if (remoteReferrals.isNotEmpty && effectiveVolunteerId.isNotEmpty) {
      AppDatabase.instance.cacheRecordsList(
        entityType: 'REFERRAL',
        volunteerId: effectiveVolunteerId,
        records: remoteReferrals.map((e) => e.toJson()).toList(),
        idExtractor: (m) => m['id']?.toString() ?? '',
      );
    } else if (remoteReferrals.isEmpty) {
      // Offline fallback: load from SQLite cache
      try {
        final cachedRows = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'REFERRAL',
          volunteerId: effectiveVolunteerId,
        );
        if (cachedRows.isNotEmpty) {
          remoteReferrals = cachedRows
              .map((r) => ReferralItem.fromJson(r))
              .toList();
        }
      } catch (_) {}
    }

    // Merge pending outbox records from SQLite
    try {
      final pendingRows = await OfflineOutboxService.instance
          .getPendingByEntity('REFERRAL');
      final pendingClientRefs = pendingRows
          .map((r) => r['client_ref']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();

      for (final row in pendingRows) {
        final payload =
            jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
        final isUpdate = payload['is_update'] == true;
        final targetId = payload['target_referral_id'] ??
            payload['referral_id'];
        final targetIdStr = targetId?.toString();
        final clientRef = row['client_ref']?.toString() ?? '';

        if (isUpdate && (targetIdStr != null || clientRef.isNotEmpty)) {
          final idx = remoteReferrals.indexWhere(
            (r) =>
                r.id == clientRef ||
                (targetIdStr != null &&
                    (r.referralId?.toString() == targetIdStr ||
                        r.id == targetIdStr ||
                        r.id == 'REF-$targetIdStr' ||
                        r.id == 'REF-26-${targetIdStr.padLeft(4, '0')}')),
          );
          if (idx != -1) {
            final existing = remoteReferrals[idx];
            final photos = payload['photos'] is List
                ? (payload['photos'] as List).map((e) => e.toString()).toList()
                : <String>[];
            final videos = payload['videos'] is List
                ? (payload['videos'] as List).map((e) => e.toString()).toList()
                : <String>[];
            final docs = payload['documents'] is List
                ? (payload['documents'] as List).map((e) => e.toString()).toList()
                : <String>[];
            final allMedia = [...photos, ...videos, ...docs];

            final removedIds = (payload['removed_attachment_ids'] is List)
                ? (payload['removed_attachment_ids'] as List)
                      .map((e) => int.tryParse(e.toString()))
                      .whereType<int>()
                      .toSet()
                : <int>{};
            final updatedAttachments = existing.attachments
                .where((a) => !removedIds.contains(a.attachmentId))
                .toList();

            for (final p in photos) {
              if (!updatedAttachments.any((a) => a.storagePath == p || a.fileUrl == p)) {
                updatedAttachments.add(
                  ReferralAttachmentItem(
                    attachmentId: 0,
                    fileKind: 'IMAGE',
                    fileName: p.split(Platform.pathSeparator).last,
                    storagePath: p,
                    fileUrl: p.startsWith('http') ? p : null,
                  ),
                );
              }
            }
            for (final v in videos) {
              if (!updatedAttachments.any((a) => a.storagePath == v || a.fileUrl == v)) {
                updatedAttachments.add(
                  ReferralAttachmentItem(
                    attachmentId: 0,
                    fileKind: 'VIDEO',
                    fileName: v.split(Platform.pathSeparator).last,
                    storagePath: v,
                    fileUrl: v.startsWith('http') ? v : null,
                  ),
                );
              }
            }
            for (final d in docs) {
              if (!updatedAttachments.any((a) => a.storagePath == d || a.fileUrl == d)) {
                updatedAttachments.add(
                  ReferralAttachmentItem(
                    attachmentId: 0,
                    fileKind: 'DOCUMENT',
                    fileName: d.split(Platform.pathSeparator).last,
                    storagePath: d,
                    fileUrl: d.startsWith('http') ? d : null,
                  ),
                );
              }
            }

            remoteReferrals[idx] = existing.copyWith(
              status: 'pending',
              verificationStatus: 'Edited',
              reason: payload['reason']?.toString() ?? existing.reason,
              stream: payload['referral_stream']?.toString() ?? existing.stream,
              facilityName: payload['referral_facility_name']?.toString() ??
                  payload['facility_name']?.toString() ??
                  existing.facilityName,
              village: payload['village_name']?.toString() ??
                  payload['village']?.toString() ??
                  existing.village,
              mediaCaption: payload['media_caption']?.toString() ??
                  payload['caption']?.toString() ??
                  payload['description']?.toString() ??
                  existing.mediaCaption,
              attachments: updatedAttachments,
              mediaFiles: allMedia.isNotEmpty
                  ? allMedia
                  : updatedAttachments
                        .map((a) => a.storagePath.isNotEmpty ? a.storagePath : (a.fileUrl ?? ''))
                        .toList(),
            );
          }
          continue;
        }

        final code = clientRef.isNotEmpty
            ? clientRef
            : (payload['referral_code']?.toString() ?? 'PENDING');
        if (!remoteReferrals.any((r) => r.id == code)) {
          final rowStatus =
              row['status']?.toString().toUpperCase() ?? 'PENDING';
          final isFail = rowStatus == 'FAILED';
          remoteReferrals.insert(
            0,
            ReferralItem.fromJson({
              ...payload,
              'id': code,
              'status': isFail ? 'failed' : 'pending',
              'verification_status': isFail ? 'SYNC_FAILED' : 'PENDING_SYNC',
              'volunteer_id': effectiveVolunteerId,
              'numeric_volunteer_id': effectiveNumericId,
            }),
          );
        }
      }

      // Merge with locally stored referrals scoped to this volunteer
      final localStored = await SessionManager.getSubmittedReferrals(
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
      if (localStored.isNotEmpty) {
        for (final local in localStored) {
          if (local.id == 'REF-26-0001') continue;

          // If this is an offline created ref that is no longer pending in SQLite outbox, it has already synced
          if (local.id.startsWith('REF-CLI-') || local.id.startsWith('OFFLINE-')) {
            if (!pendingClientRefs.contains(local.id)) {
              await SessionManager.removeSubmittedReferral(local.id);
              continue;
            }
          }

          final idx = remoteReferrals.indexWhere(
            (r) =>
                r.id == local.id ||
                (local.referralId != null &&
                    local.referralId! > 0 &&
                    r.referralId == local.referralId),
          );
          if (idx != -1) {
            final existing = remoteReferrals[idx];
            final isLocallyEdited =
                local.verificationStatus?.toLowerCase() == 'edited' ||
                local.status.toLowerCase() == 'edited';
            final isPendingOutbox = pendingClientRefs.contains(local.id) ||
                (local.referralId != null &&
                    pendingClientRefs.contains(local.referralId.toString()));
            final isPending = isPendingOutbox || local.status == 'pending';

            if (isPending) {
              remoteReferrals[idx] = local.copyWith(
                status: 'pending',
                verificationStatus: 'Edited',
                referralId: existing.referralId ?? local.referralId,
                id: existing.id.isNotEmpty ? existing.id : local.id,
              );
            } else if (isLocallyEdited) {
              remoteReferrals[idx] = existing.copyWith(
                status: 'synced',
                verificationStatus: 'Edited',
                reason: local.reason ?? existing.reason,
                facilityName: local.facilityName.isNotEmpty
                    ? local.facilityName
                    : existing.facilityName,
                stream: local.stream.isNotEmpty
                    ? local.stream
                    : existing.stream,
                village: local.village.isNotEmpty
                    ? local.village
                    : existing.village,
                mediaCaption: local.mediaCaption ?? existing.mediaCaption,
                attachments: local.attachments,
                mediaFiles: local.mediaFiles,
              );
            }
          } else if (VolunteerOwnershipFilter.isOwnedByVolunteer(
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

    // Persist fully merged referrals into volunteer-scoped cache
    if (remoteReferrals.isNotEmpty) {
      await SessionManager.saveSubmittedReferralsList(
        remoteReferrals,
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
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
      ReferralFacility(facilityId: 2, stream: 'HUMAN', facilityName: 'PHC'),
      ReferralFacility(facilityId: 3, stream: 'HUMAN', facilityName: 'CHC'),
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
          .timeout(const Duration(seconds: 6));

      debugPrint(
        '[REFERRALS_API] GET /api/referrals/$referralId status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final data = decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : Map<String, dynamic>.from(decoded);
          var item = ReferralItem.fromJson(data);

          try {
            final session = await SessionManager.getUserSession();
            final effectiveVolunteerId = session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '';
            final effectiveNumericId = session?.numericVolunteerId ??
                await SessionManager.getNumericVolunteerId() ??
                VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);
            final stored = await SessionManager.getSubmittedReferrals(
              volunteerId: effectiveVolunteerId,
              numericVolunteerId: effectiveNumericId,
            );
            ReferralItem? localMatch;
            for (final local in stored) {
              if (local.id == item.id ||
                  (local.referralId != null && local.referralId == item.referralId)) {
                localMatch = local;
                break;
              }
            }
            localMatch ??= await getCachedReferralDetail(item.referralId ?? item.id);
            if (localMatch != null) {
              final isLocallyEdited =
                  localMatch.verificationStatus?.toLowerCase() == 'edited' ||
                  localMatch.status.toLowerCase() == 'edited';
              final pendingRows = await OfflineOutboxService.instance
                  .getPendingByEntity('REFERRAL');
              final isPendingOutbox = pendingRows.any(
                (r) =>
                    r['client_ref']?.toString() == item.id ||
                    r['client_ref']?.toString() == localMatch!.id ||
                    (item.referralId != null &&
                        r['client_ref']?.toString() == item.referralId.toString()),
              );
              final isPending = isPendingOutbox || localMatch.status == 'pending';

              if (isPending) {
                item = localMatch.copyWith(
                  status: 'pending',
                  verificationStatus: 'Edited',
                  referralId: item.referralId ?? localMatch.referralId,
                  id: item.id.isNotEmpty ? item.id : localMatch.id,
                );
              } else if (isLocallyEdited) {
                item = item.copyWith(
                  status: 'synced',
                  verificationStatus: 'Edited',
                  reason: localMatch.reason ?? item.reason,
                  facilityName: localMatch.facilityName.isNotEmpty
                      ? localMatch.facilityName
                      : item.facilityName,
                  stream: localMatch.stream.isNotEmpty
                      ? localMatch.stream
                      : item.stream,
                  village: localMatch.village.isNotEmpty
                      ? localMatch.village
                      : item.village,
                  mediaCaption: localMatch.mediaCaption ?? item.mediaCaption,
                  attachments: localMatch.attachments,
                  mediaFiles: localMatch.mediaFiles,
                );
              }
            }
          } catch (_) {}

          return item;
        }
      }
    } catch (e) {
      debugPrint(
        '[REFERRALS_API] Error fetching live referral detail ($referralId): $e',
      );
    }

    // Offline / Network error fallback
    return getCachedReferralDetail(referralId);
  }

  /// Retrieves a cached ReferralItem by numeric ID or referral code
  Future<ReferralItem?> getCachedReferralDetail(dynamic idOrCode) async {
    final searchKey = idOrCode.toString();
    final numId = (idOrCode is int) ? idOrCode : int.tryParse(searchKey);

    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId = session?.volunteerId ??
          await SessionManager.getVolunteerId() ??
          '';
      final effectiveNumericId = session?.numericVolunteerId ??
          await SessionManager.getNumericVolunteerId() ??
          VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);
      final stored = await SessionManager.getSubmittedReferrals(
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
      for (final item in stored) {
        if (item.id == searchKey || (numId != null && item.referralId == numId)) {
          return item;
        }
      }
    } catch (_) {}

    final list = await getCachedReferrals();
    for (final item in list) {
      if (item.id == searchKey || (numId != null && item.referralId == numId)) {
        return item;
      }
    }
    return null;
  }
}
