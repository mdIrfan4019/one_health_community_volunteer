// API Service for Success Stories Module
// File: lib/features/success_stories/data/success_story_api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import '../domain/success_story_models.dart';

import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/database/master_data_cache_service.dart';
import 'package:cohv/core/database/offline_outbox_service.dart';

class SuccessStoryApiService {
  final http.Client _client;

  SuccessStoryApiService({http.Client? client})
      : _client = client ?? AuthenticatedHttpClient.instance;

  /// 1. Fetch Departments from GET /api/success-stories/departments
  Future<List<SuccessStoryDepartmentModel>> fetchDepartments() async {
    final uri = Uri.parse(ApiConstants.endpointSuccessStoriesDepartments);

    debugPrint('[SUCCESS_STORY_API] GET $uri');

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[SUCCESS_STORY_API] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['value'] is List) {
          list = decoded['value'] as List<dynamic>;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'] as List<dynamic>;
        } else {
          list = [];
        }

        final departments = list
            .whereType<Map>()
            .map(
              (item) => SuccessStoryDepartmentModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        if (departments.isNotEmpty) {
          // Ensure Community / NGO and Other exist for custom stakeholder selection
          final hasCommunity = departments.any(
            (d) => d.departmentName.toLowerCase().contains('community'),
          );
          if (!hasCommunity) {
            departments.add(
              const SuccessStoryDepartmentModel(
                departmentId: 7,
                departmentName: 'Community / NGO',
                isOther: true,
              ),
            );
          }

          final hasOther = departments.any(
            (d) => d.departmentName.toLowerCase() == 'other',
          );
          if (!hasOther) {
            departments.add(
              const SuccessStoryDepartmentModel(
                departmentId: 99,
                departmentName: 'Other',
                isOther: true,
              ),
            );
          }

          return departments;
        }
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Error fetching departments: $e');
    }

    // SQLite offline cache fallback
    try {
      final offline = await MasterDataCacheService.instance
          .getSuccessStoryDepartments();
      if (offline.isNotEmpty) return offline;
    } catch (_) {}

    // Fallback to standard /api/departments endpoint if /api/success-stories/departments is unavailable
    try {
      final stdDepts = await DemographicRepository.fetchDepartmentsFromApi(client: _client);
      if (stdDepts.isNotEmpty) {
        final departments = stdDepts.map((d) => SuccessStoryDepartmentModel(
          departmentId: d.departmentId,
          departmentName: d.departmentName,
          isOther: d.departmentName.toLowerCase() == 'other' ||
              d.departmentName.toLowerCase().contains('other') ||
              d.departmentName.toLowerCase().contains('community'),
        )).toList();

        if (!departments.any((d) => d.departmentName.toLowerCase().contains('community'))) {
          departments.add(
            const SuccessStoryDepartmentModel(
              departmentId: 7,
              departmentName: 'Community / NGO',
              isOther: true,
            ),
          );
        }
        if (!departments.any((d) => d.isOther)) {
          departments.add(
            const SuccessStoryDepartmentModel(
              departmentId: 99,
              departmentName: 'Other',
              isOther: true,
            ),
          );
        }
        return departments;
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Error fetching fallback /api/departments: $e');
    }

    // Fallback to default list matching staging backend master
    return SuccessStoryDepartmentModel.fallbackDepartments();
  }

