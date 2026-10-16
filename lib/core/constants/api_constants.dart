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
  static const String endpointLoginWithPin = '$baseUrl/auth/login-pin';
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
  static const String endpointProfileDetails = '$baseUrl/volunteer/profile-details';
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
  static const String endpointReportEvent = '$baseUrl/events/report';

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
}
