import 'package:flutter/foundation.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/capacity_building/data/capacity_building_api_service.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';
import 'package:cohv/features/dashboard/data/dashboard_api_service.dart';
import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/profile/data/profile_api_service.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/data/success_story_api_service.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';

import 'app_database.dart';

/// Central Master Data Synchronizer and Offline Provider.
/// Pre-caches all dropdown options from existing backend GET endpoints into SQLite
/// so that all form screens function seamlessly with zero internet connection.
class MasterDataCacheService {
  static const String categoryTrainingMasters = 'TRAINING_MASTERS';
  static const String categoryAwarenessActivityTypes =
      'AWARENESS_ACTIVITY_TYPES';
  static const String categoryAwarenessTopics = 'AWARENESS_TOPICS';
  static const String categorySampleTypes = 'SAMPLE_TYPES';
  static const String categorySuccessStoryDepartments =
      'SUCCESS_STORY_DEPARTMENTS';
  static const String categoryReferralFacilities = 'REFERRAL_FACILITIES';

  static final MasterDataCacheService instance =
      MasterDataCacheService._internal();
  MasterDataCacheService._internal();

  final AppDatabase _db = AppDatabase.instance;
  bool _isSyncing = false;

  /// Downloads all master dropdown data concurrently using existing GET endpoints
  /// and saves the responses into SQLite. Safe to call on app startup or post-login.
  Future<void> syncAllMasterData() async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint(
      '[MASTER_CACHE] Starting background sync of all master data to SQLite...',
    );

