// API Service for Sample Support Module
// File: lib/features/sample_reprot/data/sample_support_api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';

import '../domain/sample_support_models.dart';

import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/database/master_data_cache_service.dart';
import 'package:cohv/core/database/offline_outbox_service.dart';

class SampleSupportApiService {
  final http.Client _client;

  SampleSupportApiService({http.Client? client})
      : _client = client ?? AuthenticatedHttpClient.instance;

  /// 1. Fetch Sample Types from GET /api/sample-support/types
  /// Optionally filters by the logged-in volunteer's applicable sector (e.g. 'human', 'animal', 'wildlife', 'environment').
  Future<List<SampleTypeModel>> fetchSampleTypes({String? sectorFilter}) async {
    try {
      final uri = Uri.parse(ApiConstants.endpointSampleSupportTypes);
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[SAMPLE_SUPPORT_API] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is Map && decoded['value'] is List) {
          list = decoded['value'] as List<dynamic>;
        } else {
          list = [];
        }

        final types = list
            .whereType<Map>()
            .map(
              (item) =>
                  SampleTypeModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        if (types.isNotEmpty) {
          if (sectorFilter != null && sectorFilter.trim().isNotEmpty) {
            final filtered = types
                .where((t) => t.isApplicableTo(sectorFilter))
                .toList();
            if (filtered.isNotEmpty) {
              return filtered;
            }
          }
          return types;
        }
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Error fetching sample types: $e');
    }

    // SQLite offline cache fallback
    try {
      final offline = await MasterDataCacheService.instance.getSampleTypes(
        sectorFilter: sectorFilter,
      );
      if (offline.isNotEmpty) return offline;
    } catch (_) {}

    // Graceful offline fallback
    final fallbacks = SampleTypeModel.fallbackTypes();
    if (sectorFilter != null && sectorFilter.trim().isNotEmpty) {
      final filtered = fallbacks
          .where((t) => t.isApplicableTo(sectorFilter))
          .toList();
      if (filtered.isNotEmpty) return filtered;
    }
    return fallbacks;
  }

