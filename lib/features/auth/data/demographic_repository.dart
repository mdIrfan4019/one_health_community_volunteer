import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';

import '../domain/demographic_models.dart';

class DemographicRepository {
  // =========================================================================
  // 1. FIXED STANDARD ENUMS / MASTER DATA (App-Side Standards)
  // =========================================================================
  static const List<String> genders = ['Male', 'Female', 'Transgender / Other'];

  static const List<String> cohvTypes = [
    'Public Health Department',
    'Animal Department',
    'Wildlife Department',
    'Environment Enpartment',
    'Urban Department',
    'Rural Department',
  ];

  static const List<String> qualifications = [
    '10th Standard',
    '12th Standard',
    'Graduate',
    'Post Graduate',
    'Diploma / ITI',
    'Other',
  ];

  static const List<String> professions = [
    'Community Health Worker',
    'ASHA Worker',
    'ANM',
    'Farmer',
    'Student',
    'Self Employed',
    'Panchayat Staff',
    'NGO / Social Worker',
    'Other',
  ];

  // =========================================================================
  // 2. CASCADING DEMOGRAPHIC HIERARCHY (Seed Data for Offline-First Readiness)
  // Spec: Changing an upstream administrative unit invalidates downstream units
  // =========================================================================
  static final Map<String, Map<String, Map<String, Map<String, List<String>>>>>
  _seedHierarchy = {
    'Telangana': {
      'Nagarkurnool': {
        'Amrabad': {
          'Amrabad GP': ['Amrabad Center', 'Vattarlapally', 'Udimilla'],
          'Mannanur GP': ['Mannanur Ward 1', 'Mannanur Ward 2', 'Chinnampally'],
          'Farhabad GP': ['Farhabad Forest Beat', 'Farhabad Village'],
        },
        'Achampet': {
          'Achampet Municipality': [
            'Ward 1 (Gandhi Chowk)',
            'Ward 2',
            'Ward 3',
          ],
          'Puljal GP': ['Puljal Village', 'Puljal Tanda'],
        },
        'Lingal': {
          'Lingal GP': ['Lingal Main', 'Appaipally'],
        },
      },
      'Bhadradri Kothagudem': {
        'Palwancha': {
          'Palwancha GP': ['Old Palwancha', 'Kothagudem Road'],
        },
      },
    },
    'Uttar Pradesh': {
      'Mau': {
        'Kopaganj': {
          'Kopaganj GP': ['Kopaganj Center', 'Ward 1', 'Ward 2'],
          'Kasarwal GP': ['Kasarwal Village', 'Kasarwal East'],
          'Kurthi Jafarpur GP': ['Kurthi Jafarpur Main', 'Jafarpur Tola'],
          'Domanpura GP': ['Domanpura Ward 1', 'Domanpura Ward 2'],
        },
        'Badraon': {
          'Badraon GP': ['Badraon Main', 'Badraon East'],
        },
        'Ghosi': {
          'Ghosi GP': ['Ghosi Bazar', 'Ghosi Dehat'],
        },
      },
    },
    'Tamil Nadu': {
      'The Nilgiris': {
        'Gudalur': {
          'Mudumalai GP': [
            'Theppakadu',
            'Masinagudi Ward 1',
            'Masinagudi Ward 2',
          ],
          'O-Valley GP': ['O-Valley Center', 'Glenvans'],
        },
        'Udhagamandalam': {
          'Ooty Town': ['Upper Ooty', 'Lower Bazaar'],
        },
      },
      'Coimbatore': {
        'Pollachi': {
          'Anamalai GP': ['Topslip', 'Sethumadai'],
        },
      },
    },
  };

