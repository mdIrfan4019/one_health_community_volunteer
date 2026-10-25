// API Service for Sample Support Module
// File: lib/features/sample_reprot/data/sample_support_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../domain/sample_support_models.dart';

class SampleSupportApiService {
  final http.Client _client;

  SampleSupportApiService({http.Client? client})
      : _client = client ?? http.Client();

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

    debugPrint(
      '[SAMPLE_SUPPORT_API] POST $uri with payload: ${jsonEncode(request.toJson())}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
      final body = jsonEncode(request.toJson());

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

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

  /// 4. Fetch Sample Support List from GET /api/sample-support
  Future<List<SampleSupportRecordModel>> fetchSampleSupportList({
    int? volunteerId,
  }) async {
    final token = await SessionManager.getToken();
    final uri = Uri.parse(ApiConstants.endpointSampleSupport);

    debugPrint(
      '[SAMPLE_SUPPORT_API] GET $uri with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final headers = ApiConstants.defaultHeaders(token: token);
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
      debugPrint('[SAMPLE_SUPPORT_API] Error fetching sample support list: $e');
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
