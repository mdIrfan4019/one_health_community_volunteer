import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
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
          .timeout(const Duration(seconds: 15));

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
          return metrics;
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
    final cached = await SessionManager.getCachedDashboardMetrics(cacheKey);
    if (cached != null) {
      debugPrint('[DASHBOARD_API] Returning cached metrics for $cacheKey');
      return cached;
    }

    // Default clean initial state (no dummy numbers)
    return DashboardMetrics(
      pendingSyncCount: SyncRepository().getSummary().pendingSync,
    );
  }

  /// Fetch volunteer profile dynamically from GET /api/auth/me or local SessionManager
  Future<VolunteerProfile> getVolunteerProfile(String volunteerId) async {
    try {
      final freshSession = await _authApiService.getCurrentUser();
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
        departmentName: freshSession.sector.isNotEmpty
            ? freshSession.sector
            : 'Public Health Department',
      );
    } catch (_) {}

    final detailed = await SessionManager.getDetailedProfile();
    if (detailed != null) {
      final breadcrumbParts = [
        detailed.village,
        detailed.block,
        detailed.district,
      ].where((s) => s.trim().isNotEmpty).toList();

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
        departmentName: (detailed.departmentName != null &&
                detailed.departmentName!.trim().isNotEmpty)
            ? detailed.departmentName!
            : (detailed.cohvType?.trim().isNotEmpty == true
                ? detailed.cohvType!
                : (detailed.designation.isNotEmpty
                    ? detailed.designation
                    : 'Public Health Department')),
      );
    }

    final cached = await SessionManager.getUserSession();
    if (cached != null) {
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
        departmentName: cached.sector.isNotEmpty
            ? cached.sector
            : 'Public Health Department',
      );
    }

    return VolunteerProfile(
      fullName: 'Alex',
      volunteerId: volunteerId.isNotEmpty ? volunteerId : 'COHV-26-0005',
      status: 'Active',
      locationBreadcrumb: 'Mannanur · Amrabad · Nagarkurnool',
      departmentName: 'Public Health Department',
    );
  }
}
