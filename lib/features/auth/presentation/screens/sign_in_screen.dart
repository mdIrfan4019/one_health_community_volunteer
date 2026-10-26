import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../domain/auth_models.dart';
import '../widgets/attention_banner.dart';
import '../widgets/one_health_logo.dart';
import 'volunteer_registration_screen.dart';

import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();

  final AuthApiService _apiService = AuthApiService();

  bool _isLoading = false;
  bool _obscurePin = true;

  // Holds attention/validation errors displayed in the Amber banner
  List<String> _attentionErrors = [];

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _clearAttentionErrors() {
    if (_attentionErrors.isNotEmpty) {
      setState(() => _attentionErrors = []);
    }
  }

  Future<void> _handleForgotPin() async {
    final input = _identifierController.text.trim();

    // Validate national 10-digit format (spec: starts with 6-9, strictly 10 digits)
    final isMobileValid = RegExp(r'^[6-9]\d{9}$').hasMatch(input);

    if (!isMobileValid) {
      setState(() {
        _attentionErrors = [
          'Please enter your registered 10-digit mobile number above to reset PIN.',
        ];
      });
      return;
    }

    setState(() {
      _attentionErrors = [];
      _isLoading = true;
    });

    try {
      final message = await _apiService.requestForgotPin(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.success, content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attentionErrors = [e.toString().replaceAll('Exception: ', '')];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    _clearAttentionErrors();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = SignInWithPinRequest(
        identifier: _identifierController.text.trim(),
        pin: _pinController.text.trim(),
        deviceId: 'DEV-C0YBZ9WK',
      );
      final session = await _apiService.loginWithPin(request);

      // Enrich user session with full demographic and supervisor data from /api/auth/me
      UserSession effectiveSession = session;
      try {
        if (session.token.isNotEmpty) {
          effectiveSession = await _apiService.getCurrentUser(token: session.token);
        }
      } catch (meError) {
        debugPrint('[AUTH] Could not enrich session immediately via /api/auth/me: $meError');
      }

      if (!mounted) return;

      // Navigate to Dashboard on successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            volunteerId: effectiveSession.volunteerId,
            volunteerName: effectiveSession.fullName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attentionErrors = [e.toString().replaceAll('Exception: ', '')];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSignUp() {
    final input = _identifierController.text.trim();
    final prefillMobile = RegExp(r'^[6-9]\d{9}$').hasMatch(input) ? input : '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VolunteerRegistrationScreen(mobileNumber: prefillMobile),
      ),
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
        backgroundColor: AppColors.setuBackground,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Circular Logo
                  const OneHealthLogo(size: 96),
                  const SizedBox(height: 14),

                  // 2. SETU Heading
                  const Text(
                    'SETU',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.setuGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 3. Subtitle
                  const Text(
                    'Breaching the Silos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.setuGreen,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 3. Subtitle
                  const Text(
                    'COHV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Main Authentication Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in with your Volunteer ID or mobile number and your PIN.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Attention Banner (Amber/Orange Ramp)
                          AttentionBanner(errors: _attentionErrors),

                          // Field 1: Volunteer ID or Mobile Number
                          RichText(
                            text: const TextSpan(
                              text: 'Volunteer ID or mobile number',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              children: [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: AppColors.setuGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.text,
                            onChanged: (_) => _clearAttentionErrors(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'COHV-26-0016 or 10-digit mobile',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.setuGreen,
                                  width: 1.6,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your Volunteer ID or mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Field 2: PIN (4-6 digits)
                          RichText(
                            text: const TextSpan(
                              text: 'PIN',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              children: [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: AppColors.setuGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _pinController,
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _clearAttentionErrors(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••',
                              hintStyle: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textLight,
                                letterSpacing: 2.0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.setuGreen,
                                  width: 1.6,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your 4–6 digit PIN';
                              }
                              if (val.trim().length < 4 ||
                                  val.trim().length > 6) {
                                return 'PIN must be between 4 and 6 digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Primary Action Button (Sign in)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.setuGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.setuGreen
                                    .withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Forgot PIN / Password Link
                          Center(
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleForgotPin,
                              child: const Text(
                                'Forgot password / PIN?',
                                style: TextStyle(
                                  color: AppColors.setuGreen,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Direct "Register" Navigation
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 13.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoading ? null : _navigateToSignUp,
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      color: AppColors.setuGreen,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Institutional Logos (NCDC & National One Health Mission)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ncdc_logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 40, width: 32),
                      ),
                      Container(
                        height: 26,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFFCBD5E1),
                      ),
                      Image.asset(
                        'assets/images/national_one_health_mission_logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 40, width: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 6. Organization Subtitle
                  const Text(
                    'National Centre for Disease Control · National One Health Mission',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // // 7. Footer Disclaimer
                  // const Text(
                  //   'Prototype build for design review.\nRecords are held on this device only.',
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: AppColors.textMuted,
                  //     height: 1.35,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
