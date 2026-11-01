import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/profile/data/profile_api_service.dart';
import 'package:cohv/features/sync/data/sync_repository.dart';

import '../domain/dashboard_models.dart';

class DashboardApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointDashboardSummary =
      ApiConstants.endpointDashboardSummary;
  static const String endpointVolunteerSummary =
      ApiConstants.endpointVolunteerSummary;
  static const String endpointProfile = ApiConstants.endpointProfile;

  final AuthApiService _authApiService = AuthApiService();
  final http.Client _client;

  DashboardApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch dynamic KPI metrics for the logged-in volunteer from GET /api/volunteers/summary
  Future<DashboardMetrics> getDashboardMetrics([
    String? volunteerIdentifier,
    int? numericVolunteerId,
  ]) async {
    final token = await SessionManager.getToken();
    final session = await SessionManager.getUserSession();

    // 1. Resolve effective volunteer identifiers
    String? volunteerCode;
    int? effectiveNumericId = numericVolunteerId;

    final ident = volunteerIdentifier?.trim() ?? '';
    if (ident.isNotEmpty) {
      if (RegExp(r'^\d+$').hasMatch(ident)) {
        effectiveNumericId ??= int.tryParse(ident);
      } else {
        volunteerCode = ident;
      }
    }

    if (volunteerCode == null && effectiveNumericId == null) {
      if (session != null) {
        if (session.volunteerId.isNotEmpty) {
          if (RegExp(r'^\d+$').hasMatch(session.volunteerId)) {
            effectiveNumericId = int.tryParse(session.volunteerId);
          } else {
            volunteerCode = session.volunteerId;
          }
        }
        if (effectiveNumericId == null &&
            session.numericVolunteerId != null &&
            session.numericVolunteerId! > 0) {
          effectiveNumericId = session.numericVolunteerId;
        }
      }
    }

    if (effectiveNumericId == null) {
      final cachedNumId = await SessionManager.getNumericVolunteerId();
      if (cachedNumId != null && cachedNumId > 0) {
        effectiveNumericId = cachedNumId;
      }
    }

    if (volunteerCode == null) {
      final cachedVolId = await SessionManager.getVolunteerId();
      if (cachedVolId != null && cachedVolId.isNotEmpty) {
        if (RegExp(r'^\d+$').hasMatch(cachedVolId)) {
          effectiveNumericId ??= int.tryParse(cachedVolId);
        } else {
          volunteerCode = cachedVolId;
        }
      }
    }

    // Prioritize primary numeric volunteer ID if known (e.g. 52).
    // Otherwise, use volunteerCode directly (e.g. "COHV-26-0018") as backend GET /volunteers/summary supports both.
    final String queryParamVolunteerId =
        effectiveNumericId != null && effectiveNumericId > 0
            ? effectiveNumericId.toString()
            : (volunteerCode ?? '');

    final cacheKey = (volunteerCode != null && volunteerCode.isNotEmpty)
        ? volunteerCode
        : (effectiveNumericId?.toString() ?? session?.volunteerId ?? 'default');

    final url = ApiConstants.endpointVolunteerSummaryQuery(
      volunteerId:
          queryParamVolunteerId.isNotEmpty ? queryParamVolunteerId : null,
      volunteerCode: volunteerCode,
    );

    debugPrint(
      '[DASHBOARD_API] GET $url (token: ${token != null && token.isNotEmpty ? "present" : "none"})',
    );

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: ApiConstants.defaultHeaders(token: token),
          )
          .timeout(const Duration(seconds: 6));

      debugPrint(
        '[DASHBOARD_API] Response status: ${response.statusCode}, length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = (decoded['data'] is Map<String, dynamic>)
              ? decoded['data'] as Map<String, dynamic>
              : (decoded['data'] is Map
                  ? Map<String, dynamic>.from(decoded['data'] as Map)
                  : decoded);

          await SyncRepository().refreshFromDatabase();
          final localPendingSync =
              SyncRepository().getSummary().pendingSync;

          final metrics = DashboardMetrics.fromJson(
            data,
            localPendingSync: localPendingSync,
          );

          if (metrics.volunteerId != null && metrics.volunteerId! > 0) {
            await SessionManager.saveNumericVolunteerId(metrics.volunteerId!);
          }

          // Persist metrics locally for instant offline recovery
          await SessionManager.saveDashboardMetrics(cacheKey, metrics);

          // Persist metrics into SQLite cached_records
          try {
            await AppDatabase.instance.cacheRecordsList(
              entityType: 'DASHBOARD_METRICS',
              volunteerId: cacheKey,
              records: [metrics.toJson()],
              idExtractor: (r) => cacheKey,
            );
          } catch (_) {}

          return await _augmentWithOutboxCounts(metrics);
        }
      } else {
        debugPrint(
          '[DASHBOARD_API] Failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] Error fetching volunteer summary: $e');
    }

    // Offline / error resilience: recover from local cache
    DashboardMetrics? cached = await SessionManager.getCachedDashboardMetrics(cacheKey);

    // Fallback: check SQLite cached_records
    if (cached == null) {
      try {
        final sqliteRecords = await AppDatabase.instance.getCachedRecordsList(
          entityType: 'DASHBOARD_METRICS',
          volunteerId: cacheKey,
        );
        if (sqliteRecords.isNotEmpty) {
          cached = DashboardMetrics.fromJson(sqliteRecords.first);
          await SessionManager.saveDashboardMetrics(cacheKey, cached);
        }
      } catch (_) {}
    }

    final baseMetrics = cached ?? DashboardMetrics(volunteerCode: cacheKey);
    return await _augmentWithOutboxCounts(baseMetrics);
  }

  /// Reconciles cached metrics with un-synced outbox records in SQLite
  Future<DashboardMetrics> _augmentWithOutboxCounts(DashboardMetrics base) async {
    try {
      final db = AppDatabase.instance;
      int pendingCount = 0;
      try {
        pendingCount = await db.getPendingCount();
      } catch (_) {}

      int pendingEvents = 0;
      int pendingReferrals = 0;
      int pendingAwareness = 0;
      int pendingSamples = 0;
      int pendingImparted = 0;
      int pendingAttended = 0;
      int pendingStories = 0;

      try {
        pendingEvents = (await db.getOutboxRecordsByEntity('EVENT')).length;
      } catch (_) {}
      try {
        pendingReferrals = (await db.getOutboxRecordsByEntity('REFERRAL')).length;
      } catch (_) {}
      try {
        pendingAwareness = (await db.getOutboxRecordsByEntity('AWARENESS')).length;
      } catch (_) {}
      try {
        pendingSamples = (await db.getOutboxRecordsByEntity('SAMPLE_SUPPORT')).length;
      } catch (_) {}
      try {
        pendingImparted = (await db.getOutboxRecordsByEntity('TRAINING_IMPARTED')).length;
      } catch (_) {}
      try {
        pendingAttended = (await db.getOutboxRecordsByEntity('TRAINING_ATTENDED')).length;
      } catch (_) {}
      try {
        pendingStories = (await db.getOutboxRecordsByEntity('SUCCESS_STORY')).length;
      } catch (_) {}

      return base.copyWith(
        totalVisits: base.totalVisits + pendingEvents,
        referrals: base.referrals + pendingReferrals,
        awarenessActivities: base.awarenessActivities + pendingAwareness,
        samplesSupported: base.samplesSupported + pendingSamples,
        trainingsImparted: base.trainingsImparted + pendingImparted,
        trainingsAttended: base.trainingsAttended + pendingAttended,
        successStories: base.successStories + pendingStories,
        pendingSyncCount: pendingCount,
      );
    } catch (e) {
      debugPrint('[DASHBOARD_API] Error augmenting with outbox counts: $e');
      return base;
    }
  }

  /// Fetch volunteer profile dynamically from GET /api/auth/me or local SessionManager
  Future<VolunteerProfile> getVolunteerProfile(String volunteerId) async {
    try {
      final freshSession = await _authApiService.getCurrentUser();
      final freshDept = freshSession.departmentName?.trim().isNotEmpty == true
          ? freshSession.departmentName!.trim()
          : freshSession.sector.trim();

      if (freshDept.isNotEmpty) {
        return VolunteerProfile(
          fullName: freshSession.fullName.isNotEmpty
              ? freshSession.fullName
              : 'Alex',
          volunteerId: freshSession.volunteerId.isNotEmpty
              ? freshSession.volunteerId
              : volunteerId,
          status: freshSession.status.toUpperCase() == 'ACTIVE'
              ? 'Active'
              : freshSession.status,
          locationBreadcrumb: freshSession.locationBreadcrumb.isNotEmpty
              ? freshSession.locationBreadcrumb
              : 'Mannanur · Amrabad · Nagarkurnool',
          photoUrl: freshSession.photoPath,
          departmentName: freshDept,
        );
      }
    } catch (_) {}

    // Fallback: Fetch detailed profile from server via GET /api/volunteers/{id} or /api/volunteers/me
    try {
      final freshProfile = await ProfileApiService().getDetailedProfile();
      final freshDept = (freshProfile.departmentName != null &&
              freshProfile.departmentName!.trim().isNotEmpty)
          ? freshProfile.departmentName!.trim()
          : (freshProfile.cohvType?.trim().isNotEmpty == true
              ? freshProfile.cohvType!.trim()
              : '');
      if (freshDept.isNotEmpty) {
        final breadcrumbParts = [
          freshProfile.village,
          freshProfile.block,
          freshProfile.district,
        ].where((s) => s.trim().isNotEmpty).toList();

        return VolunteerProfile(
          fullName: freshProfile.fullName.isNotEmpty
              ? freshProfile.fullName
              : 'Alex',
          volunteerId: freshProfile.volunteerId.isNotEmpty
              ? freshProfile.volunteerId
              : volunteerId,
          status: freshProfile.status.toUpperCase() == 'ACTIVE'
              ? 'Active'
              : freshProfile.status,
          locationBreadcrumb: breadcrumbParts.isNotEmpty
              ? breadcrumbParts.join(' · ')
              : 'Mannanur · Amrabad · Nagarkurnool',
          photoUrl: freshProfile.photoUrl,
          departmentName: freshDept,
        );
      }
    } catch (_) {}

    final detailed = await SessionManager.getDetailedProfile();
    if (detailed != null) {
      final breadcrumbParts = [
        detailed.village,
        detailed.block,
        detailed.district,
      ].where((s) => s.trim().isNotEmpty).toList();

      final detailedDept = (detailed.departmentName != null &&
              detailed.departmentName!.trim().isNotEmpty)
          ? detailed.departmentName!.trim()
          : (detailed.cohvType?.trim().isNotEmpty == true
              ? detailed.cohvType!.trim()
              : (detailed.designation.isNotEmpty ? detailed.designation : ''));

      return VolunteerProfile(
        fullName: detailed.fullName.isNotEmpty ? detailed.fullName : 'Alex',
        volunteerId: detailed.volunteerId.isNotEmpty
            ? detailed.volunteerId
            : volunteerId,
        status: detailed.status.toUpperCase() == 'ACTIVE'
            ? 'Active'
            : detailed.status,
        locationBreadcrumb: breadcrumbParts.isNotEmpty
            ? breadcrumbParts.join(' · ')
            : 'Mannanur · Amrabad · Nagarkurnool',
        photoUrl: detailed.photoUrl,
        departmentName: detailedDept,
      );
    }

    final cached = await SessionManager.getUserSession();
    if (cached != null) {
      final cachedDept = cached.departmentName?.trim().isNotEmpty == true
          ? cached.departmentName!.trim()
          : cached.sector.trim();

      return VolunteerProfile(
        fullName: cached.fullName.isNotEmpty ? cached.fullName : 'Alex',
        volunteerId: cached.volunteerId.isNotEmpty
            ? cached.volunteerId
            : volunteerId,
        status: cached.status.toUpperCase() == 'ACTIVE'
            ? 'Active'
            : cached.status,
        locationBreadcrumb: cached.locationBreadcrumb.isNotEmpty
            ? cached.locationBreadcrumb
            : 'Mannanur · Amrabad · Nagarkurnool',
        photoUrl: cached.photoPath,
        departmentName: cachedDept,
      );
    }

    return VolunteerProfile(
      fullName: 'Alex',
      volunteerId: volunteerId.isNotEmpty ? volunteerId : 'COHV-26-0005',
      status: 'Active',
      locationBreadcrumb: 'Mannanur · Amrabad · Nagarkurnool',
      departmentName: '',
    );
  }
}
