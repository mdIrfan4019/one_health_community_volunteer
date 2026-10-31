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
import '../domain/success_story_models.dart';
import 'package:cohv/core/models/geo_location_data.dart';

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

    // Fallback to default list matching staging backend master
    return SuccessStoryDepartmentModel.fallbackDepartments();
  }

  /// 2. Submit Success Story via POST /api/success-stories
  Future<SuccessStoryCreateResponse> submitSuccessStory(
    SuccessStoryCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSuccessStories);

    final hasAttachments = request.photos.isNotEmpty ||
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
        multipart.fields['department_id'] = request.departmentId.toString();
        final deptIds = request.departmentIds.isNotEmpty
            ? request.departmentIds
            : [request.departmentId];
        multipart.fields['department_ids'] = jsonEncode(deptIds);
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

        // Attach photos
        for (final path in request.photos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath('photos', path, filename: fileName),
            );
          }
        }

        // Attach videos
        for (final path in request.videos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath('videos', path, filename: fileName),
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
              await http.MultipartFile.fromPath('documents', path, filename: fileName),
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
            errorMessage = errorJson['detail']?.toString() ??
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
      multipart.fields['department_id'] = request.departmentId.toString();
      final deptIds = request.departmentIds.isNotEmpty
          ? request.departmentIds
          : [request.departmentId];
      multipart.fields['department_ids'] = jsonEncode(deptIds);
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
            errorMessage = errorJson['detail']?.toString() ??
                errorJson['message']?.toString() ??
                errorMessage;
          }
        } catch (_) {}
        return SuccessStoryCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Network error updating success story: $e');
      return SuccessStoryCreateResponse.failure(
        'Network error: Unable to update story ($e)',
      );
    }
  }

  /// 3. Fetch All Success Stories: GET /api/success-stories/all
  Future<List<SuccessStoryRecordModel>> fetchSuccessStoriesList({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSuccessStoriesAll);

    debugPrint(
      '[SUCCESS_STORY_API] GET $uri with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

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

        final allRecords = list
            .whereType<Map>()
            .map(
              (item) => SuccessStoryRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        // Scope to logged-in volunteer if volunteer identity is available
        final session = await SessionManager.getUserSession();
        final effectiveCode = (volunteerId != null && volunteerId.isNotEmpty)
            ? volunteerId
            : (session?.volunteerId ?? '');
        final effectiveNumId = numericVolunteerId ?? session?.numericVolunteerId;

        List<SuccessStoryRecordModel> ownedRecords;
        if (effectiveCode.isNotEmpty || (effectiveNumId != null && effectiveNumId > 0)) {
          ownedRecords = allRecords.where((item) {
            return VolunteerOwnershipFilter.isOwnedByVolunteer(
              recordNumericVolunteerId: item.volunteerId,
              recordVolunteerCode: item.volunteerName,
              recordVolunteerId: item.volunteerName,
              recordVolunteerName: item.volunteerName,
              authNumericVolunteerId: effectiveNumId,
              authVolunteerCode: effectiveCode,
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
        }

        return ownedRecords;
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_API] Error fetching success stories: $e');
    }

    // Offline cache fallback
    final cached = await SessionManager.getSubmittedSuccessStoriesList(
      volunteerId: volunteerId,
    );
    if (cached.isNotEmpty) {
      return cached;
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
          .timeout(const Duration(seconds: 15));

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
        '[SUCCESS_STORY_API] Error fetching success story detail ($storyId): $e',
      );
    }

    // Offline fallback from local cache
    final cached = await SessionManager.getSubmittedSuccessStoriesList();
    for (final item in cached) {
      if (item.storyId == storyId) {
        return item;
      }
    }

    return null;
  }
}
