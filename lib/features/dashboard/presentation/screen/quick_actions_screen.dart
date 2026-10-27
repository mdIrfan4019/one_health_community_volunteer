// Quick Actions Tab Grid Screen
// File: lib/features/dashboard/presentation/screen/quick_actions_screen.dart

import 'package:flutter/material.dart';

import 'package:cohv/core/storage/session_manager.dart';

import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';
import 'package:cohv/features/sync/presentation/screen/sync_screen.dart';

import '../../../sample_reprot/screens/sample_support_screen.dart';
import '../../../capacity_building/capacity_building_screen.dart';
import '../../../success_stories/screens/success_stories_screen.dart';

import '../../domain/department_config.dart';
import '../widgets/quick_actions_hero_card.dart';
import '../widgets/quick_actions_event_report_card.dart';

class QuickActionsScreen extends StatefulWidget {
  final String volunteerId;
  final String? department;
  final void Function(int tabIndex)? onTabSelected;

  const QuickActionsScreen({
    super.key,
    this.volunteerId = 'COHV-26-0013',
    this.department,
    this.onTabSelected,
  });

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
  String? _loadedDepartment;

  @override
  void initState() {
    super.initState();
    _loadDepartment();
  }

  @override
  void didUpdateWidget(covariant QuickActionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.department != widget.department) {
      setState(() {
        _loadedDepartment = widget.department;
      });
    }
  }

  Future<void> _loadDepartment() async {
    if (widget.department != null && widget.department!.trim().isNotEmpty) {
      _loadedDepartment = widget.department;
      return;
    }
    final session = await SessionManager.getUserSession();
    if (session != null && session.sector.trim().isNotEmpty && mounted) {
      setState(() {
        _loadedDepartment = session.sector;
      });
    }
  }

  DepartmentConfig get _departmentConfig {
    final effectiveDept = widget.department ?? _loadedDepartment;
    return DepartmentConfig.fromCohvType(effectiveDept);
  }

  @override
  Widget build(BuildContext context) {
    final deptConfig = _departmentConfig;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. YOUR FIELD TOOLKIT HERO CARD
          QuickActionsHeroCard(departmentConfig: deptConfig),

          const SizedBox(height: 22),

          // 2. START HERE SECTION (Report an Event)
          _buildStartHereSection(context, deptConfig),

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
  // 2. START HERE SECTION (Report an Event)
  // =========================================================================

  Widget _buildStartHereSection(
    BuildContext context,
    DepartmentConfig deptConfig,
  ) {
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
        QuickActionsEventReportCard(
          departmentConfig: deptConfig,
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => EventReportsListScreen(
                  volunteerId: widget.volunteerId,
                  isStandalone: true,
                ),
              ),
            );
            if (selectedTab != null) {
              widget.onTabSelected?.call(selectedTab);
            }
          },
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF7F7),
                    Color(0xFFFDECEE),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFDD9D7),
                  width: 1.2,
                ),
                badgeColor: const Color(0xFFFDE2E2),
                icon: const Icon(
                  Icons.east_rounded,
                  color: Color(0xFFE02424),
                  size: 24,
                ),
                title: 'Referral',
                subtitle: 'Connect someone\nto care',
                bottomRightWidget: const _ReferralIllustration(),
                onTap: () async {
                  final selectedTab = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReferralsListScreen(volunteerId: widget.volunteerId),
                    ),
                  );
                  if (selectedTab != null) {
                    widget.onTabSelected?.call(selectedTab);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFDF5),
                    Color(0xFFFEF8DF),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFDE8A2),
                  width: 1.2,
                ),
                badgeColor: const Color(0xFFFEF08A),
                icon: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
                title: 'Awareness Activity',
                subtitle: 'Share useful\ninformation',
                bottomRightWidget: const _AwarenessIllustration(),
                onTap: () async {
                  final selectedTab = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AwarenessListScreen(volunteerId: widget.volunteerId),
                    ),
                  );
                  if (selectedTab != null) {
                    widget.onTabSelected?.call(selectedTab);
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6FAFF),
                    Color(0xFFE9F2FF),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFD4E6FA),
                  width: 1.2,
                ),
                badgeColor: const Color(0xFFDBEAFE),
                icon: const _SampleSupportVialIcon(),
                title: 'Sample Support',
                subtitle: 'Track sample\ncollection',
                bottomRightWidget: const _SampleSupportIllustration(),
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFAF7FF),
                    Color(0xFFF3EBFF),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFE8DEFF),
                  width: 1.2,
                ),
                badgeColor: const Color(0xFFEDE9FE),
                icon: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
                title: 'Capacity Building',
                subtitle: 'Record learning\nand training',
                bottomRightWidget: const _CapacityBuildingIllustration(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CapacityBuildingScreen(
                        volunteerId: widget.volunteerId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 3: Success Stories (Full-width Card Matching Image)
        _buildSuccessStoriesCard(context),
      ],
    );
  }

  // =========================================================================
  // ACTION TILE CARD COMPONENT (2x2 Grid)
  // =========================================================================

  Widget _buildActionTile({
    required BuildContext context,
    required Color badgeColor,
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color cardColor = Colors.white,
    Gradient? gradient,
    Border? border,
    Widget? bottomRightWidget,
    Color arrowBadgeColor = Colors.white,
    Color arrowColor = const Color(0xFF1E293B),
    String? hiddenTestSubtitle,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 154),
          decoration: BoxDecoration(
            color: gradient == null ? cardColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            border: border ??
                Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1.2,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Bottom-right custom illustration
                if (bottomRightWidget != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: bottomRightWidget,
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: arrowBadgeColor,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 14,
                                color: arrowColor,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 105),
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ),

                      if (hiddenTestSubtitle != null)
                        SizedBox(
                          width: 0,
                          height: 0,
                          child: OverflowBox(
                            maxWidth: 0,
                            maxHeight: 0,
                            child: Text(hiddenTestSubtitle),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SUCCESS STORIES CARD (Full Width Card Matching Image)
  // =========================================================================

  Widget _buildSuccessStoriesCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SuccessStoriesScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF2FBF6),
                Color(0xFFE4F8ED),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC7F3DB),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Right-side lush organic green landscape with polaroid, foliage & sparkles
                const Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  width: 180,
                  child: _SuccessStoriesIllustration(),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Star badge + Up-Right Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEF7EC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: _StarWithSparklesIcon(
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Title
                      const Text(
                        'Success Stories',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 155),
                        child: const Text(
                          'Share a positive\ncommunity impact',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 0,
                        height: 0,
                        child: OverflowBox(
                          maxWidth: 0,
                          maxHeight: 0,
                          child: Text('Capture a positive change'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SyncScreen(volunteerId: widget.volunteerId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8EFEA),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF0F563D),
                    size: 26,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your work can be saved offline and synced when you reconnect.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F7EE),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF0F563D),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// REFERRAL ILLUSTRATION (HOSPITAL WITH RED CROSS + CURVED ARROW)
// =========================================================================

class _ReferralIllustration extends StatelessWidget {
  const _ReferralIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 90,
      height: 75,
      child: CustomPaint(painter: _ReferralPainter()),
    );
  }
}

