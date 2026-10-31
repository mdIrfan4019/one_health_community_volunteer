import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../domain/auth_models.dart';
import '../widgets/attention_banner.dart';
import '../widgets/one_health_logo.dart';
import 'otp_verification_screen.dart';

class RegisterMobileScreen extends StatefulWidget {
  final String? initialMobile;

  const RegisterMobileScreen({super.key, this.initialMobile});

  @override
  State<RegisterMobileScreen> createState() => _RegisterMobileScreenState();
}

class _RegisterMobileScreenState extends State<RegisterMobileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mobileController;
  final TextEditingController _emailController = TextEditingController();
  final AuthApiService _apiService = AuthApiService();

  bool _isLoading = false;
  int _registeredVolunteersCount = 0;
  List<String> _attentionErrors = [];

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(text: widget.initialMobile ?? '');
    _loadRegisteredVolunteersCount();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredVolunteersCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final volunteerCodes = <String>{};
      for (final k in keys) {
        if (k.startsWith('submitted_events_') && k.endsWith('_json')) {
          final code = k
              .replaceFirst('submitted_events_', '')
              .replaceFirst('_json', '');
          if (code.isNotEmpty) volunteerCodes.add(code);
        }
      }
      if (mounted) {
        setState(() {
          _registeredVolunteersCount = volunteerCodes.length;
        });
      }
    } catch (_) {}
  }

  void _clearAttentionErrors() {
    if (_attentionErrors.isNotEmpty) {
      setState(() => _attentionErrors = []);
    }
  }

  Future<void> _handleSendOtp() async {
    _clearAttentionErrors();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();

    if (mobile.isEmpty) {
      setState(() {
        _attentionErrors = ['Please enter your 10-digit mobile number.'];
      });
      return;
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      setState(() {
        _attentionErrors = [
          'Please enter a valid 10-digit mobile number starting with 6, 7, 8, or 9.',
        ];
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _attentionErrors = ['Please enter your email address.'];
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _attentionErrors = [
          'Please enter a valid email address (e.g. name@example.com).',
        ];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = SendOtpRequest(mobileNumber: mobile);
      await _apiService.sendOtp(request);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              OtpVerificationScreen(mobileNumber: mobile, email: email),
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

                  // 3. Subtitles
                  const Text(
                    'Bridging the Silos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.setuGreen,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),

                  const Text(
                    'COHV Reporting App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Main Registration Card
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
                            'Register as a new volunteer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your email is verified by OTP.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          if (_registeredVolunteersCount > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Adding another volunteer to this device. $_registeredVolunteersCount ${_registeredVolunteersCount == 1 ? "volunteer is" : "volunteers are"} already registered here; none of them are affected.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Attention Banner (Amber/Orange Ramp)
                          AttentionBanner(errors: _attentionErrors),

                          // // Field: Mobile number
                          // RichText(
                          //   text: const TextSpan(
                          //     text: 'Mobile number',
                          //     style: TextStyle(
                          //       fontSize: 13.5,
                          //       fontWeight: FontWeight.w600,
                          //       color: AppColors.textDark,
                          //     ),
                          //     children: [
                          //       TextSpan(
                          //         text: ' *',
                          //         style: TextStyle(
                          //           color: AppColors.setuGreen2,
                          //           fontWeight: FontWeight.bold,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // const SizedBox(height: 8),
                          // TextFormField(
                          //   controller: _mobileController,
                          //   keyboardType: TextInputType.phone,
                          //   inputFormatters: [
                          //     FilteringTextInputFormatter.digitsOnly,
                          //     LengthLimitingTextInputFormatter(10),
                          //   ],
                          //   onChanged: (_) => _clearAttentionErrors(),
                          //   style: const TextStyle(
                          //     fontSize: 14.5,
                          //     color: AppColors.textDark,
                          //   ),
                          //   decoration: InputDecoration(
                          //     hintText: '10-digit mobile number',
                          //     hintStyle: const TextStyle(
                          //       fontSize: 14,
                          //       color: AppColors.textLight,
                          //     ),
                          //     contentPadding: const EdgeInsets.symmetric(
                          //       horizontal: 16,
                          //       vertical: 14,
                          //     ),
                          //     filled: true,
                          //     fillColor: Colors.white,
                          //     border: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(12),
                          //       borderSide: const BorderSide(
                          //         color: AppColors.border,
                          //         width: 1.2,
                          //       ),
                          //     ),
                          //     enabledBorder: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(12),
                          //       borderSide: const BorderSide(
                          //         color: AppColors.border,
                          //         width: 1.2,
                          //       ),
                          //     ),
                          //     focusedBorder: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(12),
                          //       borderSide: const BorderSide(
                          //         color: AppColors.setuGreen,
                          //         width: 1.6,
                          //       ),
                          //     ),
                          //     errorBorder: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(12),
                          //       borderSide: const BorderSide(
                          //         color: AppColors.error,
                          //         width: 1.2,
                          //       ),
                          //     ),
                          //     focusedErrorBorder: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(12),
                          //       borderSide: const BorderSide(
                          //         color: AppColors.error,
                          //         width: 1.6,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(height: 18),

                          // Field: Email
                          RichText(
                            text: const TextSpan(
                              text: 'E-mail',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              children: [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: AppColors.setuGreen2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => _clearAttentionErrors(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'name@example.com',
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
                          ),
                          const SizedBox(height: 20),

                          // Primary Action Button (Send OTP to register)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSendOtp,
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
                                      'Send OTP to register',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Already registered? Sign in Link
                          Center(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text(
                                'Already registered? Sign in',
                                style: TextStyle(
                                  color: AppColors.setuGreen,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Divider & Informational Note
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Color(0xFFF1F5F9),
                                  width: 1,
                                ),
                              ),
                            ),
                            // child: const Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Text(
                            //       'This app is for One Health Community Volunteers. Every volunteer is designated COHV and registers under one of six departments — Public Health Department, Animal Department, Wildlife Department, Environment Department, Urban Department, Rural Department — which decides what they may report.',
                            //       style: TextStyle(
                            //         fontSize: 12,
                            //         color: Color(0xFF64748B),
                            //         height: 1.45,
                            //       ),
                            //     ),
                            //     SizedBox(height: 12),
                            //     Text(
                            //       'Supervisors do not sign in here: registration approval, report verification and alert escalation happen on their own system.',
                            //       style: TextStyle(
                            //         fontSize: 12,
                            //         color: Color(0xFF64748B),
                            //         height: 1.45,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Institutional Logos (NCDC)
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
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 6. Organization Subtitle
                  const Text(
                    'National Centre for Disease Control',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
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
