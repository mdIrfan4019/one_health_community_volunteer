import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sign_in_screen.dart';

class AwaitingApprovalScreen extends StatelessWidget {
  final String fullName;
  final String volunteerId;
  final String supervisorStatus;
  final String accountStatus;

  const AwaitingApprovalScreen({
    super.key,
    required this.fullName,
    required this.volunteerId,
    this.supervisorStatus = 'Assigned on approval',
    this.accountStatus = 'Inactive',
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F7F4),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. One Health Logo in circular container
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/one_health_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Titles
                  const Text(
                    'Awaiting approval',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B6A4C),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your registration has been submitted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // 3. Status Information Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          label: 'Volunteer',
                          value: fullName,
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 28,
                          thickness: 1,
                        ),
                        _buildDetailRow(
                          label: 'Volunteer ID',
                          value: volunteerId,
                          valueColor: const Color(0xFF1B7657),
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 28,
                          thickness: 1,
                        ),
                        _buildDetailRow(
                          label: 'Reporting supervisor',
                          value: supervisorStatus,
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 28,
                          thickness: 1,
                        ),
                        _buildDetailRow(
                          label: 'Account status',
                          value: accountStatus,
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFF1F5F9),
                          height: 28,
                          thickness: 1,
                        ),
                        const Text(
                          'Your supervisor approves the registration and activates the account. Reporting opens once that is done.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Back to Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const SignInScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: const Color(0xFF1B6A4C),
                            ),
                            child: const Text(
                              'Back to sign in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B6A4C),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4. Footer Text
                  const Text(
                    'Records are held on this device only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