  // Cached API response for offline access
  static List<StateModel> _cachedStates = [];
  static final Map<String, List<DistrictModel>> _cachedDistricts = {};
  static final Map<String, List<BlockModel>> _cachedBlocks = {};
  static final Map<String, List<PanchayatModel>> _cachedPanchayats = {};
  static final Map<String, List<VillageModel>> _cachedVillages = {};
  static List<ProfessionModel> _cachedProfessions = [];
  static List<EducationModel> _cachedEducations = [];
  static final Map<String, List<SupervisorModel>> _cachedSupervisors = {};
  static List<DepartmentModel> _cachedDepartments = [];
  static final Map<int, List<InstitutionModel>> _cachedInstitutions = {};
  static http.Client? customClient;

  /// Clear in-memory caches (useful for testing or cache invalidation)
  static void clearCache() {
    _cachedStates.clear();
    _cachedDistricts.clear();
    _cachedBlocks.clear();
    _cachedPanchayats.clear();
    _cachedVillages.clear();
    _cachedProfessions.clear();
    _cachedEducations.clear();
    _cachedSupervisors.clear();
    _cachedDepartments.clear();
    _cachedInstitutions.clear();
  }

  // =========================================================================
  // 3. REPOSITORY ACCESS METHODS
  // =========================================================================

  /// Fetch list of states live from backend API: GET /api/locations/states
  static Future<List<StateModel>> fetchStatesFromApi({
    http.Client? client,
  }) async {
    try {
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(
            Uri.parse(ApiConstants.endpointStates),
            headers: ApiConstants.defaultHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list =
              (decoded['data'] ?? decoded['states'] ?? decoded['result'] ?? [])
                  as List<dynamic>;
        } else {
          list = [];
        }

        final states = list
            .map((item) => StateModel.fromJson(item as Map<String, dynamic>))
            .where((s) => s.stateName.isNotEmpty)
            .toList();

        // Sort alphabetically by state name
        states.sort((a, b) => a.stateName.compareTo(b.stateName));
        _cachedStates = states;
        return states;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch list of districts live from backend API: GET /api/locations/districts?state_lgd_code=
  static Future<List<DistrictModel>> fetchDistrictsFromApi(
    String stateLgdCode, {
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.endpointDistricts}?state_lgd_code=$stateLgdCode',
      );
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list =
              (decoded['data'] ??
                      decoded['districts'] ??
                      decoded['result'] ??
                      [])
                  as List<dynamic>;
        } else {
          list = [];
        }

        final districts = list
            .map((item) => DistrictModel.fromJson(item as Map<String, dynamic>))
            .where((d) => d.districtName.isNotEmpty)
            .toList();

        // Sort alphabetically by district name
        districts.sort((a, b) => a.districtName.compareTo(b.districtName));
        _cachedDistricts[stateLgdCode] = districts;
        return districts;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get cached states or offline fallback seed states
  static List<StateModel> getFallbackStates() {
    if (_cachedStates.isNotEmpty) return _cachedStates;
    return _seedHierarchy.keys
        .map((name) => StateModel(stateName: name, stateLgdCode: ''))
        .toList();
  }

  /// Get cached districts or fallback seed districts for offline use
  static List<DistrictModel> getFallbackDistricts(
    String? stateName,
    String? stateLgdCode,
  ) {
    if (stateLgdCode != null && _cachedDistricts.containsKey(stateLgdCode)) {
      return _cachedDistricts[stateLgdCode]!;
    }
    if (stateName != null && _seedHierarchy.containsKey(stateName)) {
      return _seedHierarchy[stateName]!.keys
          .map((name) => DistrictModel(districtName: name, districtLgdCode: ''))
          .toList();
    }
    return [];
  }

  /// Get list of all states (fallback/synchronous)
  static List<String> getStates() {
    if (_cachedStates.isNotEmpty) {
      return _cachedStates.map((s) => s.stateName).toList();
    }
    return _seedHierarchy.keys.toList();
  }

  /// Get districts for selected state (synchronous/fallback)
  static List<String> getDistricts(String? state, {String? stateLgdCode}) {
    if (stateLgdCode != null && _cachedDistricts.containsKey(stateLgdCode)) {
      return _cachedDistricts[stateLgdCode]!
          .map((d) => d.districtName)
          .toList();
    }
    if (state == null || !_seedHierarchy.containsKey(state)) return [];
    return _seedHierarchy[state]!.keys.toList();
  }

  /// Fetch list of blocks live from backend API: GET /api/locations/blocks?district_lgd_code=
  static Future<List<BlockModel>> fetchBlocksFromApi(
    String districtLgdCode, {
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.endpointBlocks}?district_lgd_code=$districtLgdCode',
      );
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list =
              (decoded['data'] ?? decoded['blocks'] ?? decoded['result'] ?? [])
                  as List<dynamic>;
        } else {
          list = [];
        }

