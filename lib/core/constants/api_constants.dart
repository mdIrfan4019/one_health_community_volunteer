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

  // static const String baseUrl = 'http://192.168.10.99:8000/api';

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
  // 📊 DASHBOARD ENDPOINTS
  // =========================================================================
  static const String endpointDashboardSummary = '$baseUrl/dashboard/summary';

  // =========================================================================
  // 👤 PROFILE ENDPOINTS
  // =========================================================================
  static const String endpointVolunteersProfile = '$baseUrl/volunteers/profile';
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
  static const String endpointSampleSupportTypes = '$baseUrl/sample-support/types';
  static String endpointSampleSupportDetail(int sampleSupportId) =>
      '$baseUrl/sample-support/$sampleSupportId';

  // =========================================================================
  // 🌟 SUCCESS STORIES ENDPOINTS
  // =========================================================================
  static const String endpointSuccessStories = '$baseUrl/success-stories';
  static const String endpointSuccessStoriesAll = '$baseUrl/success-stories/all';
  static const String endpointSuccessStoriesDepartments =
      '$baseUrl/success-stories/departments';
  static String endpointSuccessStoryDetail(int successStoryId) =>
      '$baseUrl/success-stories/$successStoryId';

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
}
