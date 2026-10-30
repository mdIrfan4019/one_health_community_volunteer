// API Service for Capacity Building Module
// File: lib/features/capacity_building/data/capacity_building_api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/database/master_data_cache_service.dart';
import 'package:cohv/core/database/offline_outbox_service.dart';

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
          // Persist to SQLite in background for offline use
          AppDatabase.instance.saveMasterLookupBatch(
            category: MasterDataCacheService.categoryTrainingMasters,
            items: types.map((e) => e.toJson()).toList(),
            keyExtractor: (m) => m['training_id']?.toString() ?? '',
          );
          return types;
        }
      }
    } catch (e) {
      debugPrint('[CAPACITY_BUILDING_API] Error fetching training masters: $e');
    }

    // Graceful offline fallback from SQLite
    try {
      final cached = await MasterDataCacheService.instance.getTrainingMasters();
      if (cached.isNotEmpty) {
        return cached;
      }
    } catch (_) {}

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

        final liveList = itemsList
            .whereType<Map>()
            .map(
              (item) => TrainingImpartedRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        // Cache live records in SQLite
        final session = await SessionManager.getUserSession();
        final volunteerId = session?.volunteerId ?? '';
        if (liveList.isNotEmpty && volunteerId.isNotEmpty) {
          AppDatabase.instance.cacheRecordsList(
            entityType: 'TRAINING_IMPARTED',
            volunteerId: volunteerId,
            records: liveList.map((e) => e.toJson()).toList(),
            idExtractor: (m) => m['training_imparted_id']?.toString() ?? '',
          );
        }

        final pending = await _getPendingImpartedFromOutbox();
        return [...pending, ...liveList];
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Error fetching training imparted list: $e',
      );
    }

    // Graceful offline fallback from SQLite
    try {
      final session = await SessionManager.getUserSession();
      final volunteerId = session?.volunteerId ?? '';
      final cachedRows = await AppDatabase.instance.getCachedRecordsList(
        entityType: 'TRAINING_IMPARTED',
        volunteerId: volunteerId,
      );
      final cachedRecords = cachedRows
          .map((r) => TrainingImpartedRecordModel.fromJson(r))
          .toList();
      final pending = await _getPendingImpartedFromOutbox();
      return [...pending, ...cachedRecords];
    } catch (_) {}

    return await _getPendingImpartedFromOutbox();
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
    TrainingImpartedCreateRequest request, {
    bool allowOfflineFallback = true,
  }) async {
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
        if (request.caption != null && request.caption!.trim().isNotEmpty) {
          final cap = request.caption!.trim();
          multipart.fields['caption'] = cap;
          multipart.fields['media_caption'] = cap;
          multipart.fields['description'] = cap;
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
        if (request.capturedAt != null &&
            request.capturedAt!.trim().isNotEmpty) {
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

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Imparted',
          method: 'POST',
          url: uri,
          body: multipart.fields,
        );

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

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Imparted',
          method: 'POST',
          url: uri,
          body: request.toJson(),
        );

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
      if (allowOfflineFallback && OfflineOutboxService.isNetworkException(e)) {
        return await _saveTrainingImpartedOffline(request);
      }
      return TrainingImpartedCreateResponse.failure(
        'Unable to connect to server ($e). Please check your internet connection.',
      );
    }
  }

  // =========================================================================
  /// Update Training Imparted Record: PUT /api/capacity-building/training-imparted/{training_imparted_id}
  Future<TrainingImpartedCreateResponse> updateTrainingImparted(
    int trainingImpartedId,
    TrainingImpartedCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(
      ApiConstants.endpointTrainingImpartedDetail(trainingImpartedId),
    );

    debugPrint(
      '[CAPACITY_BUILDING_API] PUT $uri (update training imparted $trainingImpartedId)',
    );

    try {
      final hasLocalFiles =
          request.photos.any((p) => !p.startsWith('http')) ||
          request.documents.any((d) => !d.startsWith('http')) ||
          request.videos.any((v) => !v.startsWith('http'));

      if (hasLocalFiles) {
        final multipart = http.MultipartRequest('PUT', uri);
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
        if (request.caption != null && request.caption!.trim().isNotEmpty) {
          final cap = request.caption!.trim();
          multipart.fields['caption'] = cap;
          multipart.fields['media_caption'] = cap;
          multipart.fields['description'] = cap;
        }
        if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
          multipart.fields['client_ref'] = request.clientRef!.trim();
        }
        if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
          multipart.fields['device_id'] = request.deviceId!.trim();
        }

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

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Imparted',
          method: 'PUT',
          url: uri,
          body: multipart.fields,
        );

        final streamedResponse = await multipart.send().timeout(
          const Duration(seconds: 45),
        );
        final response = await http.Response.fromStream(streamedResponse);
        return _handleImpartedResponse(response);
      } else {
        final headers = ApiConstants.defaultHeaders(token: token);
        final body = jsonEncode(request.toJson());

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Imparted',
          method: 'PUT',
          url: uri,
          body: request.toJson(),
        );

        final response = await _client
            .put(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));

        return _handleImpartedResponse(response);
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Network error updating training imparted: $e',
      );
      return TrainingImpartedCreateResponse.failure(
        'Unable to connect to server ($e). Please check your internet connection.',
      );
    }
  }

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

        final liveList = itemsList
            .whereType<Map>()
            .map(
              (item) => TrainingAttendedRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        // Cache live records in SQLite
        final session = await SessionManager.getUserSession();
        final volunteerId = session?.volunteerId ?? '';
        if (liveList.isNotEmpty && volunteerId.isNotEmpty) {
          AppDatabase.instance.cacheRecordsList(
            entityType: 'TRAINING_ATTENDED',
            volunteerId: volunteerId,
            records: liveList.map((e) => e.toJson()).toList(),
            idExtractor: (m) => m['training_attended_id']?.toString() ?? '',
          );
        }

        final pending = await _getPendingAttendedFromOutbox();
        return [...pending, ...liveList];
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Error fetching training attended list: $e',
      );
    }

    // Graceful offline fallback from SQLite
    try {
      final session = await SessionManager.getUserSession();
      final volunteerId = session?.volunteerId ?? '';
      final cachedRows = await AppDatabase.instance.getCachedRecordsList(
        entityType: 'TRAINING_ATTENDED',
        volunteerId: volunteerId,
      );
      final cachedRecords = cachedRows
          .map((r) => TrainingAttendedRecordModel.fromJson(r))
          .toList();
      final pending = await _getPendingAttendedFromOutbox();
      return [...pending, ...cachedRecords];
    } catch (_) {}

    return await _getPendingAttendedFromOutbox();
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
    TrainingAttendedCreateRequest request, {
    bool allowOfflineFallback = true,
  }) async {
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
        if (request.caption != null && request.caption!.trim().isNotEmpty) {
          final cap = request.caption!.trim();
          multipart.fields['caption'] = cap;
          multipart.fields['media_caption'] = cap;
          multipart.fields['description'] = cap;
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
        if (request.capturedAt != null &&
            request.capturedAt!.trim().isNotEmpty) {
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

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Attended',
          method: 'POST',
          url: uri,
          body: multipart.fields,
        );

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

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Attended',
          method: 'POST',
          url: uri,
          body: request.toJson(),
        );

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
      if (allowOfflineFallback && OfflineOutboxService.isNetworkException(e)) {
        return await _saveTrainingAttendedOffline(request);
      }
      return TrainingAttendedCreateResponse.failure(
        'Unable to connect to server ($e). Please check your internet connection.',
      );
    }
  }

  // =========================================================================
  /// Update Training Attended Record: PUT /api/capacity-building/training-attended/{training_attended_id}
  Future<TrainingAttendedCreateResponse> updateTrainingAttended(
    int trainingAttendedId,
    TrainingAttendedCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(
      ApiConstants.endpointTrainingAttendedDetail(trainingAttendedId),
    );

    debugPrint(
      '[CAPACITY_BUILDING_API] PUT $uri (update training attended $trainingAttendedId)',
    );

    try {
      final hasLocalFiles =
          request.photos.any((p) => !p.startsWith('http')) ||
          request.documents.any((d) => !d.startsWith('http')) ||
          request.videos.any((v) => !v.startsWith('http'));

      if (hasLocalFiles) {
        final multipart = http.MultipartRequest('PUT', uri);
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
        if (request.caption != null && request.caption!.trim().isNotEmpty) {
          final cap = request.caption!.trim();
          multipart.fields['caption'] = cap;
          multipart.fields['media_caption'] = cap;
          multipart.fields['description'] = cap;
        }
        multipart.fields['certificate_issued'] = request.certificateIssued
            ? '1'
            : '0';
        if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
          multipart.fields['client_ref'] = request.clientRef!.trim();
        }
        if (request.deviceId != null && request.deviceId!.trim().isNotEmpty) {
          multipart.fields['device_id'] = request.deviceId!.trim();
        }

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

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Attended',
          method: 'PUT',
          url: uri,
          body: multipart.fields,
        );

        final streamedResponse = await multipart.send().timeout(
          const Duration(seconds: 45),
        );
        final response = await http.Response.fromStream(streamedResponse);
        return _handleAttendedResponse(response);
      } else {
        final headers = ApiConstants.defaultHeaders(token: token);
        final body = jsonEncode(request.toJson());

        ApiConstants.logRequest(
          module: 'Capacity Building - Training Attended',
          method: 'PUT',
          url: uri,
          body: request.toJson(),
        );

        final response = await _client
            .put(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));

        return _handleAttendedResponse(response);
      }
    } catch (e) {
      debugPrint(
        '[CAPACITY_BUILDING_API] Network error updating training attended: $e',
      );
      return TrainingAttendedCreateResponse.failure(
        'Unable to connect to server ($e). Please check your internet connection.',
      );
    }
  }

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

  // =========================================================================
  // OFFLINE OUTBOX & LOCAL CACHE HELPERS
  // =========================================================================

  Future<TrainingImpartedCreateResponse> _saveTrainingImpartedOffline(
    TrainingImpartedCreateRequest request,
  ) async {
    try {
      final clientRef = request.clientRef ??
          'TRN-IMP-${DateTime.now().millisecondsSinceEpoch}';

      final localId = await OfflineOutboxService.instance.enqueueSubmission(
        entityType: 'TRAINING_IMPARTED',
        clientRef: clientRef,
        payload: request.toJson(),
        photos: request.photos,
        documents: request.documents,
        videos: request.videos,
      );

      String trainingName = 'Training #${request.trainingId}';
      try {
        final masters = await MasterDataCacheService.instance.getTrainingMasters();
        final matches = masters.where((m) => m.trainingId == request.trainingId);
        if (matches.isNotEmpty) trainingName = matches.first.trainingName;
      } catch (_) {}

      final syntheticRecord = TrainingImpartedRecordModel(
        trainingImpartedId: -localId,
        trainingImpartedCode: clientRef,
        volunteerId: int.tryParse(request.deviceId ?? ''),
        clientRef: clientRef,
        deviceId: request.deviceId,
        trainingId: request.trainingId,
        trainingName: trainingName,
        trainingDate: request.trainingDate,
        organisedBy: request.organisedBy,
        duration: request.duration,
        remarks: request.remarks,
        caption: request.caption,
        verificationStatus: 'PENDING',
        createdAt: DateTime.now().toIso8601String(),
        latitude: request.latitude,
        longitude: request.longitude,
        gpsAccuracyM: request.gpsAccuracyM,
        photos: request.photos,
        documents: request.documents,
        videos: request.videos,
      );

      return TrainingImpartedCreateResponse(
        success: true,
        message: 'Saved offline. Record queued for automatic synchronisation.',
        record: syntheticRecord,
      );
    } catch (err) {
      debugPrint('[CAPACITY_BUILDING_API] Offline save failed: $err');
      return TrainingImpartedCreateResponse.failure('Offline save failed: $err');
    }
  }

  Future<TrainingAttendedCreateResponse> _saveTrainingAttendedOffline(
    TrainingAttendedCreateRequest request,
  ) async {
    try {
      final clientRef = request.clientRef ??
          'TRN-ATT-${DateTime.now().millisecondsSinceEpoch}';

      final localId = await OfflineOutboxService.instance.enqueueSubmission(
        entityType: 'TRAINING_ATTENDED',
        clientRef: clientRef,
        payload: request.toJson(),
        photos: request.photos,
        documents: request.documents,
        videos: request.videos,
      );

      String trainingName = 'Training #${request.trainingId}';
      try {
        final masters = await MasterDataCacheService.instance.getTrainingMasters();
        final matches = masters.where((m) => m.trainingId == request.trainingId);
        if (matches.isNotEmpty) trainingName = matches.first.trainingName;
      } catch (_) {}

      final syntheticRecord = TrainingAttendedRecordModel(
        trainingAttendedId: -localId,
        trainingAttendedCode: clientRef,
        volunteerId: int.tryParse(request.deviceId ?? ''),
        clientRef: clientRef,
        deviceId: request.deviceId,
        trainingId: request.trainingId,
        trainingName: trainingName,
        trainingDate: request.trainingDate,
        venue: request.venue,
        chairedBy: request.chairedBy,
        keyPoints: request.keyPoints,
        caption: request.caption,
        certificateIssued: request.certificateIssued,
        verificationStatus: 'PENDING',
        createdAt: DateTime.now().toIso8601String(),
        latitude: request.latitude,
        longitude: request.longitude,
        gpsAccuracyM: request.gpsAccuracyM,
        photos: request.photos,
        documents: request.documents,
        videos: request.videos,
      );

      return TrainingAttendedCreateResponse(
        success: true,
        message: 'Saved offline. Record queued for automatic synchronisation.',
        record: syntheticRecord,
      );
    } catch (err) {
      debugPrint('[CAPACITY_BUILDING_API] Offline save failed: $err');
      return TrainingAttendedCreateResponse.failure('Offline save failed: $err');
    }
  }

  Future<List<TrainingImpartedRecordModel>> _getPendingImpartedFromOutbox() async {
    try {
      final pendingRows = await OfflineOutboxService.instance
          .getPendingByEntity('TRAINING_IMPARTED');
      if (pendingRows.isEmpty) return [];

      final masters = await MasterDataCacheService.instance.getTrainingMasters();
      final masterMap = {for (final m in masters) m.trainingId: m.trainingName};

      return pendingRows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String)
            as Map<String, dynamic>;
        final trainingId = payload['training_id'] is int
            ? payload['training_id'] as int
            : int.tryParse(payload['training_id']?.toString() ?? '0') ?? 0;
        final trainingName = masterMap[trainingId] ?? 'Training #$trainingId';
        final clientRef = row['client_ref']?.toString() ?? 'PENDING';
        final rowId = row['id'] as int? ?? 0;

        List<String> parseList(dynamic raw) {
          if (raw is List) return raw.map((e) => e.toString()).toList();
          return [];
        }

        return TrainingImpartedRecordModel(
          trainingImpartedId: -rowId,
          trainingImpartedCode: clientRef,
          clientRef: clientRef,
          trainingId: trainingId,
          trainingName: trainingName,
          trainingDate: payload['training_date']?.toString() ?? '',
          organisedBy: payload['organised_by']?.toString(),
          duration: payload['duration']?.toString(),
          remarks: payload['remarks']?.toString(),
          caption: payload['caption']?.toString() ??
              payload['description']?.toString(),
          verificationStatus: 'PENDING',
          createdAt: row['created_at']?.toString(),
          photos: parseList(payload['photos']),
          documents: parseList(payload['documents']),
          videos: parseList(payload['videos']),
        );
      }).toList();
    } catch (e) {
      debugPrint('[CAPACITY_BUILDING_API] Error reading pending imparted outbox: $e');
      return [];
    }
  }

  Future<List<TrainingAttendedRecordModel>> _getPendingAttendedFromOutbox() async {
    try {
      final pendingRows = await OfflineOutboxService.instance
          .getPendingByEntity('TRAINING_ATTENDED');
      if (pendingRows.isEmpty) return [];

      final masters = await MasterDataCacheService.instance.getTrainingMasters();
      final masterMap = {for (final m in masters) m.trainingId: m.trainingName};

      return pendingRows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String)
            as Map<String, dynamic>;
        final trainingId = payload['training_id'] is int
            ? payload['training_id'] as int
            : int.tryParse(payload['training_id']?.toString() ?? '0') ?? 0;
        final trainingName = masterMap[trainingId] ?? 'Training #$trainingId';
        final clientRef = row['client_ref']?.toString() ?? 'PENDING';
        final rowId = row['id'] as int? ?? 0;

        List<String> parseList(dynamic raw) {
          if (raw is List) return raw.map((e) => e.toString()).toList();
          return [];
        }

        return TrainingAttendedRecordModel(
          trainingAttendedId: -rowId,
          trainingAttendedCode: clientRef,
          clientRef: clientRef,
          trainingId: trainingId,
          trainingName: trainingName,
          trainingDate: payload['training_date']?.toString() ?? '',
          venue: payload['venue']?.toString(),
          chairedBy: payload['chaired_by']?.toString(),
          keyPoints: payload['key_points']?.toString(),
          caption: payload['caption']?.toString() ??
              payload['description']?.toString(),
          certificateIssued: payload['certificate_issued'] == true ||
              payload['certificate_issued'] == 'true' ||
              payload['certificate_issued'] == '1',
          verificationStatus: 'PENDING',
          createdAt: row['created_at']?.toString(),
          photos: parseList(payload['photos']),
          documents: parseList(payload['documents']),
          videos: parseList(payload['videos']),
        );
      }).toList();
    } catch (e) {
      debugPrint('[CAPACITY_BUILDING_API] Error reading pending attended outbox: $e');
      return [];
    }
  }
}
