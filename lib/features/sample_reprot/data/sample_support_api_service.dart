// API Service for Sample Support Module
// File: lib/features/sample_reprot/data/sample_support_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
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
