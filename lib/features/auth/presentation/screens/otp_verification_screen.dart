import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../domain/auth_models.dart';
import '../widgets/attention_banner.dart';
import '../widgets/one_health_logo.dart';
import 'volunteer_registration_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? mobileNumber;
  final String? email;

  const OtpVerificationScreen({
    super.key,
    this.mobileNumber,
    this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthApiService _apiService = AuthApiService();

  bool _isLoading = false;
  List<String> _attentionErrors = [];

  @override
  void initState() {
    super.initState();
    // Auto-focus the OTP input after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearAttentionErrors() {
    if (_attentionErrors.isNotEmpty) {
      setState(() => _attentionErrors = []);
    }
  }

  Future<void> _handleVerify() async {
    _clearAttentionErrors();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _attentionErrors = ['Please enter all 6 digits of the OTP.'];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = VerifyOtpRequest(
        mobileNumber: widget.mobileNumber,
        email: widget.email,
        otp: otp,
        purpose: 'REGISTRATION',
      );
      await _apiService.verifyOtp(request);

      if (!mounted) return;

      // Navigate directly to Volunteer Registration Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VolunteerRegistrationScreen(
            mobileNumber: widget.mobileNumber,
            email: widget.email,
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

                  // 4. Verification Card
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.email != null && widget.email!.isNotEmpty)
                              ? 'Verify your email'
                              : 'Verify your mobile',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A 6-digit OTP has been sent to ${widget.email ?? widget.mobileNumber ?? "your email"}.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner (Section 8 Amber-to-Orange ramp standard)
                        if (_attentionErrors.isNotEmpty) ...[
                          AttentionBanner(errors: _attentionErrors),
                          const SizedBox(height: 18),
                        ],

                        // Visual OTP Input Boxes with hidden text controller
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Invisible TextField to receive native keyboard input & clipboard paste
                            Opacity(
                              opacity: 0.0,
                              child: TextField(
                                controller: _otpController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onChanged: (val) {
                                  setState(() {});
                                  _clearAttentionErrors();
                                  if (val.length == 6) {
                                    _handleVerify();
                                  }
                                },
                              ),
                            ),

                            // Visual 6 individual rounded boxes
                            GestureDetector(
                              onTap: () => _focusNode.requestFocus(),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final text = _otpController.text;
                                  final isFilled = index < text.length;
                                  final isCurrent = index == text.length &&
                                      _focusNode.hasFocus;
                                  final digit =
                                      isFilled ? text[index] : '';

                                  return Container(
                                    width: 44,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.setuGreen
                                            : (isFilled
                                                ? AppColors.textDark
                                                : AppColors.border),
                                        width: isCurrent ? 1.8 : 1.2,
                                      ),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: AppColors.setuGreen
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      digit,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Verification helper note
                        const Text(
                          'Enter the 6-digit verification code sent to your email. Server verifies OTP (break-glass testing accepts MASTER_OTP).',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Verify Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.setuGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.setuGreen.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Change Mobile Number Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              (widget.email != null && widget.email!.isNotEmpty)
                                  ? 'Change email'
                                  : 'Change mobile number',
                              style: const TextStyle(
                                color: AppColors.setuGreen,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