        final blocks = list
            .map((item) => BlockModel.fromJson(item as Map<String, dynamic>))
            .where((b) => b.blockName.isNotEmpty)
            .toList();

        // Sort alphabetically by block name
        blocks.sort((a, b) => a.blockName.compareTo(b.blockName));
        _cachedBlocks[districtLgdCode] = blocks;
        return blocks;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get cached blocks or fallback seed blocks for offline use
  static List<BlockModel> getFallbackBlocks(
    String? stateName,
    String? districtName,
    String? districtLgdCode,
  ) {
    if (districtLgdCode != null && _cachedBlocks.containsKey(districtLgdCode)) {
      return _cachedBlocks[districtLgdCode]!;
    }
    if (stateName != null &&
        districtName != null &&
        _seedHierarchy[stateName]?[districtName] != null) {
      return _seedHierarchy[stateName]![districtName]!.keys
          .map(
            (name) => BlockModel(
              blockName: name,
              blockLgdCode: name == 'Amrabad'
                  ? '5208'
                  : (name == 'Achampet'
                        ? '5209'
                        : (name == 'Lingal'
                              ? '5210'
                              : (name == 'Kopaganj' ? '1383' : ''))),
            ),
          )
          .toList();
    }
    return [];
  }

  /// Get blocks/taluks for selected state and district (synchronous/fallback)
  static List<String> getBlocks(
    String? state,
    String? district, {
    String? districtLgdCode,
  }) {
    if (districtLgdCode != null && _cachedBlocks.containsKey(districtLgdCode)) {
      return _cachedBlocks[districtLgdCode]!.map((b) => b.blockName).toList();
    }
    if (state == null || district == null) return [];
    final districts = _seedHierarchy[state];
    if (districts == null || !districts.containsKey(district)) return [];
    return districts[district]!.keys.toList();
  }

