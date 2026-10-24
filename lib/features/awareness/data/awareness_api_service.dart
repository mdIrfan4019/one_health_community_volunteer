import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/awareness_models.dart';

class AwarenessApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointAwarenessActivityTypes =
      ApiConstants.endpointAwarenessActivityTypes;
  static const String endpointAwarenessTopics =
      ApiConstants.endpointAwarenessTopics;
  static const String endpointDepartments = ApiConstants.endpointDepartments;
  static const String endpointAwarenessAll = ApiConstants.endpointAwarenessAll;

  final http.Client _client;
  final SyncRepository _syncRepository;

  AwarenessApiService({
    http.Client? client,
    SyncRepository? syncRepository,
  })  : _client = client ?? http.Client(),
        _syncRepository = syncRepository ?? SyncRepository();

  /// Fetch logged-in volunteer's user session
  Future<UserSession?> getLoggedInUserSession() async {
    return await SessionManager.getUserSession();
  }

  /// 1. Fetch Activity Types: GET /api/awareness-activities/activity-types
  Future<List<AwarenessActivityTypeModel>> fetchActivityTypes({
    String? filterSector,
  }) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointAwarenessActivityTypes);
    debugPrint('[AWARENESS_API] GET $url');

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AWARENESS_API] /activity-types status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final allTypes = decoded
              .whereType<Map>()
              .map(
                (item) => AwarenessActivityTypeModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();

          if (filterSector != null && filterSector.trim().isNotEmpty) {
            final targetSector = filterSector.trim().toLowerCase();
            return allTypes.where((act) {
              if (act.applicableSectors.isEmpty) return true;
              return act.applicableSectors.any(
                (sec) => sec.toLowerCase() == targetSector,
              );
            }).toList();
          }

          return allTypes;
        }
      }
    } catch (e) {
      debugPrint('[AWARENESS_API] Error fetching activity types: $e');
    }
    return [];
  }

  /// 2. Fetch Topics: GET /api/awareness-activities/topics
  Future<List<AwarenessTopicModel>> fetchTopics() async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointAwarenessTopics);
    debugPrint('[AWARENESS_API] GET $url');

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AWARENESS_API] /topics status: ${response.statusCode}, body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => AwarenessTopicModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AWARENESS_API] Error fetching topics: $e');
    }
    return [];
  }

  /// 3. Fetch Departments: GET /api/departments
  Future<List<DepartmentModel>> fetchDepartments() async {
    return await DemographicRepository.fetchDepartmentsFromApi(client: _client);
  }

  /// 4. Fetch Villages for Gram Panchayat:
  /// GET /api/locations/villages?gram_panchayat_lgd_code={code}
  Future<List<VillageModel>> fetchVillagesForPanchayat(
    int gramPanchayatLgdCode,
  ) async {
    return await DemographicRepository.fetchVillagesFromApi(
      gramPanchayatLgdCode.toString(),
    );
  }

  /// Helper to resolve COHV type / sector to sector key (e.g. human, animal, wildlife, environment)
  static String mapCohvTypeToSector(String? cohvType) {
    if (cohvType == null || cohvType.trim().isEmpty) return 'human';
    final lower = cohvType.toLowerCase().trim();
    if (lower.contains('public health') ||
        lower.contains('health') ||
        lower.contains('human')) {
      return 'human';
    }
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
        lower.contains('sanitation')) {
      return 'environment';
    }
    return 'human';
  }

  /// Resolves logged-in volunteer profile, sector key, and GP LGD code
  Future<VolunteerSessionInfo> getVolunteerSessionInfo({
    String? fallbackVolunteerId,
  }) async {
    final detailed = await SessionManager.getDetailedProfile();
    final session = await SessionManager.getUserSession();

    final volunteerId = (detailed?.volunteerId.isNotEmpty == true)
        ? detailed!.volunteerId
        : (session?.volunteerId.isNotEmpty == true
            ? session!.volunteerId
            : (fallbackVolunteerId ?? 'COHV-26-0005'));

    final cohvType = (detailed?.cohvType != null &&
            detailed!.cohvType!.trim().isNotEmpty)
        ? detailed.cohvType!.trim()
        : (detailed?.departmentName != null &&
                detailed!.departmentName!.trim().isNotEmpty)
            ? detailed.departmentName!.trim()
            : (session?.sector != null && session!.sector.trim().isNotEmpty)
                ? session.sector.trim()
                : 'Public Health Department';

    final gpCode = detailed?.gramPanchayatLgdCode ?? session?.gramPanchayatLgdCode;
    final gpName = detailed?.panchayat ?? session?.gramPanchayatName ?? 'Amrabad';
    final villageLgdCode = detailed?.villageLgdCode ?? session?.villageLgdCode;
    final villageName = detailed?.village ?? session?.villageName ?? 'Mannanur';
    final blockName = detailed?.block ?? session?.blockName ?? 'Amrabad';
    final districtName = detailed?.district ?? session?.districtName ?? 'Nagarkurnool';
    final stateName = detailed?.state ?? session?.stateName ?? 'Telangana';

    final sectorKey = mapCohvTypeToSector(cohvType);

    return VolunteerSessionInfo(
      volunteerCode: volunteerId,
      cohvType: cohvType,
      sectorKey: sectorKey,
      gramPanchayatLgdCode: gpCode,
      gramPanchayatName: gpName,
      villageLgdCode: villageLgdCode,
      villageName: villageName,
      blockName: blockName,
      districtName: districtName,
      stateName: stateName,
    );
  }

  /// Fetch list of awareness activities
  Future<List<AwarenessItem>> getAwarenessList(String volunteerId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Initial record
    return [
      AwarenessItem(
        id: 'AWR-26-0006',
        activityType: 'Village meetings',
        date: DateTime(2026, 10, 13),
        village: 'Amrabad',
        peopleReached: 45,
        topicCovered: 'Sanitation and waste disposal',
        departmentInvolved: 'Multi-Sectoral Joint Team',
        status: 'synced',
        latitude: 28.60928,
        longitude: 77.367449,
        accuracy: 133,
        volunteerId: volunteerId,
        deviceId: 'DEV-C0YBZ9WK',
      ),
    ];
  }

  /// Create and submit a new awareness activity
  Future<AwarenessItem> createAwareness(AwarenessItem item) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Automatically enqueue into local offline Sync Repository
    await _syncRepository.enqueueRecord(
      entityType: 'AWR',
      payload: item.toJson(),
    );

    return item;
  }
}