  /// 2. Submit Success Story via POST /api/success-stories
  Future<SuccessStoryCreateResponse> submitSuccessStory(
    SuccessStoryCreateRequest request, {
    bool allowOfflineFallback = true,
  }) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSuccessStories);

    final hasAttachments =
        request.photos.isNotEmpty ||
        request.videos.isNotEmpty ||
        request.documents.isNotEmpty;

    debugPrint(
      '[SUCCESS_STORY_API] POST $uri (hasAttachments: $hasAttachments, '
      'photos: ${request.photos.length}, videos: ${request.videos.length}, docs: ${request.documents.length})',
    );

    try {
      http.Response response;

      if (hasAttachments) {
        final multipart = http.MultipartRequest('POST', uri);
        if (token != null && token.isNotEmpty) {
          multipart.headers['Authorization'] = 'Bearer $token';
        }
        multipart.headers['Accept'] = 'application/json';

        // Add form fields
        multipart.fields['volunteer_id'] = request.volunteerId.toString();
        multipart.fields['client_ref'] = request.clientRef;
        multipart.fields['device_id'] = request.deviceId;
        multipart.fields['title'] = request.title;
        multipart.fields['story_date'] = request.storyDate;
        multipart.fields['location_text'] = request.locationText;
        multipart.fields['one_health_issue'] = request.oneHealthIssue;
        multipart.fields['situation'] = request.situation;
        multipart.fields['action_taken'] = request.actionTaken;
        final deptIds = request.departmentIds.isNotEmpty
            ? request.departmentIds
            : (request.departmentId != null ? [request.departmentId!] : <int>[]);
        if (deptIds.isNotEmpty) {
          multipart.fields['department_id'] = jsonEncode(deptIds);
          multipart.fields['department_ids'] = jsonEncode(deptIds);
        }
        if (request.departmentOther != null &&
            request.departmentOther!.trim().isNotEmpty) {
          multipart.fields['department_other'] = request.departmentOther!
              .trim();
        }
        if (request.caption != null && request.caption!.trim().isNotEmpty) {
          final cap = request.caption!.trim();
          multipart.fields['caption'] = cap;
          multipart.fields['media_caption'] = cap;
          multipart.fields['description'] = cap;
        }
        multipart.fields['outcome'] = request.outcome;
        if (request.communityBenefit != null &&
            request.communityBenefit!.trim().isNotEmpty) {
          multipart.fields['community_benefit'] = request.communityBenefit!
              .trim();
        }
        if (request.lessonsLearned != null &&
            request.lessonsLearned!.trim().isNotEmpty) {
          multipart.fields['lessons_learned'] = request.lessonsLearned!.trim();
        }
        multipart.fields['is_innovation'] = request.isInnovation.toString();
        if (request.latitude != null) {
          multipart.fields['latitude'] = GeoLocationData.formatCoordinateString(
            request.latitude,
          )!;
        }
        if (request.longitude != null) {
          multipart.fields['longitude'] =
              GeoLocationData.formatCoordinateString(request.longitude)!;
        }
        if (request.gpsAccuracyM != null) {
          multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
        }
        if (request.gpsUnavailableReason != null &&
            request.gpsUnavailableReason!.trim().isNotEmpty) {
          multipart.fields['gps_unavailable_reason'] = request
              .gpsUnavailableReason!
              .trim();
        }

        // Attach photos
        for (final path in request.photos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath(
                'photos',
                path,
                filename: fileName,
              ),
            );
          }
        }

        // Attach videos
        for (final path in request.videos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath(
                'videos',
                path,
                filename: fileName,
              ),
            );
          }
        }

        final existingPhotos = request.photos.where((p) => p.startsWith('http') || !File(p).existsSync()).toList();
        final existingVideos = request.videos.where((v) => v.startsWith('http') || !File(v).existsSync()).toList();
        final existingDocs = request.documents.where((d) => d.startsWith('http') || !File(d).existsSync()).toList();
        if (existingPhotos.isNotEmpty) {
          multipart.fields['existing_photos'] = jsonEncode(existingPhotos);
        }
        if (existingVideos.isNotEmpty) {
          multipart.fields['existing_videos'] = jsonEncode(existingVideos);
        }
        if (existingDocs.isNotEmpty) {
          multipart.fields['existing_documents'] = jsonEncode(existingDocs);
        }

        // Attach documents
        for (final path in request.documents) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath(
                'documents',
                path,
                filename: fileName,
              ),
            );
          }
        }

        ApiConstants.logRequest(
          module: 'Success Stories',
          method: 'POST',
          url: uri,
          body: multipart.fields,
        );

        final streamedResponse = await _client
            .send(multipart)
            .timeout(const Duration(seconds: 45));
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Fallback to JSON POST when no local attachments are provided
        final headers = ApiConstants.defaultHeaders(token: token);
        final body = jsonEncode(request.toJson());

        ApiConstants.logRequest(
          module: 'Success Stories',
          method: 'POST',
          url: uri,
          body: request.toJson(),
        );

        response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      }

      debugPrint(
        '[SUCCESS_STORY_API] POST $uri -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return SuccessStoryCreateResponse.fromJson(decoded);
        } else if (decoded is Map) {
          return SuccessStoryCreateResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
        return const SuccessStoryCreateResponse(
          success: true,
          message: 'Success story submitted successfully.',
        );
      } else {
        String errorMessage = 'Server error (${response.statusCode})';
        try {
          final dynamic errorJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorJson is Map) {
            errorMessage =
                errorJson['detail']?.toString() ??
                errorJson['message']?.toString() ??
                errorMessage;
          }
        } catch (_) {}
        return SuccessStoryCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint(
        '[SUCCESS_STORY_API] Network error submitting success story: $e',
      );
      if (allowOfflineFallback && OfflineOutboxService.isNetworkException(e)) {
        return await _saveSuccessStoryOffline(request);
      }
      return SuccessStoryCreateResponse.failure(
        'Network error: Unable to submit to server ($e)',
      );
    }
  }

  /// Update Success Story: PUT /api/success-stories/{story_id}
  Future<SuccessStoryCreateResponse> updateSuccessStory(
    int storyId,
    SuccessStoryCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSuccessStoryDetail(storyId));

    final hasAttachments =
        request.photos.any((p) => !p.startsWith('http')) ||
        request.videos.any((v) => !v.startsWith('http')) ||
        request.documents.any((d) => !d.startsWith('http'));

    debugPrint(
      '[SUCCESS_STORY_API] PUT $uri (storyId: $storyId, photos: ${request.photos.length}, videos: ${request.videos.length}, docs: ${request.documents.length})',
    );

    try {
      final multipart = http.MultipartRequest('PUT', uri);
      if (token != null && token.isNotEmpty) {
        multipart.headers['Authorization'] = 'Bearer $token';
      }
      multipart.headers['Accept'] = 'application/json';

      // Add standard form fields
      multipart.fields['volunteer_id'] = request.volunteerId.toString();
      multipart.fields['client_ref'] = request.clientRef;
      multipart.fields['device_id'] = request.deviceId;
      multipart.fields['title'] = request.title;
      multipart.fields['story_date'] = request.storyDate;
      multipart.fields['location_text'] = request.locationText;
      multipart.fields['one_health_issue'] = request.oneHealthIssue;
      multipart.fields['situation'] = request.situation;
      multipart.fields['action_taken'] = request.actionTaken;
      final deptIds = request.departmentIds.isNotEmpty
          ? request.departmentIds
          : (request.departmentId != null ? [request.departmentId!] : <int>[]);
      if (deptIds.isNotEmpty) {
        multipart.fields['department_id'] = jsonEncode(deptIds);
        multipart.fields['department_ids'] = jsonEncode(deptIds);
        if (request.departmentOther != null &&
            request.departmentOther!.trim().isNotEmpty) {
          multipart.fields['department_other'] = request.departmentOther!
              .trim();
        }
        if (request.caption != null && request.caption!.trim().isNotEmpty) {
          final cap = request.caption!.trim();
          multipart.fields['caption'] = cap;
          multipart.fields['media_caption'] = cap;
          multipart.fields['description'] = cap;
        }
        multipart.fields['outcome'] = request.outcome;
        if (request.communityBenefit != null &&
            request.communityBenefit!.trim().isNotEmpty) {
          multipart.fields['community_benefit'] = request.communityBenefit!
              .trim();
        }
        if (request.lessonsLearned != null &&
            request.lessonsLearned!.trim().isNotEmpty) {
          multipart.fields['lessons_learned'] = request.lessonsLearned!.trim();
        }
        multipart.fields['is_innovation'] = request.isInnovation.toString();
        if (request.latitude != null) {
          multipart.fields['latitude'] = GeoLocationData.formatCoordinateString(
            request.latitude,
          )!;
        }
        if (request.longitude != null) {
          multipart.fields['longitude'] =
              GeoLocationData.formatCoordinateString(request.longitude)!;
        }
        if (request.gpsAccuracyM != null) {
          multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
        }
        if (request.gpsUnavailableReason != null &&
            request.gpsUnavailableReason!.trim().isNotEmpty) {
          multipart.fields['gps_unavailable_reason'] = request
              .gpsUnavailableReason!
              .trim();
        }
      }
      if (request.departmentOther != null &&
          request.departmentOther!.trim().isNotEmpty) {
        multipart.fields['department_other'] = request.departmentOther!.trim();
      }
      if (request.caption != null && request.caption!.trim().isNotEmpty) {
        final cap = request.caption!.trim();
        multipart.fields['caption'] = cap;
        multipart.fields['media_caption'] = cap;
        multipart.fields['description'] = cap;
      }
      multipart.fields['outcome'] = request.outcome;
      if (request.communityBenefit != null &&
          request.communityBenefit!.trim().isNotEmpty) {
        multipart.fields['community_benefit'] = request.communityBenefit!.trim();
      }
      if (request.lessonsLearned != null &&
          request.lessonsLearned!.trim().isNotEmpty) {
        multipart.fields['lessons_learned'] = request.lessonsLearned!.trim();
      }
      multipart.fields['is_innovation'] = request.isInnovation.toString();
      if (request.latitude != null) {
        multipart.fields['latitude'] =
            GeoLocationData.formatCoordinateString(request.latitude)!;
      }
      if (request.longitude != null) {
        multipart.fields['longitude'] =
            GeoLocationData.formatCoordinateString(request.longitude)!;
      }
      if (request.gpsAccuracyM != null) {
        multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
      }
      if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.trim().isNotEmpty) {
        multipart.fields['gps_unavailable_reason'] =
            request.gpsUnavailableReason!.trim();
      }

      // Helper to check if a path is an existing remote or server asset
      bool isExistingAsset(String p) {
        final clean = p.trim();
        if (clean.isEmpty || (clean.startsWith('{') && clean.endsWith('}'))) return false;
        return clean.startsWith('http') ||
            clean.startsWith('/uploads') ||
            clean.startsWith('uploads/') ||
            clean.startsWith('/api/') ||
            !File(clean).existsSync();
      }

      // Attach newly picked local photos
      for (final path in request.photos) {
        if (isExistingAsset(path)) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(RegExp(r'[/\\]')).last.split('?').first;
          multipart.files.add(
            await http.MultipartFile.fromPath('photos', path, filename: fileName),
          );
        }
      }
        // Attach photos
        for (final path in request.photos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath(
                'photos',
                path,
                filename: fileName,
              ),
            );
          }
        }

        // Attach documents
        for (final path in request.documents) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath(
                'documents',
                path,
                filename: fileName,
              ),
            );
          }
        }
      // Attach newly picked local videos
      for (final path in request.videos) {
        if (isExistingAsset(path)) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(RegExp(r'[/\\]')).last.split('?').first;
          multipart.files.add(
            await http.MultipartFile.fromPath('videos', path, filename: fileName),
          );
        }
      }

        // Attach videos
        for (final path in request.videos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath(
                'videos',
                path,
                filename: fileName,
              ),
            );
          }
        }
      // Attach newly picked local documents
      for (final path in request.documents) {
        if (isExistingAsset(path)) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(RegExp(r'[/\\]')).last.split('?').first;
          multipart.files.add(
            await http.MultipartFile.fromPath('documents', path, filename: fileName),
          );
        }
      }

      // Preserve existing server attachments
      final cleanExistingPhotos = request.photos
          .where(isExistingAsset)
          .where((p) => !p.startsWith('{'))
          .toList();
      final cleanExistingVideos = request.videos
          .where(isExistingAsset)
          .where((v) => !v.startsWith('{'))
          .toList();
      final cleanExistingDocs = request.documents
          .where(isExistingAsset)
          .where((d) => !d.startsWith('{'))
          .toList();

      if (cleanExistingPhotos.isNotEmpty) {
        multipart.fields['existing_photos'] = jsonEncode(cleanExistingPhotos);
      }
      if (cleanExistingVideos.isNotEmpty) {
        multipart.fields['existing_videos'] = jsonEncode(cleanExistingVideos);
      }
      if (cleanExistingDocs.isNotEmpty) {
        multipart.fields['existing_documents'] = jsonEncode(cleanExistingDocs);
      }

      if (request.removedAttachmentIds.isNotEmpty) {
        multipart.fields['removed_attachment_ids'] = jsonEncode(request.removedAttachmentIds);
      }

      ApiConstants.logRequest(
        module: 'Success Stories',
        method: 'PUT',
        url: uri,
        body: multipart.fields,
      );

      final streamed = await _client.send(multipart).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return SuccessStoryCreateResponse.fromJson(decoded);
        } else if (decoded is Map) {
          return SuccessStoryCreateResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
        return const SuccessStoryCreateResponse(
          success: true,
          message: 'Success story updated successfully.',
        );
      } else {
        String errorMessage = 'Server returned code ${response.statusCode}';
        try {
          final dynamic errorJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorJson is Map) {
            errorMessage =
                errorJson['detail']?.toString() ??
                errorJson['message']?.toString() ??
                errorMessage;
          }
        } catch (_) {}
        return SuccessStoryCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint(
        '[SUCCESS_STORY_API] Network error updating success story: $e',
      );
      return SuccessStoryCreateResponse.failure(
        'Network error: Unable to update story ($e)',
      );
    }
  }

  /// Instant offline loader: retrieves cached success stories from SQLite and merges
  /// pending outbox items without performing any network call.
  Future<List<SuccessStoryRecordModel>> getCachedSuccessStoriesList({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final session = await SessionManager.getUserSession();
      final effectiveCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');

      List<SuccessStoryRecordModel> localRecords = [];

      // Try with volunteer code key first
      if (effectiveCode.isNotEmpty) {
        final cachedRows = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'SUCCESS_STORY',
          volunteerId: effectiveCode,
        );
        if (cachedRows.isNotEmpty) {
          for (final r in cachedRows) {
            try {
              localRecords.add(SuccessStoryRecordModel.fromJson(r));
            } catch (_) {}
          }
        }
      }

      // Also try with 'DEFAULT' key (used when volunteerId was empty at submission time)
      if (localRecords.isEmpty) {
        final defaultRows = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'SUCCESS_STORY',
          volunteerId: 'DEFAULT',
        );
        if (defaultRows.isNotEmpty) {
          for (final r in defaultRows) {
            try {
              localRecords.add(SuccessStoryRecordModel.fromJson(r));
            } catch (_) {}
          }
        }
      }

      // Fallback to SharedPreferences cache
      if (localRecords.isEmpty) {
        final cached = await SessionManager.getSubmittedSuccessStoriesList(
          volunteerId: volunteerId,
        );
        if (cached.isNotEmpty) {
          localRecords = cached;
        }
      }

      final pending = await _getPendingSuccessStoriesFromOutbox();
      final Map<String, SuccessStoryRecordModel> dedup = {};
      for (final p in pending) {
        final key = p.storyCode.isNotEmpty ? p.storyCode : 'PENDING_${p.storyId}';
        dedup[key] = p;
      }
      for (final r in localRecords) {
        final key = r.storyCode.isNotEmpty ? r.storyCode : (r.storyId > 0 ? r.storyId.toString() : '');
        if (key.isNotEmpty) {
          dedup[key] = r;
        } else {
          dedup['STORY_${dedup.length}'] = r;
        }
      }
      final resultList = dedup.values.toList();
      resultList.sort((a, b) => b.storyId.compareTo(a.storyId));
      return resultList;
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Error reading cached success stories: $e');
      return [];
    }
  }

  /// 3. Fetch All Success Stories: GET /api/success-stories/all?volunteer_id={id}
  Future<List<SuccessStoryRecordModel>> fetchSuccessStoriesList({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    final token = await SessionManager.getToken();
    final session = await SessionManager.getUserSession();
    // Resolve the numeric DB volunteer ID — do NOT use code suffix as it
    // may not match the actual DB primary key (e.g. COHV-26-0073 suffix=73 != DB id=37)
    final storedNumId = await SessionManager.getNumericVolunteerId();
    final effectiveCode = (volunteerId != null && volunteerId.isNotEmpty)
        ? volunteerId
        : (session?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');
    // Priority: explicit param → session numericVolunteerId → stored SharedPrefs key
    // Do NOT fall back to code suffix — that can be wrong (e.g. 73 vs DB id 37)
    final effectiveNumId = numericVolunteerId ??
        session?.numericVolunteerId ??
        storedNumId;
    final effectiveName = session?.fullName;

    final queryParams = <String, String>{};
    if (effectiveNumId != null && effectiveNumId > 0) {
      queryParams['volunteer_id'] = effectiveNumId.toString();
    }
    final uri = Uri.parse(ApiConstants.endpointSuccessStoriesAll)
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    debugPrint(
      '[SUCCESS_STORY_API] GET $uri with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      http.Response response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      // Fallback: If filtered endpoint returns non-200, try bare endpoint
      if (response.statusCode != 200 && queryParams.isNotEmpty) {
        debugPrint(
          '[SUCCESS_STORY_API] Filtered GET $uri returned ${response.statusCode}, trying bare endpoint',
        );
        final bareUri = Uri.parse(ApiConstants.endpointSuccessStoriesAll);
        final fallbackResp = await _client
            .get(bareUri, headers: headers)
            .timeout(const Duration(seconds: 10));
        if (fallbackResp.statusCode == 200) {
          response = fallbackResp;
        }
      }

      debugPrint(
        '[SUCCESS_STORY_API] GET $uri status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list;
        if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          list = decoded;
        } else {
          list = [];
        }

        final allRecords = <SuccessStoryRecordModel>[];
        for (final item in list.whereType<Map>()) {
          try {
            allRecords.add(
              SuccessStoryRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (e) {
            debugPrint('[SUCCESS_STORY_API] Error parsing single story item: $e');
          }
        }

        List<SuccessStoryRecordModel> ownedRecords;
        if (queryParams.containsKey('volunteer_id')) {
          // Backend has already filtered by volunteer_id
          ownedRecords = allRecords;
        } else if (effectiveCode.isNotEmpty ||
            (effectiveNumId != null && effectiveNumId > 0) ||
            (effectiveName != null && effectiveName.trim().isNotEmpty)) {
          ownedRecords = allRecords.where((item) {
            // 1. Explicit numeric ID match
            if (effectiveNumId != null && effectiveNumId > 0 && item.volunteerId != null && item.volunteerId! > 0) {
              if (item.volunteerId == effectiveNumId) return true;
            }
            // 2. Numeric suffix of volunteer code
            final codeSuffix = VolunteerOwnershipFilter.extractNumericSuffix(effectiveCode);
            if (codeSuffix != null && item.volunteerId != null && item.volunteerId == codeSuffix) {
              return true;
            }
            // 3. Name match
            if (effectiveName != null &&
                effectiveName.trim().isNotEmpty &&
                item.volunteerName != null &&
                item.volunteerName!.trim().isNotEmpty) {
              if (effectiveName.trim().toLowerCase() == item.volunteerName!.trim().toLowerCase()) {
                return true;
              }
            }
            // 4. Centralized VolunteerOwnershipFilter
            return VolunteerOwnershipFilter.isOwnedByVolunteer(
              recordNumericVolunteerId: item.volunteerId,
              recordVolunteerName: item.volunteerName,
              authNumericVolunteerId: effectiveNumId,
              authVolunteerCode: effectiveCode,
              authVolunteerName: effectiveName,
            );
          }).toList();

          // Fallback to allRecords if strict ownership check filtered everything (useful for test/staging envs)
          if (ownedRecords.isEmpty && allRecords.isNotEmpty) {
            ownedRecords = allRecords;
          }
        } else {
          ownedRecords = allRecords;
        }

        if (ownedRecords.isNotEmpty) {
          await SessionManager.saveSubmittedSuccessStoriesList(
            ownedRecords,
            volunteerId: effectiveCode,
          );
          AppDatabase.instance.cacheRecordsList(
            entityType: 'SUCCESS_STORY',
            volunteerId: effectiveCode.isNotEmpty ? effectiveCode : 'DEFAULT',
            records: ownedRecords.map((e) => e.toJson()).toList(),
            idExtractor: (m) => m['story_id']?.toString() ?? '',
          );
        }

        final pending = await _getPendingSuccessStoriesFromOutbox();
        final Map<String, SuccessStoryRecordModel> dedup = {};
        for (final p in pending) {
          final key = p.storyCode.isNotEmpty ? p.storyCode : 'PENDING_${p.storyId}';
          dedup[key] = p;
        }
        for (final r in ownedRecords) {
          final key = r.storyCode.isNotEmpty ? r.storyCode : (r.storyId > 0 ? r.storyId.toString() : '');
          if (key.isNotEmpty) {
            dedup[key] = r;
          } else {
            dedup['STORY_${dedup.length}'] = r;
          }
        }
        final resultList = dedup.values.toList();
        resultList.sort((a, b) => b.storyId.compareTo(a.storyId));
        return resultList;
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Error fetching success stories: $e');
    }

    // Offline cache fallback from SQLite
    try {
      final session = await SessionManager.getUserSession();
      final effectiveCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');
      List<Map<String, dynamic>> cachedRows = [];
      // Try volunteer-specific key
      if (effectiveCode.isNotEmpty) {
        cachedRows = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'SUCCESS_STORY',
          volunteerId: effectiveCode,
        );
      }
      // Fallback to 'DEFAULT' key if nothing found
      if (cachedRows.isEmpty) {
        cachedRows = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'SUCCESS_STORY',
          volunteerId: 'DEFAULT',
        );
      }
      final cachedRecords = <SuccessStoryRecordModel>[];
      for (final r in cachedRows) {
        try {
          cachedRecords.add(SuccessStoryRecordModel.fromJson(r));
        } catch (_) {}
      }
      final pending = await _getPendingSuccessStoriesFromOutbox();
      if (cachedRecords.isNotEmpty || pending.isNotEmpty) {
        final Map<String, SuccessStoryRecordModel> dedup = {};
        for (final p in pending) {
          final key = p.storyCode.isNotEmpty ? p.storyCode : 'PENDING_${p.storyId}';
          dedup[key] = p;
        }
        for (final r in cachedRecords) {
          final key = r.storyCode.isNotEmpty ? r.storyCode : (r.storyId > 0 ? r.storyId.toString() : '');
          if (key.isNotEmpty) dedup[key] = r;
        }
        final result = dedup.values.toList();
        result.sort((a, b) => b.storyId.compareTo(a.storyId));
        return result;
      }
    } catch (_) {}

    // Legacy SharedPreferences cache fallback
    final cached = await SessionManager.getSubmittedSuccessStoriesList(
      volunteerId: volunteerId,
    );
    final pending = await _getPendingSuccessStoriesFromOutbox();
    if (cached.isNotEmpty || pending.isNotEmpty) {
      return [...pending, ...cached];
    }

    return [];
  }

  /// 4. Fetch Single Success Story Details: GET /api/success-stories/{id}
  Future<SuccessStoryRecordModel?> fetchSuccessStoryDetail(int storyId) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSuccessStoryDetail(storyId));

    debugPrint(
      '[SUCCESS_STORY_API] GET $uri with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 6));

      debugPrint(
        '[SUCCESS_STORY_API] GET $uri status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> itemMap;
        if (decoded is Map && decoded['data'] is Map) {
          itemMap = Map<String, dynamic>.from(decoded['data'] as Map);
        } else if (decoded is Map<String, dynamic>) {
          itemMap = decoded;
        } else {
          return null;
        }

        final record = SuccessStoryRecordModel.fromJson(itemMap);
        await SessionManager.saveSubmittedSuccessStory(record);
        return record;
      }
    } catch (e) {
      debugPrint(
        '[SUCCESS_STORY_API] Error fetching live success story detail ($storyId): $e',
      );
    }

    // Offline fallback from SQLite and local cache
    return getCachedSuccessStoryDetail(storyId);
  }

  /// Retrieves a cached SuccessStoryRecordModel by numeric ID or clientRef
  Future<SuccessStoryRecordModel?> getCachedSuccessStoryDetail(
    dynamic idOrCode,
  ) async {
    final searchKey = idOrCode.toString();
    final numId = (idOrCode is int) ? idOrCode : int.tryParse(searchKey);

    final list = await getCachedSuccessStoriesList();
    for (final item in list) {
      if (item.storyCode == searchKey || (numId != null && item.storyId == numId)) {
        return item;
      }
    }
    return null;
  }

  // =========================================================================
  // OFFLINE OUTBOX & LOCAL CACHE HELPERS
  // =========================================================================

  Future<SuccessStoryCreateResponse> _saveSuccessStoryOffline(
    SuccessStoryCreateRequest request,
  ) async {
    try {
      final clientRef = request.clientRef.isNotEmpty
          ? request.clientRef
          : 'STY-${DateTime.now().millisecondsSinceEpoch}';

      final localId = await OfflineOutboxService.instance.enqueueSubmission(
        entityType: 'SUCCESS_STORY',
        clientRef: clientRef,
        payload: request.toJson(),
        photos: request.photos,
        documents: request.documents,
        videos: request.videos,
      );

      return SuccessStoryCreateResponse(
        success: true,
        message: 'Saved offline. Record queued for automatic synchronisation.',
        storyId: -localId,
        storyCode: clientRef,
      );
    } catch (err) {
      debugPrint('[SUCCESS_STORY_API] Offline save failed: $err');
      return SuccessStoryCreateResponse.failure('Offline save failed: $err');
    }
  }

  Future<List<SuccessStoryRecordModel>> _getPendingSuccessStoriesFromOutbox() async {
    try {
      final pendingRows = await OfflineOutboxService.instance
          .getPendingByEntity('SUCCESS_STORY');
      if (pendingRows.isEmpty) return [];

      final depts = await fetchDepartments();
      final deptMap = {for (final d in depts) d.departmentId: d.departmentName};
      final session = await SessionManager.getUserSession();

      return pendingRows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String)
            as Map<String, dynamic>;
        final deptId = payload['department_id'] is int
            ? payload['department_id'] as int
            : int.tryParse(payload['department_id']?.toString() ?? '0');
        final deptName = (deptId != null ? deptMap[deptId] : null) ??
            session?.departmentName ??
            'Department';
        final clientRef = row['client_ref']?.toString() ?? 'PENDING';
        final rowId = row['id'] as int? ?? 0;

        List<String> parseList(dynamic raw) {
          if (raw is List) return raw.map((e) => e.toString()).toList();
          return [];
        }

        return SuccessStoryRecordModel(
          storyId: -rowId,
          storyCode: clientRef,
          volunteerId: session?.numericVolunteerId,
          volunteerName: session?.fullName,
          departmentId: deptId,
          departmentName: deptName,
          title: payload['title']?.toString() ?? 'Success Story',
          storyDate: payload['story_date']?.toString() ?? '',
          locationText: payload['location_text']?.toString() ?? 'Local Area',
          oneHealthIssue:
              payload['one_health_issue']?.toString() ?? 'Community Health',
          situation: payload['situation']?.toString() ?? '',
          actionTaken: payload['action_taken']?.toString() ?? '',
          outcome: payload['outcome']?.toString() ?? '',
          communityBenefit: payload['community_benefit']?.toString(),
          lessonsLearned: payload['lessons_learned']?.toString(),
          verificationStatus: 'PENDING',
          createdAt: row['created_at']?.toString(),
          photos: parseList(payload['photos']),
          videos: parseList(payload['videos']),
          documents: parseList(payload['documents']),
        );
      }).toList();
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Error reading pending outbox: $e');
      return [];
    }
  }
}