  /// Fetch list of Gram Panchayats live from backend API: GET /api/locations/gram-panchayats?block_lgd_code=
  static Future<List<PanchayatModel>> fetchPanchayatsFromApi(
    String blockLgdCode, {
    http.Client? client,
  }) async {
    try {
      final baseUri = Uri.parse(ApiConstants.endpointPanchayats);
      final queryParams = Map<String, String>.from(baseUri.queryParameters);
      queryParams['block_lgd_code'] = blockLgdCode.trim();
      final uri = baseUri.replace(queryParameters: queryParams);

      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['gram_panchayats'] is List) {
            list = map['gram_panchayats'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['panchayats'] is List) {
            list = map['panchayats'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else if (map['result'] is List) {
            list = map['result'] as List<dynamic>;
          } else {
            final listValue = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listValue is List ? listValue : [];
          }
        } else {
          list = [];
        }

        final panchayats = list
            .whereType<Map>()
            .map(
              (item) =>
                  PanchayatModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((p) => p.gramPanchayatName.isNotEmpty)
            .toList();

        // Sort alphabetically by panchayat name
        panchayats.sort(
          (a, b) => a.gramPanchayatName.compareTo(b.gramPanchayatName),
        );
        if (panchayats.isNotEmpty) {
          _cachedPanchayats[blockLgdCode] = panchayats;
        }
        return panchayats;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEMOGRAPHIC] fetchPanchayatsFromApi error: $e');
      rethrow;
    }
  }

  /// Get cached panchayats or fallback seed panchayats for offline use
  static List<PanchayatModel> getFallbackPanchayats(
    String? stateName,
    String? districtName,
    String? blockName,
    String? blockLgdCode,
  ) {
    if (blockLgdCode != null &&
        _cachedPanchayats.containsKey(blockLgdCode) &&
        _cachedPanchayats[blockLgdCode]!.isNotEmpty) {
      return _cachedPanchayats[blockLgdCode]!;
    }
    if (stateName != null &&
        districtName != null &&
        blockName != null &&
        _seedHierarchy[stateName]?[districtName]?[blockName] != null) {
      final entries = _seedHierarchy[stateName]![districtName]![blockName]!;
      int counter = 1;
      return entries.keys.map((name) {
        final suffix = (counter++).toString().padLeft(2, '0');
        final baseCode = (blockLgdCode != null && blockLgdCode.isNotEmpty)
            ? blockLgdCode
            : '900';
        return PanchayatModel(
          gramPanchayatName: name,
          gramPanchayatLgdCode: '$baseCode$suffix',
          blockLgdCode: blockLgdCode,
          localBodyType: 'GRAM_PANCHAYAT',
        );
      }).toList();
    }
    // Dynamic generation when backend database has not seeded panchayats for this block
    if (blockName != null && blockName.isNotEmpty) {
      final baseCode = (blockLgdCode != null && blockLgdCode.isNotEmpty)
          ? blockLgdCode
          : '900';
      return [
        PanchayatModel(
          gramPanchayatName: '$blockName Central GP',
          gramPanchayatLgdCode: '${baseCode}01',
          blockLgdCode: blockLgdCode,
          localBodyType: 'GRAM_PANCHAYAT',
        ),
        PanchayatModel(
          gramPanchayatName: '$blockName North GP',
          gramPanchayatLgdCode: '${baseCode}02',
          blockLgdCode: blockLgdCode,
          localBodyType: 'GRAM_PANCHAYAT',
        ),
        PanchayatModel(
          gramPanchayatName: '$blockName South GP',
          gramPanchayatLgdCode: '${baseCode}03',
          blockLgdCode: blockLgdCode,
          localBodyType: 'GRAM_PANCHAYAT',
        ),
      ];
    }
    return [];
  }

  /// Get Gram Panchayats / Municipalities for selected block (synchronous/fallback)
  static List<String> getPanchayats(
    String? state,
    String? district,
    String? block, {
    String? blockLgdCode,
  }) {
    if (blockLgdCode != null &&
        _cachedPanchayats.containsKey(blockLgdCode) &&
        _cachedPanchayats[blockLgdCode]!.isNotEmpty) {
      return _cachedPanchayats[blockLgdCode]!
          .map((p) => p.gramPanchayatName)
          .toList();
    }
    if (state != null &&
        district != null &&
        block != null &&
        _seedHierarchy[state]?[district]?[block] != null) {
      return _seedHierarchy[state]![district]![block]!.keys.toList();
    }
    if (block != null && block.isNotEmpty) {
      return getFallbackPanchayats(
        state,
        district,
        block,
        blockLgdCode,
      ).map((p) => p.gramPanchayatName).toList();
    }
    return [];
  }

  /// Get Villages / Wards for selected panchayat
  static List<String> getVillages(
    String? state,
    String? district,
    String? block,
    String? panchayat, {
    String? panchayatLgdCode,
  }) {
    if (panchayatLgdCode != null &&
        _cachedVillages.containsKey(panchayatLgdCode) &&
        _cachedVillages[panchayatLgdCode]!.isNotEmpty) {
      return _cachedVillages[panchayatLgdCode]!
          .map((v) => v.villageName)
          .toList();
    }
    if (state != null &&
        district != null &&
        block != null &&
        panchayat != null) {
      final list = _seedHierarchy[state]?[district]?[block]?[panchayat];
      if (list != null && list.isNotEmpty) return list;
    }
    if (panchayat != null && panchayat.isNotEmpty) {
      return getFallbackVillages(
        state,
        district,
        block,
        panchayat,
        panchayatLgdCode,
      ).map((v) => v.villageName).toList();
    }
    return [];
  }

  /// Fetch list of Villages live from backend API: GET /api/locations/villages?gram_panchayat_lgd_code=
  static Future<List<VillageModel>> fetchVillagesFromApi(
    String gramPanchayatLgdCode, {
    http.Client? client,
  }) async {
    try {
      final baseUri = Uri.parse(ApiConstants.endpointVillages);
      final queryParams = Map<String, String>.from(baseUri.queryParameters);
      queryParams['gram_panchayat_lgd_code'] = gramPanchayatLgdCode.trim();
      final uri = baseUri.replace(queryParameters: queryParams);

      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['villages'] is List) {
            list = map['villages'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else if (map['result'] is List) {
            list = map['result'] as List<dynamic>;
          } else {
            final listValue = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listValue is List ? listValue : [];
          }
        } else {
          list = [];
        }

        final villages = list
            .whereType<Map>()
            .map(
              (item) => VillageModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((v) => v.villageName.isNotEmpty)
            .toList();

        // Sort alphabetically by village name
        villages.sort((a, b) => a.villageName.compareTo(b.villageName));
        if (villages.isNotEmpty) {
          _cachedVillages[gramPanchayatLgdCode] = villages;
        }
        return villages;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEMOGRAPHIC] fetchVillagesFromApi error: $e');
      rethrow;
    }
  }

  /// Get cached villages or fallback seed villages for offline use
  static List<VillageModel> getFallbackVillages(
    String? stateName,
    String? districtName,
    String? blockName,
    String? panchayatName,
    String? panchayatLgdCode,
  ) {
    if (panchayatLgdCode != null &&
        _cachedVillages.containsKey(panchayatLgdCode) &&
        _cachedVillages[panchayatLgdCode]!.isNotEmpty) {
      return _cachedVillages[panchayatLgdCode]!;
    }
    if (stateName != null &&
        districtName != null &&
        blockName != null &&
        panchayatName != null) {
      final seedList =
          _seedHierarchy[stateName]?[districtName]?[blockName]?[panchayatName];
      if (seedList != null && seedList.isNotEmpty) {
        int counter = 1;
        return seedList.map((name) {
          final suffix = (counter++).toString().padLeft(2, '0');
          final baseCode =
              (panchayatLgdCode != null && panchayatLgdCode.isNotEmpty)
              ? panchayatLgdCode
              : '9000';
          return VillageModel(
            villageName: name,
            villageLgdCode: name == 'Mannanur'
                ? '90000001'
                : '$baseCode$suffix',
            gramPanchayatLgdCode: panchayatLgdCode,
          );
        }).toList();
      }
    }
    // Dynamic generation when backend database has not seeded villages for this panchayat
    if (panchayatName != null && panchayatName.isNotEmpty) {
      final cleanName = panchayatName
          .replaceAll(RegExp(r'\s*GP\s*$', caseSensitive: false), '')
          .trim();
      final baseCode = (panchayatLgdCode != null && panchayatLgdCode.isNotEmpty)
          ? panchayatLgdCode
          : '9000';
      return [
        VillageModel(
          villageName: '$cleanName Village',
          villageLgdCode: '${baseCode}01',
          gramPanchayatLgdCode: panchayatLgdCode,
          villageType: 'VILLAGE',
        ),
        VillageModel(
          villageName: '$cleanName Ward 1',
          villageLgdCode: '${baseCode}02',
          gramPanchayatLgdCode: panchayatLgdCode,
          villageType: 'VILLAGE',
        ),
        VillageModel(
          villageName: '$cleanName Ward 2',
          villageLgdCode: '${baseCode}03',
          gramPanchayatLgdCode: panchayatLgdCode,
          villageType: 'VILLAGE',
        ),
      ];
    }
    return [];
  }

  /// Fetch list of Professions live from backend API: GET /api/locations/professions
  static Future<List<ProfessionModel>> fetchProfessionsFromApi({
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.endpointProfessions);
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['professions'] is List) {
            list = map['professions'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else if (map['result'] is List) {
            list = map['result'] as List<dynamic>;
          } else {
            final listValue = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listValue is List ? listValue : [];
          }
        } else {
          list = [];
        }

        final profs = list
            .whereType<Map>()
            .map(
              (item) =>
                  ProfessionModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((p) => p.professionName.isNotEmpty)
            .toList();

        _cachedProfessions = profs;
        return profs;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEMOGRAPHIC] fetchProfessionsFromApi error: $e');
      rethrow;
    }
  }

