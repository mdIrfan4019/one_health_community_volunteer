import 'package:flutter/material.dart';
import 'package:cohv/features/dashboard/domain/department_config.dart';
import 'volunteer_profile_avatar.dart';
import 'dashboard_event_report_card.dart';

/// Reusable Dashboard Hero Card featuring:
/// - Volunteer greeting and dynamic profile image with fallback icon
/// - Department-specific intro title and description
/// - Department badge with dynamic icon, name, and location breadcrumb
/// - Integrated "Report an event" action card
class DashboardHeroCard extends StatelessWidget {
  final DepartmentConfig departmentConfig;
  final String volunteerName;
  final String volunteerId;
  final String? photoPath;
  final String? authToken;
  final String locationBreadcrumb;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onReportEventTap;

  const DashboardHeroCard({
    super.key,
    required this.departmentConfig,
    required this.volunteerName,
    this.volunteerId = '',
    this.photoPath,
    this.authToken,
    this.locationBreadcrumb = 'Mannanur · Amrabad · Nagarkurnool',
    this.onAvatarTap,
    this.onReportEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = volunteerName.trim().isNotEmpty
        ? volunteerName.trim().split(' ').first
        : 'Alex';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF136B4F),
            Color(0xFF197653),
            Color(0xFF0F563D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF136B4F).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background organic curves
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: const _DashboardHeroBackgroundPainter(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Row: Greeting & Profile Photo Avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SETU FIELDSPACE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Good day, $displayName 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            departmentConfig.dashboardIntroTitle,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            departmentConfig.dashboardDescription,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Avatar button with real profile photo from /api/auth/me
                    VolunteerProfileAvatar(
                      photoPath: photoPath,
                      authToken: authToken,
                      size: 48,
                      onTap: onAvatarTap,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 2. Middle Sub-Card: Department & Location Breadcrumb
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          departmentConfig.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              departmentConfig.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationBreadcrumb.isNotEmpty
                                  ? locationBreadcrumb
                                  : 'Mannanur · Amrabad · Nagarkurnool',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Bottom Sub-Card: Reusable "Report an event" action
                DashboardEventReportCard(
                  departmentConfig: departmentConfig,
                  onTap: onReportEventTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroBackgroundPainter extends CustomPainter {
  const _DashboardHeroBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32;

    final path1 = Path();
    path1.moveTo(size.width * 0.45, -20);
    path1.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.5,
      size.width + 30,
      size.height * 0.35,
    );
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44;

    final path2 = Path();
    path2.moveTo(size.width * 0.25, -20);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.7,
      size.width + 30,
      size.height * 0.55,
    );
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
