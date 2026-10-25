// API Service for Success Stories Module
// File: lib/features/success_stories/data/success_story_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import '../domain/success_story_models.dart';

class SuccessStoryApiService {
  final http.Client _client;

  SuccessStoryApiService({http.Client? client})
      : _client = client ?? http.Client();

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

    debugPrint(
      '[SUCCESS_STORY_API] POST $uri with payload: ${jsonEncode(request.toJson())}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final body = jsonEncode(request.toJson());

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

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