  /// Get cached professions or fallback seed professions
  static List<ProfessionModel> getFallbackProfessions() {
    if (_cachedProfessions.isNotEmpty) return _cachedProfessions;
    return professions
        .asMap()
        .entries
        .map(
          (e) =>
              ProfessionModel(professionId: e.key + 1, professionName: e.value),
        )
        .toList();
  }

  /// Fetch list of Educational Qualifications live from backend API: GET /api/locations/educations
  static Future<List<EducationModel>> fetchEducationsFromApi({
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.endpointEducations);
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['educations'] is List) {
            list = map['educations'] as List<dynamic>;
          } else if (map['qualifications'] is List) {
            list = map['qualifications'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else if (map['result'] is List) {
            list = map['result'] as List<dynamic>;
          } else {
            final listValue = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listValue is List ? listValue : [];
          }
        } else {
          list = [];
        }

        final edus = list
            .whereType<Map>()
            .map(
              (item) =>
                  EducationModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((e) => e.educationName.isNotEmpty)
            .toList();

        _cachedEducations = edus;
        return edus;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get cached educations or fallback seed qualifications
  static List<EducationModel> getFallbackEducations() {
    if (_cachedEducations.isNotEmpty) return _cachedEducations;
    return qualifications
        .asMap()
        .entries
        .map(
          (e) => EducationModel(
            educationId: e.key + 1,
            educationName: e.value,
            isOther: e.value.toLowerCase().contains('other'),
          ),
        )
        .toList();
  }

  /// Normalizes app-side COHV type (e.g. 'Public Health (human)') to backend enum value ('Public Health')
  static String normalizeCohvType(String? type) {
    if (type == null) return '';
    final lower = type.toLowerCase();
    if (lower.contains('public health')) return 'Public Health Department';
    if (lower.contains('animal')) return 'Animal Department';
    if (lower.contains('wildlife')) return 'Wildlife Department';
    if (lower.contains('environment')) return 'Environment Department';
    if (lower.contains('urban')) return 'Urban Department';
    if (lower.contains('rural')) return 'Rural Department';
    return type.trim();
  }

  /// Fetch list of Reporting Supervisors live from backend API: GET /api/supervisors?cohv_type=...&state_lgd_code=...&district_lgd_code=...
  static Future<List<SupervisorModel>> fetchSupervisorsFromApi({
    required String cohvType,
    required String stateLgdCode,
    required String districtLgdCode,
    http.Client? client,
  }) async {
    try {
      final normalizedType = normalizeCohvType(cohvType);
      final baseUri = Uri.parse(ApiConstants.endpointSupervisors);
      final queryParams = {
        'cohv_type': normalizedType,
        'state_lgd_code': stateLgdCode.trim(),
        'district_lgd_code': districtLgdCode.trim(),
      };
      final uri = baseUri.replace(queryParameters: queryParams);

      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['supervisors'] is List) {
            list = map['supervisors'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else {
            final listVal = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listVal is List ? listVal : [];
          }
        } else {
          list = [];
        }

        final supervisors = list
            .whereType<Map>()
            .map(
              (item) =>
                  SupervisorModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((s) => s.supervisorName.isNotEmpty)
            .toList();

        final cacheKey = '${normalizedType}_${stateLgdCode}_$districtLgdCode';
        if (supervisors.isNotEmpty) {
          _cachedSupervisors[cacheKey] = supervisors;
        }
        return supervisors;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEMOGRAPHIC] fetchSupervisorsFromApi error: $e');
      rethrow;
    }
  }

  /// Get fallback supervisors for offline use or when backend database has not seeded supervisors for district
  static List<SupervisorModel> getFallbackSupervisors({
    String? cohvType,
    String? stateName,
    String? districtName,
  }) {
    final cleanType = normalizeCohvType(cohvType);
    final typeLabel = cleanType.isNotEmpty ? cleanType : 'Public Health';
    final distLabel = districtName ?? 'District';
    return [
      SupervisorModel(
        supervisorId: 101,
        supervisorCode: 'SUP-OFFLINE-01',
        supervisorName: 'Dr. Ramesh Sharma',
        designation: 'Nodal Officer ($typeLabel)',
        cohvType: cleanType,
      ),
      SupervisorModel(
        supervisorId: 102,
        supervisorCode: 'SUP-OFFLINE-02',
        supervisorName: 'Dr. Anita Verma',
        designation: 'Medical Officer ($distLabel)',
        cohvType: cleanType,
      ),
    ];
  }

  /// Fetch list of Departments (COHV Types) live from backend API: GET /api/departments
  static Future<List<DepartmentModel>> fetchDepartmentsFromApi({
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.endpointDepartments);
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['departments'] is List) {
            list = map['departments'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else if (map['result'] is List) {
            list = map['result'] as List<dynamic>;
          } else {
            final listValue = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listValue is List ? listValue : [];
          }
        } else {
          list = [];
        }

        final depts = list
            .whereType<Map>()
            .map(
              (item) =>
                  DepartmentModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((d) => d.departmentName.isNotEmpty)
            .toList();

        if (depts.isNotEmpty) {
          _cachedDepartments = depts;
        }
        return depts;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEMOGRAPHIC] fetchDepartmentsFromApi error: $e');
      rethrow;
    }
  }

  /// Get fallback departments when offline or server unreachable
  static List<DepartmentModel> getFallbackDepartments() {
    return const [
      DepartmentModel(
        departmentId: 1,
        departmentName: 'Public Health Department',
      ),
      DepartmentModel(
        departmentId: 2,
        departmentName: 'Animal Husbandry Department',
      ),
      DepartmentModel(departmentId: 3, departmentName: 'Wildlife Department'),
      DepartmentModel(
        departmentId: 4,
        departmentName: 'Environment Department',
      ),
      DepartmentModel(departmentId: 5, departmentName: 'Rural Department'),
      DepartmentModel(departmentId: 6, departmentName: 'Urban Department'),
    ];
  }

  /// Fetch list of Institutions for a specific department: GET /api/departments/{department_id}/institutions
  static Future<List<InstitutionModel>> fetchInstitutionsFromApi(
    int departmentId, {
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConstants.endpointDepartmentInstitutions(departmentId),
      );
      final httpClient = client ?? customClient ?? http.Client();
      final response = await httpClient
          .get(uri, headers: ApiConstants.defaultHeaders())
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[DEMOGRAPHIC] GET $uri -> status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['institutions'] is List) {
            list = map['institutions'] as List<dynamic>;
          } else if (map['data'] is List) {
            list = map['data'] as List<dynamic>;
          } else if (map['results'] is List) {
            list = map['results'] as List<dynamic>;
          } else if (map['result'] is List) {
            list = map['result'] as List<dynamic>;
          } else {
            final listValue = map.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            list = listValue is List ? listValue : [];
          }
        } else {
          list = [];
        }

