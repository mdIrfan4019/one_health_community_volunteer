/// Central API Configuration and Endpoint Definitions
///
/// Set the [baseUrl] here to change the backend API server across the entire application.
class ApiConstants {
  // =========================================================================
  // 🌐 BASE URL CONFIGURATION
  // Replace this single URL with your backend server URL.
  // =========================================================================
  // static const String baseUrl = 'https://api.yourserver.org/api/v1';
  static const String baseUrl = 'http://192.168.10.174:8000/api';

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
  static const String endpointProfile = '$baseUrl/volunteer/profile';

  // =========================================================================
  // 👤 PROFILE ENDPOINTS
  // =========================================================================
  static const String endpointProfileDetails =
      '$baseUrl/volunteer/profile-details';
  static const String endpointLoginHistory = '$baseUrl/volunteer/login-history';
  static const String endpointUpdateProfile = '$baseUrl/volunteer/update';

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
  static const String endpointReferralsList = '$baseUrl/referrals/list';
  static const String endpointCreateReferral = '$baseUrl/referrals/create';

  // =========================================================================
  // ⚠️ HEALTH EVENTS / OUTBREAK REPORTING ENDPOINTS
  // =========================================================================
  static const String endpointEvents = '$baseUrl/events';
  static const String endpointReportEvent = endpointEvents;
  static const String endpointEventFormMetadata = '$baseUrl/events/form-metadata';

  // =========================================================================
  // 📢 AWARENESS ACTIVITIES ENDPOINTS
  // =========================================================================
  static const String endpointAwarenessList = '$baseUrl/awareness/list';
  static const String endpointCreateAwareness = '$baseUrl/awareness/create';

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