  /// 2. Fetch Villages for Gram Panchayat
  /// 2. Fetch Villages for Gram Panchayat
  /// Backend supports GET /api/locations/villages?gram_panchayat_lgd_code={code}
  Future<List<VillageModel>> fetchVillagesForPanchayat(
    int? gramPanchayatLgdCode,
  ) async {
    try {
      if (gramPanchayatLgdCode != null && gramPanchayatLgdCode > 0) {
        // Primary: DemographicRepository queries /api/locations/villages?gram_panchayat_lgd_code={code}
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
      debugPrint('[SAMPLE_SUPPORT_API] Primary village fetch error: $e');
    }

    // Secondary fallback: Attempt direct path /api/locations/villages/{gram_panchayat_lgd_code}
    if (gramPanchayatLgdCode != null && gramPanchayatLgdCode > 0) {
      try {
        final directUri = Uri.parse(
          '${ApiConstants.endpointVillages}/$gramPanchayatLgdCode',
        );
        final response = await _client
            .get(directUri, headers: ApiConstants.defaultHeaders())
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(response.body);
          final List<dynamic> list = decoded is List
              ? decoded
              : (decoded is Map && decoded['data'] is List
                    ? decoded['data'] as List<dynamic>
                    : []);
          final parsed = list
              .whereType<Map>()
              .map(
                (item) => VillageModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
          if (parsed.isNotEmpty) {
            await MasterDataCacheService.instance.saveVillages(
              gramPanchayatLgdCode,
              parsed,
            );
            return parsed;
          }
        }
      } catch (e) {
        debugPrint('[SAMPLE_SUPPORT_API] Secondary village fetch error: $e');
      }
    }

    return await MasterDataCacheService.instance.getVillagesForPanchayat(
      gramPanchayatLgdCode,
    );
  }

  /// 3. Fetch Available Departments
  Future<List<String>> fetchDepartments() async {
    try {
      final depts = await DemographicRepository.fetchDepartmentsFromApi(client: _client);
      if (depts.isNotEmpty) {
        final names = depts
            .map((d) => d.departmentName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
        if (names.isNotEmpty) {
          return names;
        }
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Error fetching departments: $e');
    }

    return const [
      'Public Health',
      'Animal Husbandry',
      'Veterinary',
      'Wildlife',
      'Environment',
      'Rural Development',
      'Urban Development',
      'Community / NGO',
    ];
  }

  /// 4. Submit Sample Support Report: POST /api/sample-support
  Future<SampleSupportCreateResponse> submitSampleSupport(
    SampleSupportCreateRequest request, {
    bool allowOfflineFallback = true,
  }) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSampleSupport);

    final hasAttachments =
        request.photos.isNotEmpty ||
        request.videos.isNotEmpty ||
        request.documents.isNotEmpty;

    debugPrint(
      '[SAMPLE_SUPPORT_API] POST $uri (hasAttachments: $hasAttachments, '
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
        multipart.fields['sample_type_id'] = request.sampleTypeId.toString();
        multipart.fields['sample_date'] = request.sampleDate;
        multipart.fields['sample_count'] = request.sampleCount.toString();
        multipart.fields['village_lgd_code'] = request.villageLgdCode.toString();
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
          multipart.fields['accuracy'] = request.gpsAccuracyM.toString();
        }
        if (request.gpsUnavailableReason != null &&
            request.gpsUnavailableReason!.isNotEmpty) {
          multipart.fields['gps_unavailable_reason'] =
              request.gpsUnavailableReason!;
        }
        // multipart.fields['captured_at'] = request.capturedAt;
        // if (request.description != null &&
        //     request.description!.trim().isNotEmpty) {
        //   final desc = request.description!.trim();
        //   multipart.fields['description'] = desc;
        //   multipart.fields['media_caption'] = desc;
        //   multipart.fields['caption'] = desc;
        // }


        // // Attach photos
        // for (final path in request.photos) {
        //   final file = File(path);
        //   if (await file.exists()) {
        //     final fileName = path.split(Platform.pathSeparator).last;
        //     multipart.files.add(
        //       await http.MultipartFile.fromPath('photos', path, filename: fileName),
        //     );
        //   }
        // }

        // // Attach videos
        // for (final path in request.videos) {
        //   final file = File(path);
        //   if (await file.exists()) {
        //     final fileName = path.split(Platform.pathSeparator).last;
        //     multipart.files.add(
        //       await http.MultipartFile.fromPath('videos', path, filename: fileName),
        //     );
        //   }
        // }

      // Stamped Media Files
      for (final path in request.photos) {
        if (path.startsWith('http')) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(Platform.pathSeparator).last;
          multipart.files.add(
            await http.MultipartFile.fromPath('photos', path, filename: fileName),
          );
        }
      }
      for (final path in request.videos) {
        if (path.startsWith('http')) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(Platform.pathSeparator).last;
          multipart.files.add(
            await http.MultipartFile.fromPath('videos', path, filename: fileName),
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

        if (request.removedAttachmentIds.isNotEmpty) {
          multipart.fields['removed_attachment_ids'] = jsonEncode(request.removedAttachmentIds);
        }

        ApiConstants.logRequest(
          module: 'Sample Support',
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
          module: 'Sample Support',
          method: 'POST',
          url: uri,
          body: request.toJson(),
        );

        response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      }

      debugPrint(
        '[SAMPLE_SUPPORT_API] POST $uri -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return SampleSupportCreateResponse.fromJson(decoded);
        } else if (decoded is Map) {
          return SampleSupportCreateResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
        return const SampleSupportCreateResponse(
          success: true,
          message: 'Sample support created successfully.',
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
        return SampleSupportCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint(
        '[SAMPLE_SUPPORT_API] Network error submitting sample support: $e',
      );
      if (allowOfflineFallback && OfflineOutboxService.isNetworkException(e)) {
        return await _saveSampleSupportOffline(request);
      }
      return SampleSupportCreateResponse.failure(
        'Network error: Unable to submit to server ($e)',
      );
    }
  }

  /// Update Sample Support Report: PUT /api/sample-support/{sample_id}
  Future<SampleSupportCreateResponse> updateSampleSupport(
    int sampleId,
    SampleSupportCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSampleSupportDetail(sampleId));

    final hasLocalFiles = request.photos.any((p) =>
            !p.startsWith('http') && !p.startsWith('data:') && File(p).existsSync()) ||
        request.videos.any((v) =>
            !v.startsWith('http') && !v.startsWith('data:') && File(v).existsSync()) ||
        request.documents.any((d) =>
            !d.startsWith('http') && !d.startsWith('data:') && File(d).existsSync());

    debugPrint(
      '[SAMPLE_SUPPORT_API] PUT $uri (sampleId: $sampleId, hasLocalFiles: $hasLocalFiles, removedIds: ${request.removedAttachmentIds})',
    );

    try {
      http.Response response;

      if (hasLocalFiles) {
        final multipart = http.MultipartRequest('PUT', uri);
        if (token != null && token.isNotEmpty) {
          multipart.headers['Authorization'] = 'Bearer $token';
        }
        multipart.headers['Accept'] = 'application/json';

        multipart.fields['volunteer_id'] = request.volunteerId.toString();
        multipart.fields['client_ref'] = request.clientRef;
        multipart.fields['device_id'] = request.deviceId;
        multipart.fields['sample_type_id'] = request.sampleTypeId.toString();
        multipart.fields['sample_date'] = request.sampleDate;
        multipart.fields['sample_count'] = request.sampleCount.toString();
        multipart.fields['village_lgd_code'] = request.villageLgdCode.toString();
        multipart.fields['department'] = jsonEncode(request.department);
        if (request.department.isNotEmpty) {
          multipart.fields['department_name'] = request.department.join(', ');
        }
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
            request.gpsUnavailableReason!.isNotEmpty) {
          multipart.fields['gps_unavailable_reason'] =
              request.gpsUnavailableReason!;
        }
        multipart.fields['captured_at'] = request.capturedAt;
        if (request.description != null &&
            request.description!.trim().isNotEmpty) {
          final desc = request.description!.trim();
          multipart.fields['description'] = desc;
          multipart.fields['media_caption'] = desc;
          multipart.fields['caption'] = desc;
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

        if (request.removedAttachmentIds.isNotEmpty) {
          multipart.fields['removed_attachment_ids'] = jsonEncode(request.removedAttachmentIds);
        }



        ApiConstants.logRequest(
          module: 'Sample Support',
          method: 'PUT',
          url: uri,
          body: multipart.fields,
        );

        final streamed = await multipart.send().timeout(
          const Duration(seconds: 45),
        );
        response = await http.Response.fromStream(streamed);
      } else {
        final headers = ApiConstants.defaultHeaders(token: token);
        final body = jsonEncode(request.toJson());

        ApiConstants.logRequest(
          module: 'Sample Support',
          method: 'PUT',
          url: uri,
          body: request.toJson(),
        );

        response = await _client
            .put(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return SampleSupportCreateResponse.fromJson(decoded);
        } else if (decoded is Map) {
          return SampleSupportCreateResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
        return const SampleSupportCreateResponse(
          success: true,
          message: 'Sample support record updated successfully.',
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
        return SampleSupportCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint(
        '[SAMPLE_SUPPORT_API] Network error updating sample support: $e',
      );
      return SampleSupportCreateResponse.failure(
        'Network error: Unable to update sample support ($e)',
      );
    }
  }

  /// Instant offline loader: retrieves cached sample support records from SQLite and merges
  /// pending outbox items without performing any network call.
  Future<List<SampleSupportRecordModel>> getCachedSampleSupportList({
    String? volunteerId,
  }) async {
    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      List<SampleSupportRecordModel> localRecords = [];

      if (effectiveVolunteerId.isNotEmpty) {
        final cachedRows = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'SAMPLE_SUPPORT',
          volunteerId: effectiveVolunteerId,
        );
        if (cachedRows.isNotEmpty) {
          localRecords = cachedRows
              .map((r) => SampleSupportRecordModel.fromJson(r))
              .toList();
        }
      }

      if (localRecords.isEmpty) {
        final cached = await SessionManager.getSubmittedSampleSupportList();
        if (cached.isNotEmpty) {
          localRecords = cached;
        }
      }

      final pending = await _getPendingSampleSupportFromOutbox();
      return [...pending, ...localRecords];
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Error reading cached sample support: $e');
      return [];
    }
  }

  /// 4. Fetch Sample Support List from GET /api/sample-support/all and GET /api/sample-support
  Future<List<SampleSupportRecordModel>> fetchSampleSupportList({
    int? volunteerId,
  }) async {
    final token = await SessionManager.getToken();
    final headers = ApiConstants.defaultHeaders(token: token);

    // Try GET /api/sample-support/all first, fallback to /api/sample-support
    final urisToTry = [
      Uri.parse(ApiConstants.endpointSampleSupportAll),
      Uri.parse(ApiConstants.endpointSampleSupport),
    ];

    for (final uri in urisToTry) {
      try {
        debugPrint(
          '[SAMPLE_SUPPORT_API] GET $uri with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
        );

        final response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 6));

        debugPrint(
          '[SAMPLE_SUPPORT_API] GET $uri status: ${response.statusCode}, body length: ${response.body.length}',
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

          final records = list
              .whereType<Map>()
              .map(
                (item) => SampleSupportRecordModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();

          if (records.isNotEmpty) {
            await SessionManager.saveSubmittedSampleSupportList(records);
            final session = await SessionManager.getUserSession();
            final volunteerId = session?.volunteerId ?? '';
            if (volunteerId.isNotEmpty) {
              AppDatabase.instance.cacheRecordsList(
                entityType: 'SAMPLE_SUPPORT',
                volunteerId: volunteerId,
                records: records.map((e) => e.toJson()).toList(),
                idExtractor: (m) => m['sample_id']?.toString() ?? '',
              );
            }
          }

          final pending = await _getPendingSampleSupportFromOutbox();
          return [...pending, ...records];
        }
      } catch (e) {
        debugPrint(
          '[SAMPLE_SUPPORT_API] Error fetching sample support from $uri: $e',
        );
      }
    }

    try {
      final session = await SessionManager.getUserSession();
      final volunteerId = session?.volunteerId ?? '';
      final cachedRows = await AppDatabase.instance.getCachedRecordsList(
        entityType: 'SAMPLE_SUPPORT',
        volunteerId: volunteerId,
      );
      final cachedRecords = cachedRows
          .map((r) => SampleSupportRecordModel.fromJson(r))
          .toList();
      final pending = await _getPendingSampleSupportFromOutbox();
      if (cachedRecords.isNotEmpty || pending.isNotEmpty) {
        return [...pending, ...cachedRecords];
      }
    } catch (_) {}

    final cached = await SessionManager.getSubmittedSampleSupportList();
    final pending = await _getPendingSampleSupportFromOutbox();
    if (cached.isNotEmpty || pending.isNotEmpty) {
      return [...pending, ...cached];
    }

    return [];
  }

  /// 5. Fetch Single Sample Support Record from GET /api/sample-support/{sample_id}
  Future<SampleSupportRecordModel?> fetchSampleSupportDetail(
    int sampleId,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSampleSupportDetail(sampleId));

    debugPrint(
      '[SAMPLE_SUPPORT_API] GET $uri with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 6));

      debugPrint(
        '[SAMPLE_SUPPORT_API] GET $uri status: ${response.statusCode}, body: ${response.body}',
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

        final record = SampleSupportRecordModel.fromJson(itemMap);
        await SessionManager.saveSubmittedSampleSupport(record);
        return record;
      }
    } catch (e) {
      debugPrint(
        '[SAMPLE_SUPPORT_API] Error fetching sample support detail ($sampleId): $e',
      );
    }

    // Offline / Network error fallback
    return getCachedSampleSupportDetail(sampleId);
  }

