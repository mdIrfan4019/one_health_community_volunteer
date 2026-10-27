// API Service for Capacity Building Module
// File: lib/features/capacity_building/data/capacity_building_api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';

import '../domain/capacity_building_models.dart';

class CapacityBuildingApiService {
  final http.Client _client;

  CapacityBuildingApiService({http.Client? client})
    : _client = client ?? http.Client();

  // =========================================================================
  // 1. TRAINING MASTER
  // =========================================================================

  /// Fetch Training Masters: GET /api/capacity-building/training-master
  Future<List<TrainingMasterModel>> fetchTrainingMasters() async {
    final uri = Uri.parse(ApiConstants.endpointTrainingMaster);
    debugPrint('[CAPACITY_BUILDING_API] GET $uri');

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CAPACITY_BUILDING_API] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is Map && decoded['items'] is List) {
          list = decoded['items'] as List<dynamic>;
        } else {
          list = [];
        }

        final types = list
            .whereType<Map>()
            .map(
              (item) =>
                  TrainingMasterModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        if (types.isNotEmpty) {
          return types;
        }
      }
    } catch (e) {
      debugPrint('[CAPACITY_BUILDING_API] Error fetching training masters: $e');
    }

    // Graceful offline fallback
    return TrainingMasterModel.fallbackTypes();
  }

  // =========================================================================
  // 2. TRAINING IMPARTED
  // =========================================================================

  /// Fetch All Training Imparted Records: GET /api/capacity-building/training-imparted
  Future<List<TrainingImpartedRecordModel>> fetchTrainingImpartedList() async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointTrainingImparted);

    debugPrint(
      '[CAPACITY_BUILDING_API] GET $uri with Bearer: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CAPACITY_BUILDING_API] GET $uri -> status: ${response.statusCode}, length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> itemsList = [];

        if (decoded is Map) {
          if (decoded['data'] is Map && decoded['data']['items'] is List) {
            itemsList = decoded['data']['items'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            itemsList = decoded['data'] as List<dynamic>;
          } else if (decoded['items'] is List) {
            itemsList = decoded['items'] as List<dynamic>;
          }
        } else if (decoded is List) {
          itemsList = decoded;
        }

        return itemsList
            .whereType<Map>()
            .map(
              (item) => TrainingImpartedRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Error fetching training imparted list: $e',
      );
    }

    return [];
  }

  /// Fetch Single Training Imparted Record: GET /api/capacity-building/training-imparted/{id}
  Future<TrainingImpartedRecordModel?> fetchTrainingImpartedDetail(
    int trainingImpartedId,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(
      ApiConstants.endpointTrainingImpartedDetail(trainingImpartedId),
    );

    debugPrint('[CAPACITY_BUILDING_API] GET $uri');

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CAPACITY_BUILDING_API] GET $uri -> status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final recordMap = decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : Map<String, dynamic>.from(decoded);
          return TrainingImpartedRecordModel.fromJson(recordMap);
        }
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Error fetching training imparted detail: $e',
      );
    }

    return null;
  }

  /// Create New Training Imparted Record: POST /api/capacity-building/training-imparted
  Future<TrainingImpartedCreateResponse> submitTrainingImparted(
    TrainingImpartedCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointTrainingImparted);

    final hasAttachments =
        request.photos.isNotEmpty ||
        request.documents.isNotEmpty ||
        request.videos.isNotEmpty;

    debugPrint(
      '[CAPACITY_BUILDING_API] POST $uri (hasAttachments: $hasAttachments)',
    );

    try {
      if (hasAttachments) {
        final multipart = http.MultipartRequest('POST', uri);
        if (token != null && token.isNotEmpty) {
          multipart.headers['Authorization'] = 'Bearer $token';
        }
        multipart.headers['Accept'] = 'application/json';

        multipart.fields['training_id'] = request.trainingId.toString();
        multipart.fields['training_date'] = request.trainingDate;

        if (request.organisedBy != null &&
            request.organisedBy!.trim().isNotEmpty) {
          multipart.fields['organised_by'] = request.organisedBy!.trim();
        }
        if (request.duration != null && request.duration!.trim().isNotEmpty) {
          multipart.fields['duration'] = request.duration!.trim();
        }
        if (request.remarks != null && request.remarks!.trim().isNotEmpty) {
          multipart.fields['remarks'] = request.remarks!.trim();
        }
        if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
          multipart.fields['client_ref'] = request.clientRef!.trim();
        }
        if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
          multipart.fields['device_id'] = request.deviceId!.trim();
        }
        if (request.latitude != null) {
          multipart.fields['latitude'] = request.latitude!.toString();
        }
        if (request.longitude != null) {
          multipart.fields['longitude'] = request.longitude!.toString();
        }
        if (request.gpsAccuracyM != null) {
          multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
        }
        if (request.capturedAt != null && request.capturedAt!.trim().isNotEmpty) {
          multipart.fields['captured_at'] = request.capturedAt!.trim();
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

        final streamedResponse = await multipart.send().timeout(
          const Duration(seconds: 45),
        );
        final response = await http.Response.fromStream(streamedResponse);

        debugPrint(
          '[CAPACITY_BUILDING_API] Multipart response status: ${response.statusCode}, body: ${response.body}',
        );

        return _handleImpartedResponse(response);
      } else {
        final headers = ApiConstants.defaultHeaders(token: token);
        final body = jsonEncode(request.toJson());

        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));

        debugPrint(
          '[CAPACITY_BUILDING_API] JSON response status: ${response.statusCode}, body: ${response.body}',
        );

        return _handleImpartedResponse(response);
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Network error submitting training imparted: $e',
      );
      return TrainingImpartedCreateResponse.failure(
        'Unable to connect to server ($e). Please check your internet connection.',
      );
    }
  }

  // =========================================================================
  // 3. TRAINING ATTENDED
  // =========================================================================

  /// Fetch All Training Attended Records: GET /api/capacity-building/training-attended
  Future<List<TrainingAttendedRecordModel>> fetchTrainingAttendedList() async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointTrainingAttended);

    debugPrint(
      '[CAPACITY_BUILDING_API] GET $uri with Bearer: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CAPACITY_BUILDING_API] GET $uri -> status: ${response.statusCode}, length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> itemsList = [];

        if (decoded is Map) {
          if (decoded['data'] is Map && decoded['data']['items'] is List) {
            itemsList = decoded['data']['items'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            itemsList = decoded['data'] as List<dynamic>;
          } else if (decoded['items'] is List) {
            itemsList = decoded['items'] as List<dynamic>;
          }
        } else if (decoded is List) {
          itemsList = decoded;
        }

        return itemsList
            .whereType<Map>()
            .map(
              (item) => TrainingAttendedRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Error fetching training attended list: $e',
      );
    }

    return [];
  }

  /// Fetch Single Training Attended Record: GET /api/capacity-building/training-attended/{id}
  Future<TrainingAttendedRecordModel?> fetchTrainingAttendedDetail(
    int trainingAttendedId,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(
      ApiConstants.endpointTrainingAttendedDetail(trainingAttendedId),
    );

    debugPrint('[CAPACITY_BUILDING_API] GET $uri');

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CAPACITY_BUILDING_API] GET $uri -> status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final recordMap = decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : Map<String, dynamic>.from(decoded);
          return TrainingAttendedRecordModel.fromJson(recordMap);
        }
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Error fetching training attended detail: $e',
      );
    }

    return null;
  }

  /// Create New Training Attended Record: POST /api/capacity-building/training-attended
  Future<TrainingAttendedCreateResponse> submitTrainingAttended(
    TrainingAttendedCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointTrainingAttended);

    final hasAttachments =
        request.photos.isNotEmpty ||
        request.documents.isNotEmpty ||
        request.videos.isNotEmpty;

    debugPrint(
      '[CAPACITY_BUILDING_API] POST $uri (hasAttachments: $hasAttachments)',
    );

    try {
      if (hasAttachments) {
        final multipart = http.MultipartRequest('POST', uri);
        if (token != null && token.isNotEmpty) {
          multipart.headers['Authorization'] = 'Bearer $token';
        }
        multipart.headers['Accept'] = 'application/json';

        multipart.fields['training_id'] = request.trainingId.toString();
        multipart.fields['training_date'] = request.trainingDate;

        if (request.venue != null && request.venue!.trim().isNotEmpty) {
          multipart.fields['venue'] = request.venue!.trim();
        }
        if (request.chairedBy != null && request.chairedBy!.trim().isNotEmpty) {
          multipart.fields['chaired_by'] = request.chairedBy!.trim();
        }
        if (request.keyPoints != null && request.keyPoints!.trim().isNotEmpty) {
          multipart.fields['key_points'] = request.keyPoints!.trim();
        }
        multipart.fields['certificate_issued'] = request.certificateIssued
            .toString();

        if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
          multipart.fields['client_ref'] = request.clientRef!.trim();
        }
        if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
          multipart.fields['device_id'] = request.deviceId!.trim();
        }
        if (request.latitude != null) {
          multipart.fields['latitude'] = request.latitude!.toString();
        }
        if (request.longitude != null) {
          multipart.fields['longitude'] = request.longitude!.toString();
        }
        if (request.gpsAccuracyM != null) {
          multipart.fields['gps_accuracy_m'] = request.gpsAccuracyM.toString();
        }
        if (request.capturedAt != null && request.capturedAt!.trim().isNotEmpty) {
          multipart.fields['captured_at'] = request.capturedAt!.trim();
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

        final streamedResponse = await multipart.send().timeout(
          const Duration(seconds: 45),
        );
        final response = await http.Response.fromStream(streamedResponse);

        debugPrint(
          '[CAPACITY_BUILDING_API] Multipart response status: ${response.statusCode}, body: ${response.body}',
        );

        return _handleAttendedResponse(response);
      } else {
        final headers = ApiConstants.defaultHeaders(token: token);
        final body = jsonEncode(request.toJson());

        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));

        debugPrint(
          '[CAPACITY_BUILDING_API] JSON response status: ${response.statusCode}, body: ${response.body}',
        );

        return _handleAttendedResponse(response);
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Network error submitting training attended: $e',
      );
      return TrainingAttendedCreateResponse.failure(
        'Unable to connect to server ($e). Please check your internet connection.',
      );
    }
  }

  // =========================================================================
  // HELPER RESPONSE HANDLERS
  // =========================================================================

  TrainingImpartedCreateResponse _handleImpartedResponse(
    http.Response response,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return TrainingImpartedCreateResponse.fromJson(decoded);
        } else if (decoded is Map) {
          return TrainingImpartedCreateResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
      return const TrainingImpartedCreateResponse(
        success: true,
        message: 'Training imparted record saved successfully.',
      );
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      try {
        final dynamic errorJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorJson is Map) {
          if (errorJson['detail'] is List) {
            final list = errorJson['detail'] as List;
            if (list.isNotEmpty && list.first is Map) {
              errorMessage = list.first['msg']?.toString() ?? errorMessage;
            }
          } else if (errorJson['detail'] != null) {
            errorMessage = errorJson['detail'].toString();
          } else if (errorJson['message'] != null) {
            errorMessage = errorJson['message'].toString();
          }
        }
      } catch (_) {}
      return TrainingImpartedCreateResponse.failure(errorMessage);
    }
  }

  TrainingAttendedCreateResponse _handleAttendedResponse(
    http.Response response,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return TrainingAttendedCreateResponse.fromJson(decoded);
        } else if (decoded is Map) {
          return TrainingAttendedCreateResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
      return const TrainingAttendedCreateResponse(
        success: true,
        message: 'Training attended record saved successfully.',
      );
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      try {
        final dynamic errorJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorJson is Map) {
          if (errorJson['detail'] is List) {
            final list = errorJson['detail'] as List;
            if (list.isNotEmpty && list.first is Map) {
              errorMessage = list.first['msg']?.toString() ?? errorMessage;
            }
          } else if (errorJson['detail'] != null) {
            errorMessage = errorJson['detail'].toString();
          } else if (errorJson['message'] != null) {
            errorMessage = errorJson['message'].toString();
          }
        }
      } catch (_) {}
      return TrainingAttendedCreateResponse.failure(errorMessage);
    }
  }
}
