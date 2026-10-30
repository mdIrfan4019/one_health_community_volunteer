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

class SampleSupportApiService {
  final http.Client _client;

  SampleSupportApiService({http.Client? client})
      : _client = client ?? AuthenticatedHttpClient.instance;

  /// 1. Fetch Sample Types from GET /api/sample-support/types
  /// Optionally filters by the logged-in volunteer's applicable sector (e.g. 'human', 'animal', 'wildlife', 'environment').
  Future<List<SampleTypeModel>> fetchSampleTypes({
    String? sectorFilter,
  }) async {
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
            final filtered =
                types.where((t) => t.isApplicableTo(sectorFilter)).toList();
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

    // Graceful offline fallback
    final fallbacks = SampleTypeModel.fallbackTypes();
    if (sectorFilter != null && sectorFilter.trim().isNotEmpty) {
      final filtered =
          fallbacks.where((t) => t.isApplicableTo(sectorFilter)).toList();
      if (filtered.isNotEmpty) return filtered;
    }
    return fallbacks;
  }

  /// 2. Fetch Villages for Gram Panchayat
  /// Backend supports GET /api/locations/villages?gram_panchayat_lgd_code={code}
  Future<List<VillageModel>> fetchVillagesForPanchayat(
    int? gramPanchayatLgdCode,
  ) async {
    if (gramPanchayatLgdCode == null || gramPanchayatLgdCode <= 0) {
      return _fallbackVillages();
    }

    try {
      // Primary: DemographicRepository queries /api/locations/villages?gram_panchayat_lgd_code={code}
      final villages = await DemographicRepository.fetchVillagesFromApi(
        gramPanchayatLgdCode.toString(),
      );
      if (villages.isNotEmpty) {
        return villages;
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Primary village fetch error: $e');
    }

    // Secondary fallback: Attempt direct path /api/locations/villages/{gram_panchayat_lgd_code}
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
              (item) =>
                  VillageModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Secondary village fetch error: $e');
    }

    return _fallbackVillages();
  }

  /// 3. Submit Sample Support Report: POST /api/sample-support
  Future<SampleSupportCreateResponse> submitSampleSupport(
    SampleSupportCreateRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSampleSupport);

    final hasAttachments = request.photos.isNotEmpty ||
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
          multipart.fields['latitude'] =
              GeoLocationData.formatCoordinateString(request.latitude)!;
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
              await http.MultipartFile.fromPath('documents', path, filename: fileName),
            );
          }
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
            errorMessage = errorJson['detail']?.toString() ??
                errorJson['message']?.toString() ??
                errorMessage;
          }
        } catch (_) {}
        return SampleSupportCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Network error submitting sample support: $e');
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

    final hasAttachments = request.photos.any((p) => !p.startsWith('http')) ||
        request.videos.any((v) => !v.startsWith('http')) ||
        request.documents.any((d) => !d.startsWith('http'));

    debugPrint(
      '[SAMPLE_SUPPORT_API] PUT $uri (sampleId: $sampleId, hasAttachments: $hasAttachments)',
    );

    try {
      http.Response response;

      if (hasAttachments) {
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
              await http.MultipartFile.fromPath('photos', path, filename: fileName),
            );
          }
        }

        for (final path in request.videos) {
          final file = File(path);
          if (await file.exists()) {
            final fileName = path.split(Platform.pathSeparator).last;
            multipart.files.add(
              await http.MultipartFile.fromPath('videos', path, filename: fileName),
            );
          }
        }

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
          module: 'Sample Support',
          method: 'PUT',
          url: uri,
          body: multipart.fields,
        );

        final streamed = await multipart.send().timeout(const Duration(seconds: 45));
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
            errorMessage = errorJson['detail']?.toString() ??
                errorJson['message']?.toString() ??
                errorMessage;
          }
        } catch (_) {}
        return SampleSupportCreateResponse.failure(errorMessage);
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_API] Network error updating sample support: $e');
      return SampleSupportCreateResponse.failure(
        'Network error: Unable to update sample support ($e)',
      );
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
            .timeout(const Duration(seconds: 15));

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
              .map((item) =>
                  SampleSupportRecordModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          if (records.isNotEmpty) {
            await SessionManager.saveSubmittedSampleSupportList(records);
          }

          return records;
        }
      } catch (e) {
        debugPrint('[SAMPLE_SUPPORT_API] Error fetching sample support from $uri: $e');
      }
    }

    final cached = await SessionManager.getSubmittedSampleSupportList();
    if (cached.isNotEmpty) {
      return cached;
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
          .timeout(const Duration(seconds: 15));

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
      debugPrint('[SAMPLE_SUPPORT_API] Error fetching sample support detail ($sampleId): $e');
    }

    final cached = await SessionManager.getSubmittedSampleSupportList();
    for (final item in cached) {
      if (item.sampleId == sampleId) {
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
      VillageModel(
        villageName: 'Achampet',
        villageLgdCode: '580001',
      ),
      VillageModel(
        villageName: 'Nagarkurnool',
        villageLgdCode: '580002',
      ),
      VillageModel(
        villageName: 'Mannanur',
        villageLgdCode: '580003',
      ),
      VillageModel(
        villageName: 'Other',
        villageLgdCode: '999999',
      ),
    ];
  }
}