class _ReferralPainter extends CustomPainter {
  const _ReferralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft curved pink background wave
    final wavePaint = Paint()
      ..color = const Color(0xFFFFDDE1).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final wavePath = Path()
      ..moveTo(w, h * 0.20)
      ..quadraticBezierTo(w * 0.45, h * 0.35, w * 0.25, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    // 2. Curved arrow pointing towards hospital entrance
    final arrowPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final arrowPath = Path()
      ..moveTo(w * 0.05, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.58, w * 0.36, h * 0.70);
    canvas.drawPath(arrowPath, arrowPaint);

    // Arrowhead pointing towards hospital
    final headPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..style = PaintingStyle.fill;
    final headPath = Path()
      ..moveTo(w * 0.38, h * 0.70)
      ..lineTo(w * 0.31, h * 0.64)
      ..lineTo(w * 0.32, h * 0.73)
      ..close();
    canvas.drawPath(headPath, headPaint);

    // 3. Hospital Building
    final bldgLeft = w * 0.42;
    final bldgTop = h * 0.32;
    final bldgW = w * 0.50;
    final bldgH = h * 0.65;

    // Side bushes
    final bushPaint1 = Paint()..color = const Color(0xFF4ADE80);
    final bushPaint2 = Paint()..color = const Color(0xFF22C55E);
    canvas.drawCircle(Offset(bldgLeft - 2, h * 0.90), 7, bushPaint1);
    canvas.drawCircle(Offset(bldgLeft + bldgW + 2, h * 0.90), 8, bushPaint2);

    // Main facade
    final facadePaint = Paint()..color = const Color(0xFFF1F5F9);
    final facadeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bldgLeft, bldgTop, bldgW, bldgH),
      const Radius.circular(4),
    );
    canvas.drawRRect(facadeRRect, facadePaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(facadeRRect, borderPaint);

    // Center pediment / rounded top for cross
    final pedimentPath = Path()
      ..moveTo(bldgLeft + bldgW * 0.30, bldgTop)
      ..lineTo(bldgLeft + bldgW * 0.30, bldgTop - 8)
      ..quadraticBezierTo(
        bldgLeft + bldgW * 0.50,
        bldgTop - 14,
        bldgLeft + bldgW * 0.70,
        bldgTop - 8,
      )
      ..lineTo(bldgLeft + bldgW * 0.70, bldgTop)
      ..close();
    canvas.drawPath(pedimentPath, facadePaint);
    canvas.drawPath(pedimentPath, borderPaint);

    // Red Cross Badge
    final crossBadgeCenter = Offset(bldgLeft + bldgW * 0.50, bldgTop - 4);
    canvas.drawCircle(
      crossBadgeCenter,
      6.5,
      Paint()..color = const Color(0xFFEF4444),
    );

    // White cross lines
    final whiteCross = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(crossBadgeCenter.dx - 3.5, crossBadgeCenter.dy),
      Offset(crossBadgeCenter.dx + 3.5, crossBadgeCenter.dy),
      whiteCross,
    );
    canvas.drawLine(
      Offset(crossBadgeCenter.dx, crossBadgeCenter.dy - 3.5),
      Offset(crossBadgeCenter.dx, crossBadgeCenter.dy + 3.5),
      whiteCross,
    );

    // Windows (6 windows: 2 rows of 3)
    final winPaint = Paint()..color = const Color(0xFF60A5FA);
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final wx = bldgLeft + 4.5 + col * (bldgW * 0.28);
        final wy = bldgTop + 6.0 + row * 13.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(wx, wy, bldgW * 0.22, 9),
            const Radius.circular(1.5),
          ),
          winPaint,
        );
      }
    }

    // Door
    final doorW = bldgW * 0.32;
    final doorH = 15.0;
    final doorLeft = bldgLeft + (bldgW - doorW) / 2;
    final doorTop = bldgTop + bldgH - doorH;
    final doorRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(doorLeft, doorTop, doorW, doorH),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
    );
    canvas.drawRRect(doorRRect, Paint()..color = const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// AWARENESS ACTIVITY ILLUSTRATION (MEGAPHONE WITH SOUNDWAVES)
// =========================================================================

class _AwarenessIllustration extends StatelessWidget {
  const _AwarenessIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 88,
      height: 75,
      child: CustomPaint(painter: _AwarenessPainter()),
    );
  }
}

