// Quick Actions Tab Grid Screen
// File: lib/features/dashboard/presentation/screen/quick_actions_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';
import 'package:cohv/features/sync/presentation/screen/sync_screen.dart';

import '../../../sample_reprot/screens/sample_support_screen.dart';
import '../../../capacity_building/capacity_building_screen.dart';
import '../../../success_stories/screens/success_stories_screen.dart';

class QuickActionsScreen extends StatelessWidget {
  final String volunteerId;
  final void Function(int tabIndex)? onTabSelected;

  const QuickActionsScreen({
    super.key,
    this.volunteerId = 'COHV-26-0013',
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. YOUR FIELD TOOLKIT HERO CARD
          _buildHeroCard(),

          const SizedBox(height: 22),

          // 2. START HERE SECTION (Report an Event)
          _buildStartHereSection(context),

          const SizedBox(height: 22),

          // 3. MORE WAYS TO HELP SECTION (5 Action Cards)
          _buildMoreWaysSection(context),

          const SizedBox(height: 18),

          // 4. "OUT IN THE FIELD?" BOTTOM BANNER CARD
          _buildOfflineBannerCard(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. HERO CARD: "YOUR FIELD TOOLKIT"
  // =========================================================================

  Widget _buildHeroCard() {
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
          // Background organic curves and concentric arcs
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _ToolkitCardBackgroundPainter(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top line: Label + Star/Sparkle icon button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR FIELD TOOLKIT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.flare_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Main Heading + Avatar / Person Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'People first',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture health concerns and community needs.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Bottom Line: Active Dot + "Ready when you are" + Arrow down
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ready when you are',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.south_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. START HERE SECTION (Report an Event)
  // =========================================================================

  Widget _buildStartHereSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'START HERE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              '01 / QUICK CAPTURE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final selectedTab = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) => EventReportsListScreen(
                    volunteerId: volunteerId,
                    isStandalone: true,
                  ),
                ),
              );
              if (selectedTab != null) {
                onTabSelected?.call(selectedTab);
              }
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F7EE),
                    Color(0xFFF3FAF5),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFD1F2DD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF136B4F).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1F2DD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.setuGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report an event',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF136B4F),
                          ),
                        ),
                        IgnorePointer(
                          child: SizedBox(
                            height: 1,
                            child: Opacity(
                              opacity: 0.0,
                              child: Text('Report Event'),
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Open this field workflow',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF136B4F),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 3. MORE WAYS TO HELP SECTION (5 Action Cards)
  // =========================================================================

  Widget _buildMoreWaysSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MORE WAYS TO HELP',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              '05 ACTIONS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1: Referral & Awareness Activity
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                badgeColor: const Color(0xFFFCE7F3),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFBE185D),
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 16,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                title: 'Referral',
                subtitle: 'Connect someone to care',
                onTap: () async {
                  final selectedTab = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReferralsListScreen(volunteerId: volunteerId),
                    ),
                  );
                  if (selectedTab != null) {
                    onTabSelected?.call(selectedTab);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                badgeColor: const Color(0xFFFEF3C7),
                icon: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
                title: 'Awareness Activity',
                subtitle: 'Share useful information',
                onTap: () async {
                  final selectedTab = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AwarenessListScreen(volunteerId: volunteerId),
                    ),
                  );
                  if (selectedTab != null) {
                    onTabSelected?.call(selectedTab);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2: Sample Support & Capacity Building
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                badgeColor: const Color(0xFFEFF6FF),
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Container(
                      width: 12,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(6)),
                      ),
                    ),
                  ],
                ),
                title: 'Sample Support',
                subtitle: 'Track sample collection',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SampleSupportScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                badgeColor: const Color(0xFFF3E8FF),
                icon: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
                title: 'Capacity Building',
                subtitle: 'Record learning and training',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CapacityBuildingScreen(
                        volunteerId: volunteerId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 3: Success Stories (in left column, matching Screenshot 2)
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                badgeColor: const Color(0xFFFCE7F3),
                icon: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFDB2777),
                  size: 24,
                ),
                title: 'Success Stories',
                subtitle: 'Capture a positive change',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuccessStoriesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // ACTION TILE CARD COMPONENT
  // =========================================================================

  Widget _buildActionTile({
    required BuildContext context,
    required Color badgeColor,
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon badge + Up-Right Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: icon),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.north_east_rounded,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. "OUT IN THE FIELD?" BANNER CARD
  // =========================================================================

  Widget _buildOfflineBannerCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SyncScreen(volunteerId: volunteerId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.setuGreen,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Out in the field?',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your work can be saved offline and synced when you reconnect.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolkitCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36;

    final path1 = Path();
    path1.moveTo(size.width * 0.45, -20);
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.35,
      size.width + 20,
      size.height * 0.25,
    );
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Bottom right concentric arcs matching screenshot
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 1.05),
      size.width * 0.24,
      paint2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 1.05),
      size.width * 0.42,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
