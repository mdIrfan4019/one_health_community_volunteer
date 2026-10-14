import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../domain/auth_models.dart';
import '../widgets/attention_banner.dart';
import '../widgets/one_health_logo.dart';
import 'volunteer_registration_screen.dart';


class OtpVerificationScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpVerificationScreen({
    super.key,
    required this.mobileNumber,
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

//   Future<void> _handleVerify() async {
//     _clearAttentionErrors();
//     final otp = _otpController.text.trim();

//     if (otp.length != 6) {
//       setState(() {
//         _attentionErrors = ['Please enter all 6 digits of the OTP.'];
//       });
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final request = VerifyOtpRequest(
//         mobileNumber: widget.mobileNumber,
//         otp: otp,
//       );
//       final session = await _apiService.verifyOtp(request);

//     //   if (!mounted) return;
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     SnackBar(
//     //       backgroundColor: AppColors.success,
//     //       content: Text('Verified successfully! Welcome, ${session.fullName} (${session.volunteerId})'),
//     //     ),
//     //   );

//           if (!mounted) return;

//       // Navigate to the Volunteer Registration Screen
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => VolunteerRegistrationScreen(
//             mobileNumber: widget.mobileNumber,
//           ),
//         ),
//       );


//       // TODO: Navigate to Dashboard / Home screen once created
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _attentionErrors = [e.toString().replaceAll('Exception: ', '')];
//       });
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

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
        otp: otp,
      );
      await _apiService.verifyOtp(request);

      if (!mounted) return;

      // Navigate directly to Volunteer Registration Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VolunteerRegistrationScreen(
            mobileNumber: widget.mobileNumber,
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Branding Header
                  const OneHealthLogo(),
                  const SizedBox(height: 18),
                  const Text(
                    'One Health Community Volunteer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Field reporting application',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Verification Card
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify your mobile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A 6-digit OTP has been sent to ${widget.mobileNumber}.',
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

                        // 3. Six-Digit Visual Boxes with hidden reliable controller
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final text = _otpController.text;
                                  final isFilled = index < text.length;
                                  final isCurrent = index == text.length && _focusNode.hasFocus;
                                  final digit = isFilled ? text[index] : '';

                                  return Container(
                                    width: 44,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : (isFilled ? AppColors.textDark : AppColors.border),
                                        width: isCurrent ? 1.8 : 1.2,
                                      ),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
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

                        // Prototype helper note
                        const Text(
                          'Prototype build — any six digits are accepted. Production verifies the OTP server-side.',
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
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                                      fontSize: 15,
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
                            child: const Text(
                              'Change mobile number',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Footer Note
                  const Text(
                    'Prototype build for design review.\nRecords are held on this device only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      height: 1.4,
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
