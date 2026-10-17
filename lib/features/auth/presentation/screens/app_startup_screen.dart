import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/presentation/widgets/one_health_logo.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';

/// Use Case 1: Auto-Login / Session Check on App Startup
///
/// Problem: When a user re-opens the app after closing it, they shouldn't
/// have to re-enter their PIN every single time.
///
/// Solution: On app launch, read the saved token from local storage (SharedPreferences)
/// and call GET /api/auth/me:
/// - Status 200 OK: Token is valid -> Load user data and navigate directly to DashboardScreen.
/// - Status 401 / Expired: Token expired -> Clear local storage and direct user to SignInScreen.
class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    final startTime = DateTime.now();

    try {
      // 1. Read saved token from SharedPreferences
      final token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('[STARTUP] No saved token found. Directing to SignInScreen.');
        _smoothNavigateTo(const SignInScreen(), startTime);
        return;
      }

      debugPrint('[STARTUP] Saved token found. Validating via GET /api/auth/me...');

      // 2. Call GET /api/auth/me to verify token and load user profile data
      final session = await _authApiService.getCurrentUser(token: token);

      debugPrint('[STARTUP] Token valid for ${session.volunteerId} (${session.fullName}). Auto-logging into Dashboard.');

      // 3. Status 200 OK: Navigate directly to Dashboard
      _smoothNavigateTo(
        DashboardScreen(
          volunteerId: session.volunteerId,
          volunteerName: session.fullName,
        ),
        startTime,
      );
    } on AuthException catch (e) {
      debugPrint('[STARTUP] Auth validation failed (Status ${e.statusCode}): ${e.message}');
      // Status 401 / Expired: Token expired -> Clear local storage and direct to SignInScreen
      if (e.isUnauthorized) {
        await SessionManager.clearSession();
      }
      _smoothNavigateTo(const SignInScreen(), startTime);
    } catch (e) {
      debugPrint('[STARTUP] Network/connectivity issue during startup: $e');

      // Offline Resilience Check: If offline, allow entering with cached session
      final cachedSession = await SessionManager.getUserSession();
      if (cachedSession != null && cachedSession.token.isNotEmpty) {
        debugPrint('[STARTUP] Network unreachable, proceeding with cached session for ${cachedSession.volunteerId}');
        _smoothNavigateTo(
          DashboardScreen(
            volunteerId: cachedSession.volunteerId,
            volunteerName: cachedSession.fullName,
          ),
          startTime,
        );
        return;
      }

      _smoothNavigateTo(const SignInScreen(), startTime);
    }
  }

  /// Ensures branded splash screen displays for at least 450ms for smooth transitions
  void _smoothNavigateTo(Widget destination, DateTime startTime) async {
    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsedMs < 450) {
      await Future.delayed(Duration(milliseconds: 450 - elapsedMs));
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // One Health Logo & System Branding
                  const OneHealthLogo(),

                  const SizedBox(height: 28),

                  // Subtitle & Purpose
                  const Text(
                    'Community One Health Volunteer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Integrated Human · Animal · Environmental Surveillance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Clean Progress Indicator
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Verifying secure session...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Build & Version Label
                  const Text(
                    'COHV Field v1.0.0 · Department of Health & Family Welfare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