    try {
      await _db.cleanCorruptLookups();
      await Future.wait([
        _syncTrainingMasters(),
        _syncAwarenessTypesAndTopics(),
        _syncSampleTypes(),
        _syncSuccessStoryDepartments(),
        _syncReferralFacilities(),
        _syncVolunteerProfile(),
        _syncDashboardMetrics(),
        _syncModuleListings(),
      ]);
      debugPrint(
        '[MASTER_CACHE] All master data, volunteer profile, dashboard metrics, and module listings successfully synced to SQLite.',
      );
    } catch (e) {
      debugPrint('[MASTER_CACHE] Error during master data background sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncVolunteerProfile() async {
    try {
      await ProfileApiService().getDetailedProfile();
    } catch (e) {
      debugPrint('[MASTER_CACHE] Volunteer profile pre-sync error: $e');
    }
  }

  Future<void> _syncDashboardMetrics() async {
    try {
      await DashboardApiService().getDashboardMetrics();
    } catch (e) {
      debugPrint('[MASTER_CACHE] Dashboard metrics pre-sync error: $e');
    }
  }

  Future<void> _syncModuleListings() async {
    try {
      await Future.wait([
        EventApiService().fetchEventReports().then((_) => null).catchError((_) => null),
        ReferralsApiService().getReferrals().then((_) => null).catchError((_) => null),
        AwarenessApiService().getAwarenessList().then((_) => null).catchError((_) => null),
        SampleSupportApiService().fetchSampleSupportList().then((_) => null).catchError((_) => null),
        CapacityBuildingApiService().fetchTrainingImpartedList().then((_) => null).catchError((_) => null),
        CapacityBuildingApiService().fetchTrainingAttendedList().then((_) => null).catchError((_) => null),
        SuccessStoryApiService().fetchSuccessStoriesList().then((_) => null).catchError((_) => null),
      ]);
    } catch (e) {
      debugPrint('[MASTER_CACHE] Module listings pre-sync error: $e');
    }
  }

  // =========================================================================
  // 1. TRAINING MASTERS
  // =========================================================================

  Future<void> _syncTrainingMasters() async {
    try {
      final items = await CapacityBuildingApiService().fetchTrainingMasters();
      if (items.isNotEmpty) {
        await _db.saveMasterLookupBatch(
          category: categoryTrainingMasters,
          items: items.map((e) => e.toJson()).toList(),
          keyExtractor: (m) => m['training_id']?.toString() ?? '',
        );
      }
    } catch (e) {
      debugPrint('[MASTER_CACHE] Training masters sync error: $e');
    }
  }

  Future<List<TrainingMasterModel>> getTrainingMasters() async {
    final cached = await _db.getMasterLookupList(categoryTrainingMasters);
    if (cached.isNotEmpty) {
      return cached.map((m) => TrainingMasterModel.fromJson(m)).toList();
    }
    return TrainingMasterModel.fallbackTypes();
  }

  // =========================================================================
  // 2. AWARENESS ACTIVITIES & TOPICS
  // =========================================================================

  Future<void> _syncAwarenessTypesAndTopics() async {
    try {
      final types = await AwarenessApiService().fetchActivityTypes();
      if (types.isNotEmpty) {
        await _db.saveMasterLookupBatch(
          category: categoryAwarenessActivityTypes,
          items: types.map((e) => e.toJson()).toList(),
          keyExtractor: (m) =>
              m['awareness_activity_id']?.toString() ??
              m['id']?.toString() ??
              '',
        );
      }

      final topics = await AwarenessApiService().fetchTopics();
      if (topics.isNotEmpty) {
        await _db.saveMasterLookupBatch(
          category: categoryAwarenessTopics,
          items: topics.map((e) => e.toJson()).toList(),
          keyExtractor: (m) =>
              m['awareness_topic_id']?.toString() ??
              m['topic_id']?.toString() ??
              '',
        );
      }
    } catch (e) {
      debugPrint('[MASTER_CACHE] Awareness sync error: $e');
    }
  }

  Future<List<AwarenessActivityTypeModel>> getAwarenessActivityTypes() async {
    final cached = await _db.getMasterLookupList(
      categoryAwarenessActivityTypes,
    );
    if (cached.isNotEmpty) {
      final list =
          cached.map((m) => AwarenessActivityTypeModel.fromJson(m)).toList();
      if (list.length > 1 || (list.length == 1 && !list.first.isOther)) {
        return list;
      }
    }
    return AwarenessActivityTypeModel.fallbackTypes();
  }

  Future<List<AwarenessTopicModel>> getAwarenessTopics() async {
    final cached = await _db.getMasterLookupList(categoryAwarenessTopics);
    if (cached.isNotEmpty) {
      final list = cached.map((m) => AwarenessTopicModel.fromJson(m)).toList();
      if (list.length > 1 || (list.length == 1 && !list.first.isOther)) {
        return list;
      }
    }
    return AwarenessTopicModel.fallbackTopics();
  }

  // =========================================================================
  // 3. SAMPLE TYPES
  // =========================================================================

  Future<void> _syncSampleTypes() async {
    try {
      final types = await SampleSupportApiService().fetchSampleTypes();
      if (types.isNotEmpty) {
        await _db.saveMasterLookupBatch(
          category: categorySampleTypes,
          items: types.map((e) => e.toJson()).toList(),
          keyExtractor: (m) =>
              m['sample_type_id']?.toString() ??
              m['id']?.toString() ??
              '',
        );
      }
    } catch (e) {
      debugPrint('[MASTER_CACHE] Sample types sync error: $e');
    }
  }

  Future<List<SampleTypeModel>> getSampleTypes({String? sectorFilter}) async {
    final cached = await _db.getMasterLookupList(categorySampleTypes);
    if (cached.isNotEmpty) {
      final list = cached.map((m) => SampleTypeModel.fromJson(m)).toList();
      if (list.length > 1 || (list.length == 1 && !list.first.isOther)) {
        if (sectorFilter != null && sectorFilter.trim().isNotEmpty) {
          final filtered =
              list.where((t) => t.isApplicableTo(sectorFilter)).toList();
          if (filtered.isNotEmpty) return filtered;
        }
        return list;
      }
    }
    final fallbacks = SampleTypeModel.fallbackTypes();
    if (sectorFilter != null && sectorFilter.trim().isNotEmpty) {
      final filtered =
          fallbacks.where((t) => t.isApplicableTo(sectorFilter)).toList();
      if (filtered.isNotEmpty) return filtered;
    }
    return fallbacks;
  }

  // =========================================================================
  // 4. SUCCESS STORY DEPARTMENTS
  // =========================================================================

  Future<void> _syncSuccessStoryDepartments() async {
    try {
      final depts = await SuccessStoryApiService().fetchDepartments();
      if (depts.isNotEmpty) {
        await _db.saveMasterLookupBatch(
          category: categorySuccessStoryDepartments,
          items: depts.map((e) => e.toJson()).toList(),
          keyExtractor: (m) => m['department_id']?.toString() ?? '',
        );
      }
    } catch (e) {
      debugPrint('[MASTER_CACHE] Success story departments sync error: $e');
    }
  }

  Future<List<SuccessStoryDepartmentModel>> getSuccessStoryDepartments() async {
    final cached = await _db.getMasterLookupList(
      categorySuccessStoryDepartments,
    );
    if (cached.isNotEmpty) {
      return cached
          .map((m) => SuccessStoryDepartmentModel.fromJson(m))
          .toList();
    }
    return SuccessStoryDepartmentModel.fallbackDepartments();
  }

  // =========================================================================
  // 5. REFERRAL FACILITIES
  // =========================================================================

  Future<void> _syncReferralFacilities() async {
    try {
      final human = await ReferralsApiService().fetchFacilities('HUMAN');
      final animal = await ReferralsApiService().fetchFacilities('ANIMAL');
      if (human.isNotEmpty) {
        await saveReferralFacilities('HUMAN', human);
      }
      if (animal.isNotEmpty) {
        await saveReferralFacilities('ANIMAL', animal);
      }
    } catch (e) {
      debugPrint('[MASTER_CACHE] Referral facilities sync error: $e');
    }
  }

  /// Saves referral facilities for a specific stream (HUMAN or ANIMAL) into SQLite.
  Future<void> saveReferralFacilities(
    String stream,
    List<ReferralFacility> facilities,
  ) async {
    if (facilities.isEmpty) return;
    final normalized = stream.toUpperCase().contains('ANIMAL')
        ? 'ANIMAL'
        : 'HUMAN';

    final categoryKey = '${categoryReferralFacilities}_$normalized';

    await _db.saveMasterLookupBatch(
      category: categoryKey,
      items: facilities.map((e) => e.toJson()).toList(),
      keyExtractor: (m) =>
          '${m['referral_stream'] ?? normalized}_${m['referral_facility_id'] ?? m['id']}',
    );

    // Also persist into general category with proper distinct keys
    await _db.saveMasterLookupBatch(
      category: categoryReferralFacilities,
      items: facilities.map((e) => e.toJson()).toList(),
      keyExtractor: (m) =>
          '${m['referral_stream'] ?? normalized}_${m['referral_facility_id'] ?? m['id']}',
      clearExisting: false,
    );
  }

  Future<List<ReferralFacility>> getReferralFacilities(String stream) async {
    final normalized = stream.toUpperCase().contains('ANIMAL')
        ? 'ANIMAL'
        : 'HUMAN';

    // 1. Check stream-specific category first (e.g. REFERRAL_FACILITIES_ANIMAL)
    final streamCached = await _db.getMasterLookupList(
      '${categoryReferralFacilities}_$normalized',
    );
    if (streamCached.isNotEmpty) {
      final list =
          streamCached.map((m) => ReferralFacility.fromJson(m)).toList();
      // Guard against corrupt single-"Other" cache entries
      if (list.length > 1 || (list.length == 1 && !list.first.isOther)) {
        return list;
      }
    }

    // 2. Check general category
    final cached = await _db.getMasterLookupList(categoryReferralFacilities);
    if (cached.isNotEmpty) {
      final list = cached
          .map((m) => ReferralFacility.fromJson(m))
          .where((f) => f.stream.toUpperCase().contains(normalized))
          .toList();
      // Guard against corrupt single-"Other" cache entries
      if (list.length > 1 || (list.length == 1 && !list.first.isOther)) {
        return list;
      }
    }

    return [];
  }
}