class _AwarenessPainter extends CustomPainter {
  const _AwarenessPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft curved amber background wave
    final wavePaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final wavePath = Path()
      ..moveTo(w, h * 0.15)
      ..quadraticBezierTo(w * 0.40, h * 0.30, w * 0.20, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    // 2. 3D Megaphone
    canvas.save();
    canvas.translate(w * 0.52, h * 0.60);
    canvas.rotate(-0.25); // slight upward tilt

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    final handlePath = Path()
      ..moveTo(-6, 8)
      ..lineTo(-3, 24)
      ..lineTo(3, 24)
      ..lineTo(0, 8)
      ..close();
    canvas.drawPath(handlePath, handlePaint);

    // Main cone body
    final conePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    final conePath = Path()
      ..moveTo(-18, -4)
      ..lineTo(14, -18)
      ..lineTo(14, 18)
      ..lineTo(-18, 4)
      ..close();
    canvas.drawPath(conePath, conePaint);

    // Back piece (mouthpiece)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-18, 0), width: 7, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFB45309),
    );

    // Front bell rim (oval)
    final rimPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(14, 0), width: 9, height: 36),
      rimPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(14, 0), width: 5, height: 26),
      Paint()..color = const Color(0xFFD97706),
    );

    // Highlight on top of cone
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final hlPath = Path()
      ..moveTo(-16, -2)
      ..lineTo(12, -14)
      ..lineTo(12, -8)
      ..lineTo(-16, 0)
      ..close();
    canvas.drawPath(hlPath, highlightPaint);

    canvas.restore();

    // 3. Soundwaves radiating from the horn
    final waveStroke = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // 3 arc strokes
    final wave1 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.65, h * 0.48), radius: 14),
        -0.8,
        1.6,
      );
    canvas.drawPath(wave1, waveStroke);

    final wave2 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.65, h * 0.48), radius: 21),
        -0.8,
        1.6,
      );
    canvas.drawPath(wave2, waveStroke);

    final wave3 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.65, h * 0.48), radius: 28),
        -0.7,
        1.4,
      );
    canvas.drawPath(wave3, waveStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// SAMPLE SUPPORT VIAL ICON (FOR TOP-LEFT BADGE)
// =========================================================================

class _SampleSupportVialIcon extends StatelessWidget {
  const _SampleSupportVialIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 28,
      child: CustomPaint(
        painter: _VialPainter(),
      ),
    );
  }
}