  /// Retrieves a cached SampleSupportRecordModel by numeric ID or clientRef from SQLite or SessionManager
  Future<SampleSupportRecordModel?> getCachedSampleSupportDetail(
    dynamic idOrCode,
  ) async {
    final searchKey = idOrCode.toString();
    final numId = (idOrCode is int) ? idOrCode : int.tryParse(searchKey);

    final list = await getCachedSampleSupportList();
    for (final item in list) {
      if (item.recordCode == searchKey ||
          item.sampleCode == searchKey ||
          (numId != null && item.sampleId == numId)) {
        return item;
      }
    }
    return null;
  }

  /// Maps volunteer designation, COHV type, or department name to sector key:
  /// - 'human' (Public Health)
  /// - 'animal' (Animal Health / Veterinary)
  /// - 'wildlife' (Forest / Wildlife)
  /// - 'environment' (Environment / Pollution Control)
  static String mapDepartmentToSector(String? deptOrSector) {
    if (deptOrSector == null || deptOrSector.trim().isEmpty) return 'human';
    final lower = deptOrSector.toLowerCase().trim();

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
        lower.contains('sanitation') ||
        lower.contains('ulb')) {
      return 'environment';
    }
    if (lower.contains('public health') ||
        lower.contains('health') ||
        lower.contains('human')) {
      return 'human';
    }

