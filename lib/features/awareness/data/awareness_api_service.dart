import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/awareness_models.dart';

class AwarenessApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointAwarenessActivities =
      ApiConstants.endpointAwarenessActivities;
  static const String endpointAwarenessActivityTypes =
      ApiConstants.endpointAwarenessActivityTypes;
  static const String endpointAwarenessTopics =
      ApiConstants.endpointAwarenessTopics;
  static const String endpointDepartments = ApiConstants.endpointDepartments;
  static const String endpointAwarenessAll = ApiConstants.endpointAwarenessAll;

  final http.Client _client;
  final SyncRepository _syncRepository;

  AwarenessApiService({
    http.Client? client,
    SyncRepository? syncRepository,
  })  : _client = client ?? AuthenticatedHttpClient.instance,
        _syncRepository = syncRepository ?? SyncRepository();

  /// Fetch logged-in volunteer's user session
  Future<UserSession?> getLoggedInUserSession() async {
    return await SessionManager.getUserSession();
  }

  /// 1. Fetch Activity Types: GET /api/awareness-activities/activity-types
  Future<List<AwarenessActivityTypeModel>> fetchActivityTypes({
    String? filterSector,
  }) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointAwarenessActivityTypes);
    debugPrint('[AWARENESS_API] GET $url');

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AWARENESS_API] /activity-types status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final allTypes = decoded
              .whereType<Map>()
              .map(
                (item) => AwarenessActivityTypeModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();

          if (filterSector != null && filterSector.trim().isNotEmpty) {
            final targetSector = filterSector.trim().toLowerCase();
            return allTypes.where((act) {
              if (act.applicableSectors.isEmpty) return true;
              return act.applicableSectors.any(
                (sec) => sec.toLowerCase() == targetSector,
              );
            }).toList();
          }

          return allTypes;
        }
      }
    } catch (e) {
      debugPrint('[AWARENESS_API] Error fetching activity types: $e');
    }
    return [];
  }

  /// 2. Fetch Topics: GET /api/awareness-activities/topics
  Future<List<AwarenessTopicModel>> fetchTopics() async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointAwarenessTopics);
    debugPrint('[AWARENESS_API] GET $url');

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AWARENESS_API] /topics status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => AwarenessTopicModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AWARENESS_API] Error fetching topics: $e');
    }
    return [];
  }

  /// 3. Fetch Departments: GET /api/departments
  Future<List<DepartmentModel>> fetchDepartments() async {
    return await DemographicRepository.fetchDepartmentsFromApi(client: _client);
  }

  /// 4. Fetch Villages for Gram Panchayat:
  /// GET /api/locations/villages?gram_panchayat_lgd_code={code}
  Future<List<VillageModel>> fetchVillagesForPanchayat(
    int gramPanchayatLgdCode,
  ) async {
    return await DemographicRepository.fetchVillagesFromApi(
      gramPanchayatLgdCode.toString(),
    );
  }

  /// Helper to resolve COHV type / sector to sector key (e.g. human, animal, wildlife, environment)
  static String mapCohvTypeToSector(String? cohvType) {
    if (cohvType == null || cohvType.trim().isEmpty) return 'human';
    final lower = cohvType.toLowerCase().trim();
    if (lower.contains('public health') ||
        lower.contains('health') ||
        lower.contains('human')) {
      return 'human';
    }
    if (lower.contains('animal') ||
        lower.contains('veterinary') ||
        lower.contains('husbandry') ||
        lower.contains('paravet')) {
      return 'animal';
    }
    if (lower.contains('wildlife') || lower.contains('forest')) {
      return 'wildlife';
    }
    if (lower.contains('environment') ||
        lower.contains('pollution') ||
        lower.contains('sanitation')) {
      return 'environment';
    }
    return 'human';
  }

  /// Resolves logged-in volunteer profile, sector key, and GP LGD code
  Future<VolunteerSessionInfo> getVolunteerSessionInfo({
    String? fallbackVolunteerId,
  }) async {
    final detailed = await SessionManager.getDetailedProfile();
    final session = await SessionManager.getUserSession();

    final volunteerId = (detailed?.volunteerId.isNotEmpty == true)
        ? detailed!.volunteerId
        : (session?.volunteerId.isNotEmpty == true
            ? session!.volunteerId
            : (fallbackVolunteerId ?? ''));

    final cohvType = (detailed?.cohvType != null &&
            detailed!.cohvType!.trim().isNotEmpty)
        ? detailed.cohvType!.trim()
        : (detailed?.departmentName != null &&
                detailed!.departmentName!.trim().isNotEmpty)
            ? detailed.departmentName!.trim()
            : (session?.sector != null && session!.sector.trim().isNotEmpty)
                ? session.sector.trim()
                : (session?.departmentName != null && session!.departmentName!.trim().isNotEmpty)
                    ? session!.departmentName!.trim()
                    : '';

    final gpCode = detailed?.gramPanchayatLgdCode ?? session?.gramPanchayatLgdCode;
    final gpName = detailed?.panchayat ?? session?.gramPanchayatName ?? 'Amrabad';
    final villageLgdCode = detailed?.villageLgdCode ?? session?.villageLgdCode;
    final villageName = detailed?.village ?? session?.villageName ?? 'Mannanur';
    final blockName = detailed?.block ?? session?.blockName ?? 'Amrabad';
    final districtName = detailed?.district ?? session?.districtName ?? 'Nagarkurnool';
    final stateName = detailed?.state ?? session?.stateName ?? 'Telangana';

    final sectorKey = mapCohvTypeToSector(cohvType);

    return VolunteerSessionInfo(
      volunteerCode: volunteerId,
      cohvType: cohvType,
      sectorKey: sectorKey,
      gramPanchayatLgdCode: gpCode,
      gramPanchayatName: gpName,
      villageLgdCode: villageLgdCode,
      villageName: villageName,
      blockName: blockName,
      districtName: districtName,
      stateName: stateName,
    );
  }

  /// Converts a local file path into a Base64 data URI: data:<mime>;base64,<data>
  static Future<String?> fileToDataUri(
    String filePath,
    String defaultMime,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final ext = filePath.split('.').last.toLowerCase();
      String mime = defaultMime;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          mime = 'image/jpeg';
          break;
        case 'png':
          mime = 'image/png';
          break;
        case 'webp':
          mime = 'image/webp';
          break;
        case 'gif':
          mime = 'image/gif';
          break;
        case 'mp4':
          mime = 'video/mp4';
          break;
        case 'mov':
          mime = 'video/quicktime';
          break;
        case '3gp':
          mime = 'video/3gpp';
          break;
        case 'pdf':
          mime = 'application/pdf';
          break;
        case 'doc':
          mime = 'application/msword';
          break;
        case 'docx':
          mime =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          mime = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          mime =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
      }
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('[AWARENESS_API] Error encoding file to base64 data URI: $e');
      return null;
    }
  }

  /// Submit a new awareness activity: POST /api/awareness-activities (application/json with Base64 media)
  Future<AwarenessActivitySubmitResponse> submitAwarenessActivity(
    AwarenessActivityCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointAwarenessActivities);
    debugPrint('[AWARENESS_API] POST $url (application/json)');

    // 1. Convert media files into Base64 Data URIs
    final List<String> photoDataUris = [];
    for (final path in request.photos) {
      if (path.trim().isEmpty) continue;
      if (path.startsWith('data:')) {
        photoDataUris.add(path);
      } else {
        final uri = await fileToDataUri(path, 'image/jpeg');
        if (uri != null) photoDataUris.add(uri);
      }
    }

    final List<String> videoDataUris = [];
    for (final path in request.videos) {
      if (path.trim().isEmpty) continue;
      if (path.startsWith('data:')) {
        videoDataUris.add(path);
      } else {
        final uri = await fileToDataUri(path, 'video/mp4');
        if (uri != null) videoDataUris.add(uri);
      }
    }

    final List<String> documentDataUris = [];
    for (final path in request.documents) {
      if (path.trim().isEmpty) continue;
      if (path.startsWith('data:')) {
        documentDataUris.add(path);
      } else {
        final uri = await fileToDataUri(path, 'application/pdf');
        if (uri != null) documentDataUris.add(uri);
      }
    }

    // 2. Build JSON payload matching backend AwarenessActivityCreate schema
    final dateStr =
        '${request.activityDate.year.toString().padLeft(4, '0')}-${request.activityDate.month.toString().padLeft(2, '0')}-${request.activityDate.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic> payload = {
      'awareness_activity_id': request.awarenessActivityId,
      'activity_date': dateStr,
      'village_lgd_code': request.villageLgdCode,
      'photos': photoDataUris,
      'videos': videoDataUris,
      'documents': documentDataUris,
    };

    if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
      payload['client_ref'] = request.clientRef!.trim();
    }
    if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
      payload['device_id'] = request.deviceId!.trim();
    }
    if (request.peopleReached != null) {
      payload['people_reached'] = request.peopleReached;
    }
    if (request.awarenessTopicIds.isNotEmpty) {
      payload['awareness_topic_ids'] = request.awarenessTopicIds;
    }
    if (request.awarenessTopicId != null) {
      // Must be an int to avoid triggering the backend's string-based base64 photo validator
      payload['awareness_topic_id'] = request.awarenessTopicId;
    }
    if (request.departmentIds.isNotEmpty) {
      payload['department_ids'] = request.departmentIds;
    }
    if (request.departmentId != null) {
      payload['department_id'] = request.departmentId;
    }
    if (request.caption != null && request.caption!.trim().isNotEmpty) {
      final cleanCaption = request.caption!.trim();
      payload['description'] = cleanCaption;
      payload['media_caption'] = cleanCaption;
      payload['caption'] = cleanCaption;
    }

    // Safely combine department_other and any custom/other topic details into department_other.
    // Note: Top-level keys containing "pic" (like "topic_other") trigger the backend's flawed
    // image validator when sent as strings, so custom topic info is safely preserved
    // in department_other on the backend, while remaining fully retained in local cache.
    String? combinedOther = request.departmentOther?.trim();
    if (request.topicOther != null && request.topicOther!.trim().isNotEmpty) {
      final topicNote = 'Topic: ${request.topicOther!.trim()}';
      if (combinedOther != null && combinedOther.isNotEmpty) {
        combinedOther = '$combinedOther; $topicNote';
      } else {
        combinedOther = topicNote;
      }
    }
    if (combinedOther != null && combinedOther.isNotEmpty) {
      payload['department_other'] = combinedOther;
    }

    if (request.latitude != null && request.longitude != null) {
      payload['latitude'] = request.latitude;
      payload['longitude'] = request.longitude;
      if (request.gpsAccuracyM != null) {
        payload['gps_accuracy_m'] = request.gpsAccuracyM;
      }
    } else if (request.gpsUnavailableReason != null &&
        request.gpsUnavailableReason!.trim().isNotEmpty) {
      payload['gps_unavailable_reason'] =
          request.gpsUnavailableReason!.trim();
    }
    payload['captured_at'] = request.activityDate.toIso8601String();

    final headers = ApiConstants.defaultHeaders(token: token);
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';

    final bodyJson = jsonEncode(payload);

    ApiConstants.logRequest(
      module: 'Awareness Activity',
      method: 'POST',
      url: url,
      body: payload,
    );

    try {
      final response = await _client
          .post(url, headers: headers, body: bodyJson)
          .timeout(const Duration(seconds: 45));

      debugPrint(
        '[AWARENESS_API] Response status: ${response.statusCode}, body: ${response.body}',
      );

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (decoded is Map) {
          return AwarenessActivitySubmitResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      // If backend returned error message
      String errorMsg =
          'Failed to submit awareness activity (${response.statusCode})';
      if (decoded is Map) {
        if (decoded['detail'] != null) {
          if (decoded['detail'] is List) {
            final list = decoded['detail'] as List;
            errorMsg = list
                .map((e) =>
                    e is Map ? (e['msg'] ?? e['message']) : e.toString())
                .join(', ');
          } else {
            errorMsg = decoded['detail'].toString();
          }
        } else if (decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[AWARENESS_API] Error submitting awareness activity: $e');
      rethrow;
    }
  }

  /// Update an existing awareness activity: PUT /api/awareness-activities/{awareness_id}
  Future<AwarenessActivitySubmitResponse> updateAwarenessActivity(
    int awarenessId,
    AwarenessActivityCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(ApiConstants.endpointAwarenessDetail(awarenessId));
    debugPrint('[AWARENESS_API] PUT $url (awarenessId: $awarenessId)');

    // 1. Convert media files into Base64 Data URIs (skip already remote URLs)
    final List<String> photoDataUris = [];
    for (final path in request.photos) {
      if (path.trim().isEmpty) continue;
      if (path.startsWith('data:') || path.startsWith('http')) {
        photoDataUris.add(path);
      } else {
        final uri = await fileToDataUri(path, 'image/jpeg');
        if (uri != null) photoDataUris.add(uri);
      }
    }

    final List<String> videoDataUris = [];
    for (final path in request.videos) {
      if (path.trim().isEmpty) continue;
      if (path.startsWith('data:') || path.startsWith('http')) {
        videoDataUris.add(path);
      } else {
        final uri = await fileToDataUri(path, 'video/mp4');
        if (uri != null) videoDataUris.add(uri);
      }
    }

    final List<String> documentDataUris = [];
    for (final path in request.documents) {
      if (path.trim().isEmpty) continue;
      if (path.startsWith('data:') || path.startsWith('http')) {
        documentDataUris.add(path);
      } else {
        final uri = await fileToDataUri(path, 'application/pdf');
        if (uri != null) documentDataUris.add(uri);
      }
    }

    final dateStr =
        '${request.activityDate.year.toString().padLeft(4, '0')}-${request.activityDate.month.toString().padLeft(2, '0')}-${request.activityDate.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic> payload = {
      'awareness_activity_id': request.awarenessActivityId,
      'activity_date': dateStr,
      'village_lgd_code': request.villageLgdCode,
      'photos': photoDataUris,
      'videos': videoDataUris,
      'documents': documentDataUris,
    };

    if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
      payload['client_ref'] = request.clientRef!.trim();
    }
    if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
      payload['device_id'] = request.deviceId!.trim();
    }
    if (request.peopleReached != null) {
      payload['people_reached'] = request.peopleReached;
    }
    if (request.awarenessTopicIds.isNotEmpty) {
      payload['awareness_topic_ids'] = request.awarenessTopicIds;
    }
    if (request.awarenessTopicId != null) {
      payload['awareness_topic_id'] = request.awarenessTopicId;
    }
    if (request.departmentIds.isNotEmpty) {
      payload['department_ids'] = request.departmentIds;
    }
    if (request.departmentId != null) {
      payload['department_id'] = request.departmentId;
    }
    if (request.caption != null && request.caption!.trim().isNotEmpty) {
      final cleanCaption = request.caption!.trim();
      payload['description'] = cleanCaption;
      payload['media_caption'] = cleanCaption;
      payload['caption'] = cleanCaption;
    }

    final String? cleanDepOther =
        (request.departmentOther != null && request.departmentOther!.trim().isNotEmpty)
            ? request.departmentOther!.trim()
            : null;
    final String? cleanTopicOther =
        (request.topicOther != null && request.topicOther!.trim().isNotEmpty)
            ? request.topicOther!.trim()
            : null;

    if (cleanDepOther != null && cleanTopicOther != null) {
      payload['department_other'] = '$cleanDepOther | Topic: $cleanTopicOther';
    } else if (cleanDepOther != null) {
      payload['department_other'] = cleanDepOther;
    } else if (cleanTopicOther != null) {
      payload['department_other'] = 'Topic: $cleanTopicOther';
    }

    if (request.latitude != null) payload['latitude'] = request.latitude;
    if (request.longitude != null) payload['longitude'] = request.longitude;
    if (request.gpsAccuracyM != null) {
      payload['gps_accuracy_m'] = request.gpsAccuracyM;
    }
    if (request.gpsUnavailableReason != null &&
        request.gpsUnavailableReason!.trim().isNotEmpty) {
      payload['gps_unavailable_reason'] = request.gpsUnavailableReason!.trim();
    }
    payload['captured_at'] = request.activityDate.toIso8601String();

    ApiConstants.logRequest(
      module: 'Awareness Activity',
      method: 'PUT',
      url: url,
      body: payload,
    );

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await _client
          .put(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 45));

      debugPrint('[AWARENESS_API] Response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return AwarenessActivitySubmitResponse.fromJson(decoded);
        }
        return AwarenessActivitySubmitResponse(
          message: 'Awareness activity updated successfully.',
          awarenessId: awarenessId,
          awarenessCode: 'AWR-$awarenessId',
          verificationStatus: 'SUBMITTED',
          duplicate: false,
        );
      }

      String errorMsg = 'Failed to update activity (${response.statusCode})';
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] != null) {
          if (decoded['detail'] is List) {
            errorMsg = (decoded['detail'] as List)
                .map((e) => e['msg'] ?? e.toString())
                .join(', ');
          } else {
            errorMsg = decoded['detail'].toString();
          }
        } else if (decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[AWARENESS_API] Error updating awareness activity: $e');
      rethrow;
    }
  }

  /// Fetch list of awareness activities from GET /api/awareness-activities/all
  /// with ?volunteer_id=... query parameter, and applies strict client-side
  /// ownership verification against the active volunteer.
  Future<List<AwarenessItem>> getAwarenessList([
    String? volunteerId,
    int? numericVolunteerId,
  ]) async {
    final token = await SessionManager.getToken();
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

    final queryParams = <String, String>{};
    if (effectiveNumericId != null && effectiveNumericId > 0) {
      queryParams['volunteer_id'] = effectiveNumericId.toString();
    }
    final allUri = Uri.parse(endpointAwarenessAll).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    debugPrint('[AWARENESS_API] GET $allUri');

    List<AwarenessItem> remoteActivities = [];

    try {
      final response = await _client
          .get(allUri, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AWARENESS_API] /all status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> rawList = [];
        if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        } else if (decoded is List) {
          rawList = decoded;
        }

        remoteActivities = rawList
            .whereType<Map>()
            .map(
              (item) =>
                  AwarenessItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .where(
              (act) => VolunteerOwnershipFilter.isOwnedByVolunteer(
                itemOwnerId: act.volunteerId.isNotEmpty ? act.volunteerId : act.volunteerCode,
                itemNumericId: act.numericVolunteerId,
                activeVolunteerId: effectiveVolunteerId,
                activeNumericId: effectiveNumericId,
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[AWARENESS_API] Error fetching live awareness list: $e');
    }

    // Persist remote activities into volunteer-scoped local cache
    if (remoteActivities.isNotEmpty) {
      await SessionManager.saveSubmittedAwarenessList(
        remoteActivities,
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
    }

    // Merge with locally queued/offline-stored awareness activities scoped to this volunteer
    try {
      final localStored = await SessionManager.getSubmittedAwarenessActivities(
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
      if (localStored.isNotEmpty) {
        final existingIds = remoteActivities.map((a) => a.id).toSet();
        for (final local in localStored) {
          if (!existingIds.contains(local.id) &&
              VolunteerOwnershipFilter.isOwnedByVolunteer(
                itemOwnerId: local.volunteerId.isNotEmpty ? local.volunteerId : local.volunteerCode,
                itemNumericId: local.numericVolunteerId,
                activeVolunteerId: effectiveVolunteerId,
                activeNumericId: effectiveNumericId,
              )) {
            remoteActivities.insert(0, local);
          }
        }
      }
    } catch (e) {
      debugPrint('[AWARENESS_API] Error merging local awareness activities: $e');
    }

    // Final fail-closed safety filter on returned list
    return remoteActivities
        .where(
          (act) => VolunteerOwnershipFilter.isOwnedByVolunteer(
            itemOwnerId: act.volunteerId.isNotEmpty ? act.volunteerId : act.volunteerCode,
            itemNumericId: act.numericVolunteerId,
            activeVolunteerId: effectiveVolunteerId,
            activeNumericId: effectiveNumericId,
          ),
        )
        .toList();
  }

  /// Fetch a single awareness activity record by awareness ID:
  /// GET /api/awareness-activities/{awareness_id}
  Future<AwarenessItem?> fetchAwarenessDetail(int awarenessId) async {
    String? token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      final session = await SessionManager.getUserSession();
      token = session?.token;
    }

    final url = Uri.parse(ApiConstants.endpointAwarenessDetail(awarenessId));
    debugPrint('[AWARENESS_API] GET $url');

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AWARENESS_API] GET /api/awareness-activities/$awarenessId status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final Map<String, dynamic> data = decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : Map<String, dynamic>.from(decoded);
          return AwarenessItem.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint(
        '[AWARENESS_API] Error fetching awareness detail ($awarenessId): $e',
      );
    }
    return null;
  }

  /// Create and submit a new awareness activity (local offline sync queue)
  Future<AwarenessItem> createAwareness(AwarenessItem item) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Automatically enqueue into local offline Sync Repository
    await _syncRepository.enqueueRecord(
      entityType: 'AWR',
      payload: item.toJson(),
    );

    return item;
  }
}