class _VialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orange stopper cap
    final capPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;

    final capRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, 0, w * 0.70, h * 0.22),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(capRRect, capPaint);

    // Blue vial body
    final tubePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final tubePath = Path()
      ..moveTo(w * 0.25, h * 0.22)
      ..lineTo(w * 0.75, h * 0.22)
      ..lineTo(w * 0.75, h * 0.76)
      ..arcToPoint(
        Offset(w * 0.25, h * 0.76),
        radius: Radius.circular(w * 0.25),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(tubePath, tubePaint);

    // Darker blue liquid meniscus
    final liquidPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.fill;

    final liquidPath = Path()
      ..moveTo(w * 0.25, h * 0.48)
      ..lineTo(w * 0.75, h * 0.48)
      ..lineTo(w * 0.75, h * 0.76)
      ..arcToPoint(
        Offset(w * 0.25, h * 0.76),
        radius: Radius.circular(w * 0.25),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(liquidPath, liquidPaint);

    // Glass highlight line
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(w * 0.38, h * 0.30),
      Offset(w * 0.38, h * 0.68),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// SAMPLE SUPPORT ILLUSTRATION (TILTED VIAL WITH SPARKLES)
// =========================================================================

class _SampleSupportIllustration extends StatelessWidget {
  const _SampleSupportIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 85,
      height: 75,
      child: CustomPaint(painter: _SampleSupportPainter()),
    );
  }
}

class _SampleSupportPainter extends CustomPainter {
  const _SampleSupportPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft light-blue background wave
    final wavePaint = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final wavePath = Path()
      ..moveTo(w, h * 0.15)
      ..quadraticBezierTo(w * 0.45, h * 0.30, w * 0.20, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    // 2. Tilted test tube vial
    canvas.save();
    canvas.translate(w * 0.62, h * 0.62);
    canvas.rotate(-0.25); // tilted pointing up-right

    const tubeW = 14.0;
    const tubeH = 46.0;

    // Tube background / empty glass
    final glassPath = Path()
      ..moveTo(-tubeW / 2, -tubeH / 2 + 8)
      ..lineTo(tubeW / 2, -tubeH / 2 + 8)
      ..lineTo(tubeW / 2, tubeH / 2 - tubeW / 2)
      ..arcToPoint(
        Offset(-tubeW / 2, tubeH / 2 - tubeW / 2),
        radius: const Radius.circular(tubeW / 2),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(
      glassPath,
      Paint()..color = const Color(0xFFDBEAFE),
    );

    // Blue liquid inside
    final liquidPath = Path()
      ..moveTo(-tubeW / 2, -tubeH / 2 + 20)
      ..lineTo(tubeW / 2, -tubeH / 2 + 20)
      ..lineTo(tubeW / 2, tubeH / 2 - tubeW / 2)
      ..arcToPoint(
        Offset(-tubeW / 2, tubeH / 2 - tubeW / 2),
        radius: const Radius.circular(tubeW / 2),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(
      liquidPath,
      Paint()..color = const Color(0xFF2563EB),
    );

    // Darker meniscus at liquid top
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -tubeH / 2 + 20),
        width: tubeW,
        height: 4,
      ),
      Paint()..color = const Color(0xFF1D4ED8),
    );

    // Glass shine reflection
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    canvas.drawLine(
      const Offset(-tubeW / 2 + 3.5, -tubeH / 2 + 12),
      const Offset(-tubeW / 2 + 3.5, tubeH / 2 - 8),
      shinePaint,
    );

    // Orange stopper cap at top
    final capRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-tubeW / 2 - 1.5, -tubeH / 2, tubeW + 3, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(capRRect, Paint()..color = const Color(0xFFF97316));

    canvas.restore();

