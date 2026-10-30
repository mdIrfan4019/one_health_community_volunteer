import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Central API Configuration and Endpoint Definitions
///
/// Set the [baseUrl] here to change the backend API server across the entire application.
class ApiConstants {
  // =========================================================================
  // 🌐 BASE URL CONFIGURATION
  // Replace this single URL with your backend server URL.
  // =========================================================================
  static const String baseUrl =
      'https://onehealth-stage.indevconsultancy.in/api';

  // static const String baseUrl = 'http://192.168.10.141:8000/api';

  /// Root server URL without `/api` suffix
  static String get serverRoot => baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - 4)
      : baseUrl;

  /// Alias for file/upload static assets base URL
  static String get fileBaseUrl => serverRoot;

  // =========================================================================
  // 🗺️ DEMOGRAPHIC & MASTER DATA ENDPOINTS
  // (State, District, Block, Gram Panchayat, Village, Education, Profession)
  // =========================================================================
  static const String endpointStates = '$baseUrl/locations/states';
  static const String endpointDistricts = '$baseUrl/locations/districts';
  static const String endpointBlocks = '$baseUrl/locations/blocks';
  static const String endpointPanchayats = '$baseUrl/locations/gram-panchayats';
  static const String endpointVillages = '$baseUrl/locations/villages';
  static const String endpointEducations = '$baseUrl/locations/educations';
  static const String endpointQualifications = endpointEducations;
  static const String endpointProfessions = '$baseUrl/locations/professions';
  static const String endpointSupervisors = '$baseUrl/supervisors';
  static const String endpointDepartments = '$baseUrl/departments';
  static String endpointDepartmentInstitutions(int departmentId) =>
      '$baseUrl/departments/$departmentId/institutions';

  // =========================================================================
  // 🔐 AUTHENTICATION ENDPOINTS
  // =========================================================================
  static const String endpointLogin = '$baseUrl/auth/login';
  static const String endpointLoginWithPin = endpointLogin;
  static const String endpointMe = '$baseUrl/auth/me';
  static const String endpointLogout = '$baseUrl/auth/logout';
  static const String endpointSendOtp = '$baseUrl/auth/send-otp';
  static const String endpointForgotPin = '$baseUrl/auth/forgot-pin';
  static const String endpointVerifyOtp = '$baseUrl/auth/verify-otp';
  static const String endpointRegister = '$baseUrl/volunteers/register';

  // =========================================================================
  // 📊 DASHBOARD & VOLUNTEER SUMMARY ENDPOINTS
  // =========================================================================
  static const String endpointDashboardSummary = '$baseUrl/dashboard/summary';
  static const String endpointVolunteerSummary = '$baseUrl/volunteers/summary';

  /// Helper to build query parameters for GET /api/volunteers/summary
  static String endpointVolunteerSummaryQuery({
    dynamic volunteerId,
    String? volunteerCode,
  }) {
    final queryParams = <String>[];
    if (volunteerId != null) {
      final vidStr = volunteerId.toString().trim();
      if (vidStr.isNotEmpty) {
        queryParams.add('volunteer_id=${Uri.encodeComponent(vidStr)}');
      }
    }
    if (volunteerCode != null && volunteerCode.trim().isNotEmpty) {
      queryParams.add(
        'volunteer_code=${Uri.encodeComponent(volunteerCode.trim())}',
      );
    }
    if (queryParams.isEmpty) return endpointVolunteerSummary;
    return '$endpointVolunteerSummary?${queryParams.join('&')}';
  }

  // =========================================================================
  // 👤 PROFILE ENDPOINTS
  // =========================================================================
  static const String endpointVolunteersProfile = '$baseUrl/volunteers/profile';
  static const String endpointVolunteersMe = '$baseUrl/volunteers/me';
  static const String endpointProfile = endpointVolunteersProfile;
  static const String endpointProfileDetails =
      '$baseUrl/volunteer/profile-details';
  static const String endpointLoginHistory = '$baseUrl/volunteer/login-history';
  static const String endpointUpdateProfile = '$baseUrl/volunteer/update';
  static String endpointVolunteer(dynamic id) => '$baseUrl/volunteers/$id';

  /// Helper to build query parameters for GET /api/volunteers/profile
  static String endpointVolunteerProfileQuery({
    String? volunteerCode,
    int? volunteerId,
  }) {
    final queryParams = <String>[];
    if (volunteerCode != null && volunteerCode.trim().isNotEmpty) {
      queryParams.add(
        'volunteer_code=${Uri.encodeComponent(volunteerCode.trim())}',
      );
    }
    if (volunteerId != null && volunteerId > 0) {
      queryParams.add('volunteer_id=$volunteerId');
    }
    if (queryParams.isEmpty) return endpointVolunteersProfile;
    return '$endpointVolunteersProfile?${queryParams.join('&')}';
  }

  // =========================================================================
  // 🔔 NOTIFICATIONS ENDPOINTS
  // =========================================================================
  static const String endpointNotifications = '$baseUrl/notifications';
  static const String endpointMarkRead = '$baseUrl/notifications/mark-read';

  // =========================================================================
  // 📑 REPORTS ENDPOINTS
  // =========================================================================
  static const String endpointRequestReport = '$baseUrl/reports/request';
  static const String endpointReportHistory = '$baseUrl/reports/history';

  // =========================================================================
  // 🔄 OFFLINE SYNC ENDPOINTS
  // =========================================================================
  static const String endpointSyncBatch = '$baseUrl/sync/batch-upload';

  // =========================================================================
  // 👥 REFERRALS ENDPOINTS
  // =========================================================================
  static const String endpointReferrals = '$baseUrl/referrals';
  static const String endpointReferralsList = endpointReferrals;
  static const String endpointReferralsAll = '$baseUrl/referrals/all';
  static const String endpointReferralAll = '$baseUrl/referral/all';
  static const String endpointCreateReferral = endpointReferrals;
  static const String endpointReferralFacilities =
      '$baseUrl/referrals/facilities';
  static String endpointReferralFacilitiesForStream(String stream) =>
      '$endpointReferralFacilities?stream=$stream';
  static String endpointReferralDetail(int referralId) =>
      '$baseUrl/referrals/$referralId';

  // =========================================================================
  // ⚠️ HEALTH EVENTS / OUTBREAK REPORTING ENDPOINTS
  // =========================================================================
  static const String endpointEvents = '$baseUrl/events';
  static const String endpointEventsAll = '$baseUrl/events/all';
  static const String endpointReportEvent = endpointEvents;
  static const String endpointEventFormMetadata =
      '$baseUrl/events/form-metadata';
  static const String endpointPopulationSubcategories =
      '$baseUrl/events/population-subcategories';
  static String endpointPopulationSubcategoriesQuery(int populationTypeId) =>
      '$endpointPopulationSubcategories?population_type_id=$populationTypeId';
  static String endpointEventDetail(int eventReportId) =>
      '$baseUrl/events/$eventReportId';

  // =========================================================================
  // 📢 AWARENESS ACTIVITIES ENDPOINTS
  // =========================================================================
  static const String endpointAwarenessActivities =
      '$baseUrl/awareness-activities';
  static const String endpointAwarenessActivityTypes =
      '$baseUrl/awareness-activities/activity-types';
  static const String endpointAwarenessTopics =
      '$baseUrl/awareness-activities/topics';
  static const String endpointAwarenessAll =
      '$baseUrl/awareness-activities/all';
  static const String endpointAwarenessList = endpointAwarenessAll;
  static const String endpointCreateAwareness = endpointAwarenessActivities;
  static String endpointAwarenessDetail(int awarenessId) =>
      '$baseUrl/awareness-activities/$awarenessId';

  // =========================================================================
  // 🧪 SAMPLE SUPPORT ENDPOINTS
  // =========================================================================
  static const String endpointSampleSupport = '$baseUrl/sample-support';
  static const String endpointSampleSupportAll = '$baseUrl/sample-support/all';
  static const String endpointSampleSupportTypes =
      '$baseUrl/sample-support/types';
  static String endpointSampleSupportDetail(int sampleSupportId) =>
      '$baseUrl/sample-support/$sampleSupportId';

  // =========================================================================
  // 🌟 SUCCESS STORIES ENDPOINTS
  // =========================================================================
  static const String endpointSuccessStories = '$baseUrl/success-stories';
  static const String endpointSuccessStoriesAll =
      '$baseUrl/success-stories/all';
  static const String endpointSuccessStoriesDepartments =
      '$baseUrl/success-stories/departments';
  static String endpointSuccessStoryDetail(int successStoryId) =>
      '$baseUrl/success-stories/$successStoryId';

  // =========================================================================
  // ðŸ“š CAPACITY BUILDING ENDPOINTS
  // =========================================================================
  static const String endpointTrainingMaster =
      '$baseUrl/capacity-building/training-master';
  static const String endpointTrainingImparted =
      '$baseUrl/capacity-building/training-imparted';
  static String endpointTrainingImpartedDetail(dynamic id) =>
      '$endpointTrainingImparted/$id';
  static const String endpointTrainingAttended =
      '$baseUrl/capacity-building/training-attended';
  static String endpointTrainingAttendedDetail(dynamic id) =>
      '$endpointTrainingAttended/$id';

  // =========================================================================
  // 📎 ATTACHMENTS ENDPOINTS
  // =========================================================================
  static const String endpointAttachments = '$baseUrl/attachments';
  static String endpointAttachmentStream(dynamic attachmentId) =>
      '$baseUrl/attachments/$attachmentId';
  static String endpointAttachmentDownload(dynamic attachmentId) =>
      '$baseUrl/attachments/$attachmentId/download';
  static String endpointAttachmentMeta(dynamic attachmentId) =>
      '$baseUrl/attachments/$attachmentId/meta';

  /// Resolves an attachment URL from relative/absolute paths or streaming endpoint
  static String resolveAttachmentUrl({
    dynamic attachmentId,
    String? fileUrl,
    String? url,
    String? storagePath,
  }) {
    final direct = (fileUrl != null && fileUrl.trim().isNotEmpty)
        ? fileUrl.trim()
        : (url != null && url.trim().isNotEmpty)
        ? url.trim()
        : (storagePath != null && storagePath.trim().isNotEmpty)
        ? storagePath.trim()
        : null;

    if (direct != null) {
      if (direct.startsWith('http://') || direct.startsWith('https://')) {
        return direct;
      }
      final clean = direct.startsWith('/') ? direct.substring(1) : direct;
      if (clean.startsWith('api/')) {
        return '$serverRoot/$clean';
      }
      return '$serverRoot/$clean';
    }

    if (attachmentId != null &&
        attachmentId.toString().isNotEmpty &&
        attachmentId.toString() != '0') {
      return endpointAttachmentStream(attachmentId);
    }
    return '';
  }

  // =========================================================================
  // 🛠️ COMMON HEADERS
  // =========================================================================
  static Map<String, String> defaultHeaders({String? token}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  /// Resolves relative or absolute image path to a full primary URL
  static String? resolveImageUrl(String? path) {
    final candidates = resolveImageCandidateUrls(path);
    return candidates.isNotEmpty ? candidates.first : null;
  }

  /// Resolves an image path into a list of candidate URLs to try in order.
  /// This ensures that whether the backend serves files directly at /volunteers/...,
  /// via /uploads/..., /backend/uploads/..., or /api/..., the image will load successfully.
  // static List<String> resolveImageCandidateUrls(String? path) {
  //   if (path == null || path.trim().isEmpty) return const [];
  //   var trimmed = path.trim().replaceAll('\\', '/');
  //
  //   if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
  //     return [trimmed];
  //   }
  //
  //   // Do not convert local device file paths to HTTP URLs
  //   if (trimmed.startsWith('file://') ||
  //       RegExp(r'^[a-zA-Z]:').hasMatch(trimmed) ||
  //       trimmed.startsWith('/data/') ||
  //       trimmed.startsWith('/storage/')) {
  //     return const [];
  //   }
  //
  //   // Strip leading slashes or dots
  //   while (trimmed.startsWith('/') || trimmed.startsWith('./')) {
  //     trimmed = trimmed.replaceFirst(RegExp(r'^[./]+'), '');
  //   }
  //
  //   // Clean path without backend/ or uploads/ prefix
  //   var cleanPath = trimmed;
  //   if (cleanPath.toLowerCase().startsWith('backend/')) {
  //     cleanPath = cleanPath.substring('backend/'.length);
  //   }
  //   while (cleanPath.startsWith('/') || cleanPath.startsWith('./')) {
  //     cleanPath = cleanPath.replaceFirst(RegExp(r'^[./]+'), '');
  //   }
  //
  //   final serverRoot = baseUrl.endsWith('/api')
  //       ? baseUrl.substring(0, baseUrl.length - 4)
  //       : baseUrl;
  //
  //   final candidates = <String>[];
  //
  //   // If cleanPath is just a filename (e.g. COHV-26-0005.jpg)
  //   if (!cleanPath.contains('/')) {
  //     cleanPath = 'volunteers/$cleanPath';
  //   }
  //
  //   // 1. Exact path as returned from backend (e.g. /volunteers/COHV-26-0005.jpg)
  //   candidates.add('$serverRoot/$cleanPath');
  //
  //   // 2. Uploads folder mount (e.g. /uploads/volunteers/COHV-26-0005.jpg)
  //   if (cleanPath.toLowerCase().startsWith('uploads/')) {
  //     candidates.add('$serverRoot/$cleanPath');
  //   } else {
  //     candidates.add('$serverRoot/uploads/$cleanPath');
  //   }
  //
  //   // 3. Backend/uploads folder mount (e.g. /backend/uploads/volunteers/COHV-26-0005.jpg)
  //   candidates.add('$serverRoot/backend/uploads/$cleanPath');
  //
  //   // 4. API router path (e.g. /api/volunteers/COHV-26-0005.jpg)
  //   candidates.add('$baseUrl/$cleanPath');
  //
  //   // 5. Raw trimmed path if it had a custom prefix
  //   if (trimmed != cleanPath) {
  //     candidates.add('$serverRoot/$trimmed');
  //   }
  //
  //   return candidates.toSet().toList();
  // }

  static List<String> resolveImageCandidateUrls(String? path) {
    if (path == null || path.trim().isEmpty) return const [];
    var trimmed = path.trim().replaceAll('\\', '/');

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return [trimmed];
    }

    if (trimmed.startsWith('file://') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(trimmed) ||
        trimmed.startsWith('/data/') ||
        trimmed.startsWith('/storage/')) {
      return const [];
    }

    while (trimmed.startsWith('/') || trimmed.startsWith('./')) {
      trimmed = trimmed.replaceFirst(RegExp(r'^[./]+'), '');
    }

    var cleanPath = trimmed;
    if (cleanPath.toLowerCase().startsWith('backend/')) {
      cleanPath = cleanPath.substring('backend/'.length);
    }
    while (cleanPath.startsWith('/') || cleanPath.startsWith('./')) {
      cleanPath = cleanPath.replaceFirst(RegExp(r'^[./]+'), '');
    }

    if (cleanPath.toLowerCase().startsWith('uploads/')) {
      cleanPath = cleanPath.substring('uploads/'.length);
    }
    while (cleanPath.startsWith('/') || cleanPath.startsWith('./')) {
      cleanPath = cleanPath.replaceFirst(RegExp(r'^[./]+'), '');
    }

    final serverRoot = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;

    final candidates = <String>[];

    final lastDotIndex = cleanPath.lastIndexOf('.');
    final String basePath = lastDotIndex != -1
        ? cleanPath.substring(0, lastDotIndex)
        : cleanPath;
    final String origExt = lastDotIndex != -1
        ? cleanPath.substring(lastDotIndex)
        : '';

    final String fullBasePath = basePath.contains('/')
        ? basePath
        : 'volunteers/$basePath';

    final extensionsToTry = <String>[];
    if (origExt.isNotEmpty) {
      extensionsToTry.add(origExt);
    }
    for (final ext in ['.png', '.jpg', '.jpeg', '.webp']) {
      if (!extensionsToTry.contains(ext)) {
        extensionsToTry.add(ext);
      }
    }

    for (final ext in extensionsToTry) {
      final p = '$fullBasePath$ext';

      // Uploads mount
      candidates.add('$serverRoot/uploads/$p');

      // Direct mount
      candidates.add('$serverRoot/$p');

      // Backend/uploads mount
      candidates.add('$serverRoot/backend/uploads/$p');

      // API router mount
      candidates.add('$baseUrl/uploads/$p');
      candidates.add('$baseUrl/$p');

      // Static / Media mounts
      candidates.add('$serverRoot/static/uploads/$p');
      candidates.add('$serverRoot/static/$p');
      candidates.add('$serverRoot/media/$p');
    }

    if (trimmed.isNotEmpty) {
      candidates.add('$serverRoot/$trimmed');
      candidates.add('$serverRoot/uploads/$trimmed');
      candidates.add('$serverRoot/backend/uploads/$trimmed');
    }

    return candidates.toSet().toList();
  }

  /// Safe debug logger for API requests matching the required project format.
  /// Masks secrets/tokens and truncates huge base64 media strings for clean logs.
  static void logRequest({
    required String module,
    required String method,
    required dynamic url,
    required dynamic body,
  }) {
    String formattedBody;
    if (body is Map) {
      final sanitized = <String, dynamic>{};
      body.forEach((key, value) {
        if (value is List) {
          sanitized[key.toString()] = value.map((item) {
            final str = item.toString();
            if (str.startsWith('data:') && str.length > 60) {
              return '${str.substring(0, 30)}... [Base64 ${str.length} chars]';
            }
            return item;
          }).toList();
        } else if (value is String &&
            value.startsWith('data:') &&
            value.length > 60) {
          sanitized[key.toString()] =
              '${value.substring(0, 30)}... [Base64 ${value.length} chars]';
        } else {
          sanitized[key.toString()] = value;
        }
      });
      try {
        formattedBody = const JsonEncoder.withIndent('  ').convert(sanitized);
      } catch (_) {
        formattedBody = sanitized.toString();
      }
    } else {
      formattedBody = body.toString();
    }

    debugPrint('[API_REQUEST] Module: $module');
    debugPrint('[API_REQUEST] Method: $method');
    debugPrint('[API_REQUEST] URL: $url');
    debugPrint('[API_REQUEST] Body: $formattedBody');
  }
}
