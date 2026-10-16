import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../domain/auth_models.dart';
import '../widgets/attention_banner.dart';
import '../widgets/custom_text_field.dart';
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
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(message),
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

  // Future<void> _handleSubmit() async {
  //   _clearAttentionErrors();
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     final request = SignInWithPinRequest(
  //       identifier: _identifierController.text.trim(),
  //       pin: _pinController.text.trim(),
  //     );
  //     final session = await _apiService.loginWithPin(request);

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         backgroundColor: AppColors.success,
  //         content: Text('Welcome, ${session.fullName}! (${session.volunteerId})'),
  //       ),
  //     );
  //     // TODO: Navigate to Home/Dashboard screen when created
  //   } catch (e) {
  //     if (!mounted) return;
  //     // setState(() {
  //     //   _attentionErrors = [e.toString().replaceAll('Exception: ', '')];
  //     // });
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(
  //         builder: (_) => DashboardScreen(
  //           volunteerId: session.volunteerId,
  //           volunteerName: session.fullName,
  //         ),
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
     Future<void> _handleSubmit() async {
    _clearAttentionErrors();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = SignInWithPinRequest(
        identifier: _identifierController.text.trim(),
        pin: _pinController.text.trim(),
      );
      final session = await _apiService.loginWithPin(request);

      if (!mounted) return;

      // ✅ Navigate to Dashboard on successful login (inside try block)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            volunteerId: session.volunteerId,
            volunteerName: session.fullName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // ❌ Keep error handling in catch block
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
        builder: (_) => VolunteerRegistrationScreen(
          mobileNumber: prefillMobile,
        ),
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Branding Header
                  const OneHealthLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    'One Health Community Volunteer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Field reporting application',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Main Authentication Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
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

                          // ⚠️ Attention Banner (Amber/Orange Ramp)
                          AttentionBanner(errors: _attentionErrors),

                          // Field 1: Volunteer ID or Mobile Number
                          CustomTextField(
                            label: 'Volunteer ID or mobile number',
                            hintText: 'COHV-26-0001 or 10-digit mobile',
                            isRequired: true,
                            controller: _identifierController,
                            keyboardType: TextInputType.text,
                            onChanged: (_) => _clearAttentionErrors(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your Volunteer ID or mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Field 2: PIN (4-6 digits)
                          CustomTextField(
                            label: 'PIN',
                            hintText: '••••',
                            isRequired: true,
                            controller: _pinController,
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _clearAttentionErrors(),
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
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your 4–6 digit PIN';
                              }
                              if (val.trim().length < 4 || val.trim().length > 6) {
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
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Forgot PIN / Password Link
                          Center(
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleForgotPin,
                              child: const Text(
                                'Forgot password / PIN?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 8),

                          // Direct "Sign up" Navigation
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13.5,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _navigateToSignUp,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