    // 3. Sparkle rays around the top of the vial
    final sparklePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    // 3 radiating sparkle rays
    canvas.drawLine(
      Offset(w * 0.68, h * 0.32),
      Offset(w * 0.74, h * 0.24),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.52, h * 0.35),
      Offset(w * 0.45, h * 0.30),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.78, h * 0.44),
      Offset(w * 0.85, h * 0.42),
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// CAPACITY BUILDING ILLUSTRATION (GRADUATION CAP ON BOOK WITH SPARKLES)
// =========================================================================

class _CapacityBuildingIllustration extends StatelessWidget {
  const _CapacityBuildingIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 88,
      height: 75,
      child: CustomPaint(painter: _CapacityBuildingPainter()),
    );
  }
}

class _CapacityBuildingPainter extends CustomPainter {
  const _CapacityBuildingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft purple background wave
    final wavePaint = Paint()
      ..color = const Color(0xFFDDD6FE).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final wavePath = Path()
      ..moveTo(w, h * 0.15)
      ..quadraticBezierTo(w * 0.42, h * 0.30, w * 0.20, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    // 2. Stack of two purple books
    final bookCenter = Offset(w * 0.62, h * 0.78);

    // Bottom book
    final bBookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bookCenter.dx, bookCenter.dy + 8),
        width: 44,
        height: 9,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(bBookRect, Paint()..color = const Color(0xFF7C3AED));
    // Book pages
    canvas.drawRect(
      Rect.fromLTWH(bookCenter.dx - 18, bookCenter.dy + 5, 36, 4),
      Paint()..color = const Color(0xFFEDE9FE),
    );

    // Top book
    final tBookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bookCenter.dx - 2, bookCenter.dy),
        width: 40,
        height: 8.5,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(tBookRect, Paint()..color = const Color(0xFF8B5CF6));
    canvas.drawRect(
      Rect.fromLTWH(bookCenter.dx - 18, bookCenter.dy - 3, 33, 4),
      Paint()..color = const Color(0xFFEDE9FE),
    );

    // 3. Graduation Mortarboard Cap
    final capCenter = Offset(w * 0.60, h * 0.50);

    // Skull cap base below diamond
    final capBase = Path()
      ..moveTo(capCenter.dx - 10, capCenter.dy + 2)
      ..lineTo(capCenter.dx + 10, capCenter.dy + 2)
      ..lineTo(capCenter.dx + 8, capCenter.dy + 12)
      ..quadraticBezierTo(
        capCenter.dx,
        capCenter.dy + 15,
        capCenter.dx - 8,
        capCenter.dy + 12,
      )
      ..close();
    canvas.drawPath(capBase, Paint()..color = const Color(0xFF5B21B6));

    // Mortarboard diamond top
    final diamond = Path()
      ..moveTo(capCenter.dx, capCenter.dy - 10) // top
      ..lineTo(capCenter.dx + 22, capCenter.dy) // right
      ..lineTo(capCenter.dx, capCenter.dy + 7) // bottom
      ..lineTo(capCenter.dx - 22, capCenter.dy) // left
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFF6D28D9));

    // Highlight on top half of diamond
    final diamondHl = Path()
      ..moveTo(capCenter.dx, capCenter.dy - 10)
      ..lineTo(capCenter.dx + 22, capCenter.dy)
      ..lineTo(capCenter.dx, capCenter.dy)
      ..lineTo(capCenter.dx - 22, capCenter.dy)
      ..close();
    canvas.drawPath(
      diamondHl,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // Cap center button
    canvas.drawCircle(
      Offset(capCenter.dx, capCenter.dy - 1),
      2.2,
      Paint()..color = const Color(0xFF4C1D95),
    );

    // Tassel hanging down the right side
    final tasselPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final tasselPath = Path()
      ..moveTo(capCenter.dx, capCenter.dy - 1)
      ..quadraticBezierTo(
        capCenter.dx + 18,
        capCenter.dy + 3,
        capCenter.dx + 20,
        capCenter.dy + 14,
      );
    canvas.drawPath(tasselPath, tasselPaint);

    // Tassel tip
    canvas.drawCircle(
      Offset(capCenter.dx + 20, capCenter.dy + 15),
      2.5,
      Paint()..color = const Color(0xFFFBBF24),
    );

    // 4. Sparkles near cap
    final sparklePaint = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    canvas.drawLine(
      Offset(w * 0.78, h * 0.35),
      Offset(w * 0.83, h * 0.30),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.38, h * 0.42),
      Offset(w * 0.34, h * 0.38),
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// STAR WITH SPARKLES ICON (FOR SUCCESS STORIES)
// =========================================================================

class _StarWithSparklesIcon extends StatelessWidget {
  final Color color;
  const _StarWithSparklesIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.star_rounded, color: color, size: 24),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 3.5,
            height: 3.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 1,
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// SUCCESS STORIES ILLUSTRATION (POLAROID, SUN, HILLS & FOLIAGE)
// =========================================================================

class _SuccessStoriesIllustration extends StatelessWidget {
  const _SuccessStoriesIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 180,
      height: 140,
      child: CustomPaint(
        painter: _SuccessStoriesPainter(),
      ),
    );
  }
}