    return 'human';
  }

  static List<VillageModel> _fallbackVillages() {
    return const [
      VillageModel(villageName: 'Achampet', villageLgdCode: '580001'),
      VillageModel(villageName: 'Nagarkurnool', villageLgdCode: '580002'),
      VillageModel(villageName: 'Mannanur', villageLgdCode: '580003'),
      VillageModel(villageName: 'Other', villageLgdCode: '999999'),
    ];
  }

  // =========================================================================
  // OFFLINE OUTBOX & LOCAL CACHE HELPERS
  // =========================================================================

  Future<SampleSupportCreateResponse> _saveSampleSupportOffline(
    SampleSupportCreateRequest request,
  ) async {
    try {
      final clientRef = request.clientRef.isNotEmpty
          ? request.clientRef
          : 'SMP-${DateTime.now().millisecondsSinceEpoch}';

      final localId = await OfflineOutboxService.instance.enqueueSubmission(
        entityType: 'SAMPLE_SUPPORT',
        clientRef: clientRef,
        payload: request.toJson(),
        photos: request.photos,
        documents: request.documents,
        videos: request.videos,
      );

      String sampleTypeName = 'Sample #${request.sampleTypeId}';
      try {
        final types = await fetchSampleTypes();
        final matches = types.where((t) => t.sampleTypeId == request.sampleTypeId);
        if (matches.isNotEmpty) sampleTypeName = matches.first.sampleTypeName;
      } catch (_) {}

      final session = await SessionManager.getUserSession();

      return SampleSupportCreateResponse(
        success: true,
        message: 'Saved offline. Record queued for automatic synchronisation.',
        sampleId: -localId,
        sampleCode: clientRef,
        volunteerId: request.volunteerId,
        volunteerName: session?.fullName,
        cohvType: session?.sector,
        sampleTypeId: request.sampleTypeId,
        sampleTypeName: sampleTypeName,
        sampleDate: request.sampleDate,
        sampleCount: request.sampleCount,
        villageLgdCode: request.villageLgdCode,
        verificationStatus: 'PENDING',
        capturedAt: request.capturedAt,
        createdAt: DateTime.now().toIso8601String(),
      );
    } catch (err) {
      debugPrint('[SAMPLE_SUPPORT_API] Offline save failed: $err');
      return SampleSupportCreateResponse.failure('Offline save failed: $err');
    }
  }

  Future<List<SampleSupportRecordModel>> _getPendingSampleSupportFromOutbox() async {
    try {
      final pendingRows = await OfflineOutboxService.instance
          .getPendingByEntity('SAMPLE_SUPPORT');
      if (pendingRows.isEmpty) return [];

      final types = await fetchSampleTypes();
      final typeMap = {for (final t in types) t.sampleTypeId: t.sampleTypeName};
      final session = await SessionManager.getUserSession();

      return pendingRows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String)
            as Map<String, dynamic>;
        final typeId = payload['sample_type_id'] is int
            ? payload['sample_type_id'] as int
            : int.tryParse(payload['sample_type_id']?.toString() ?? '0') ?? 0;
        final typeName = typeMap[typeId] ?? 'Sample #$typeId';
        final clientRef = row['client_ref']?.toString() ?? 'PENDING';
        final rowId = row['id'] as int? ?? 0;

        List<String> parseList(dynamic raw) {
          if (raw is List) return raw.map((e) => e.toString()).toList();
          return [];
        }

        return SampleSupportRecordModel(
          sampleId: -rowId,
          sampleCode: clientRef,
          volunteerId: session?.numericVolunteerId,
          volunteerName: session?.fullName,
          cohvType: session?.sector,
          sampleTypeId: typeId,
          sampleTypeName: typeName,
          sampleDate: payload['sample_date']?.toString() ?? '',
          sampleCount: payload['sample_count'] is int
              ? payload['sample_count'] as int
              : int.tryParse(payload['sample_count']?.toString() ?? '1') ?? 1,
          villageLgdCode: payload['village_lgd_code'] is int
              ? payload['village_lgd_code'] as int
              : int.tryParse(payload['village_lgd_code']?.toString() ?? ''),
          verificationStatus: 'PENDING',
          syncStatus: 'pending',
          capturedAt: payload['captured_at']?.toString(),
          createdAt: row['created_at']?.toString(),
          description: payload['description']?.toString(),
          photos: parseList(payload['photos']),
          videos: parseList(payload['videos']),
          documents: parseList(payload['documents']),
        );
      }).toList();
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Error reading pending outbox: $e');
      return [];
    }
  }
}