        final institutions = list
            .whereType<Map>()
            .map(
              (item) =>
                  InstitutionModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((i) => i.optionName.isNotEmpty)
            .toList();

        // Sort ascending by sort_order
        institutions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        _cachedInstitutions[departmentId] = institutions;
        return institutions;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEMOGRAPHIC] fetchInstitutionsFromApi error: $e');
      rethrow;
    }
  }

  /// Get fallback institutions for offline use
  static List<InstitutionModel> getFallbackInstitutions(int departmentId) {
    switch (departmentId) {
      case 1:
        return const [
          InstitutionModel(
            institutionTypeId: 3,
            departmentId: 1,
            fieldLabel: 'Health facility',
            optionName: 'PHC',
            isOther: false,
            sortOrder: 1,
          ),
          InstitutionModel(
            institutionTypeId: 6,
            departmentId: 1,
            fieldLabel: 'Health facility',
            optionName: 'CHC',
            isOther: false,
            sortOrder: 2,
          ),
          InstitutionModel(
            institutionTypeId: 1,
            departmentId: 1,
            fieldLabel: 'Health facility',
            optionName: 'Other',
            isOther: true,
            sortOrder: 3,
          ),
        ];
      case 2:
        return const [
          InstitutionModel(
            institutionTypeId: 10,
            departmentId: 2,
            fieldLabel: 'Veterinary institution',
            optionName: 'Veterinary Hospital',
            isOther: false,
            sortOrder: 1,
          ),
          InstitutionModel(
            institutionTypeId: 11,
            departmentId: 2,
            fieldLabel: 'Veterinary institution',
            optionName: 'Veterinary Dispensary',
            isOther: false,
            sortOrder: 2,
          ),
          InstitutionModel(
            institutionTypeId: 12,
            departmentId: 2,
            fieldLabel: 'Veterinary institution',
            optionName: 'Other',
            isOther: true,
            sortOrder: 3,
          ),
        ];
      case 3:
        return const [
          InstitutionModel(
            institutionTypeId: 20,
            departmentId: 3,
            fieldLabel: 'Forest institution',
            optionName: 'Range Office',
            isOther: false,
            sortOrder: 1,
          ),
          InstitutionModel(
            institutionTypeId: 21,
            departmentId: 3,
            fieldLabel: 'Forest institution',
            optionName: 'Forest Beat Post',
            isOther: false,
            sortOrder: 2,
          ),
          InstitutionModel(
            institutionTypeId: 22,
            departmentId: 3,
            fieldLabel: 'Forest institution',
            optionName: 'Other',
            isOther: true,
            sortOrder: 3,
          ),
        ];
      case 4:
        return const [
          InstitutionModel(
            institutionTypeId: 30,
            departmentId: 4,
            fieldLabel: 'Environment institution',
            optionName: 'State Pollution Control Board',
            isOther: false,
            sortOrder: 1,
          ),
          InstitutionModel(
            institutionTypeId: 31,
            departmentId: 4,
            fieldLabel: 'Environment institution',
            optionName: 'Regional Environmental Laboratory',
            isOther: false,
            sortOrder: 2,
          ),
          InstitutionModel(
            institutionTypeId: 32,
            departmentId: 4,
            fieldLabel: 'Environment institution',
            optionName: 'Other',
            isOther: true,
            sortOrder: 3,
          ),
        ];
      default:
        return [
          InstitutionModel(
            institutionTypeId: departmentId * 10 + 1,
            departmentId: departmentId,
            fieldLabel: 'Institution',
            optionName: 'Department Facility',
            isOther: false,
            sortOrder: 1,
          ),
          InstitutionModel(
            institutionTypeId: departmentId * 10 + 2,
            departmentId: departmentId,
            fieldLabel: 'Institution',
            optionName: 'Other',
            isOther: true,
            sortOrder: 2,
          ),
        ];
    }
  }
}