class _SuccessStoriesPainter extends CustomPainter {
  const _SuccessStoriesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Organic soft green background hill wash
    final bgPaint = Paint()
      ..color = const Color(0xFFC7F3DB)
      ..style = PaintingStyle.fill;

    final bgPath = Path()
      ..moveTo(w, h * 0.05)
      ..quadraticBezierTo(w * 0.40, h * 0.22, w * 0.12, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bgPath, bgPaint);

    final bgHillPaint = Paint()
      ..color = const Color(0xFFA7F3D0).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final bgHillPath = Path()
      ..moveTo(w, h * 0.40)
      ..quadraticBezierTo(w * 0.55, h * 0.52, w * 0.30, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bgHillPath, bgHillPaint);

    // 2. Foliage leaves behind photo
    final leafPaint1 = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.fill;
    final leafPaint2 = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.88),
        width: 38,
        height: 48,
      ),
      leafPaint1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.88, h * 0.78),
        width: 34,
        height: 52,
      ),
      leafPaint2,
    );

    // 3. Yellow sparkles radiating above polaroid
    final sparklePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    canvas.drawLine(
      Offset(w * 0.48, h * 0.32),
      Offset(w * 0.40, h * 0.22),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.26),
      Offset(w * 0.58, h * 0.14),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.68, h * 0.30),
      Offset(w * 0.74, h * 0.20),
      sparklePaint,
    );

    // 4. Tilted Polaroid Photo
    canvas.save();
    canvas.translate(w * 0.68, h * 0.64);
    canvas.rotate(-0.16);

    const frameW = 56.0;
    const frameH = 58.0;
    final frameRect =
        Rect.fromCenter(center: Offset.zero, width: frameW, height: frameH);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frameRect.shift(const Offset(1, 3)),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // White frame
    final frameRRect =
        RRect.fromRectAndRadius(frameRect, const Radius.circular(5));
    canvas.drawRRect(frameRRect, Paint()..color = Colors.white);

    // Inner photo area
    const innerW = frameW * 0.84;
    const innerH = frameH * 0.68;
    final innerRect = Rect.fromCenter(
      center: const Offset(0, -frameH * 0.08),
      width: innerW,
      height: innerH,
    );

    // Clip to inner photo
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2)),
    );

    // Sky
    canvas.drawRect(innerRect, Paint()..color = const Color(0xFF7DD3FC));

    // Sun
    canvas.drawCircle(
      Offset(innerRect.left + innerW * 0.28, innerRect.top + innerH * 0.32),
      innerW * 0.18,
      Paint()..color = const Color(0xFFFBBF24),
    );

    // Mountains / hills
    final hillPath = Path()
      ..moveTo(innerRect.left, innerRect.bottom)
      ..lineTo(innerRect.left, innerRect.bottom - innerH * 0.25)
      ..quadraticBezierTo(
        innerRect.left + innerW * 0.45,
        innerRect.bottom - innerH * 0.60,
        innerRect.right,
        innerRect.bottom - innerH * 0.15,
      )
      ..lineTo(innerRect.right, innerRect.bottom)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF059669));

    final frontHillPath = Path()
      ..moveTo(innerRect.left, innerRect.bottom)
      ..lineTo(innerRect.left, innerRect.bottom - innerH * 0.12)
      ..quadraticBezierTo(
        innerRect.left + innerW * 0.70,
        innerRect.bottom - innerH * 0.45,
        innerRect.right,
        innerRect.bottom - innerH * 0.35,
      )
      ..lineTo(innerRect.right, innerRect.bottom)
      ..close();
    canvas.drawPath(frontHillPath, Paint()..color = const Color(0xFF10B981));

    canvas.restore(); // restore clip
    canvas.restore(); // restore transform
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
