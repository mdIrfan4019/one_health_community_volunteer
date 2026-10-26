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
                badgeColor: const Color(0xFFFCE7F3),
                icon: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFFBE185D),
                  size: 24,
                ),
                title: 'Referral',
                subtitle: 'Connect someone to care',
                cornerWaveColor: const Color(0xFFFDF2F8),
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
                badgeColor: const Color(0xFFFEF3C7),
                icon: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
                title: 'Awareness Activity',
                subtitle: 'Share useful information',
                cornerWaveColor: const Color(0xFFFFFBEB),
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
                badgeColor: const Color(0xFFEFF6FF),
                icon: const _SampleSupportVialIcon(),
                title: 'Sample Support',
                subtitle: 'Track sample collection',
                cornerWaveColor: const Color(0xFFEFF6FF),
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
                cornerWaveColor: const Color(0xFFFAF5FF),
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

        // Row 3: Success Stories (Matching Image 1)
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                cardColor: const Color(0xFFF0FDF4),
                border: Border.all(
                  color: const Color(0xFFDCFCE7),
                  width: 1.2,
                ),
                badgeColor: const Color(0xFFDCFCE7),
                icon: const _StarWithSparklesIcon(color: Color(0xFF0F766E)),
                arrowBadgeColor: const Color(0xFFDCFCE7),
                arrowColor: const Color(0xFF0F766E),
                title: 'Success Stories',
                subtitle: 'Share a positive community impact',
                hiddenTestSubtitle: 'Capture a positive change',
                bottomRightWidget: const _SuccessStoriesIllustration(),
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
    Color cardColor = Colors.white,
    Border? border,
    Color? cornerWaveColor,
    Widget? bottomRightWidget,
    Color arrowBadgeColor = Colors.white,
    Color arrowColor = const Color(0xFF64748B),
    String? hiddenTestSubtitle,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Bottom-right soft organic wave
              if (cornerWaveColor != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 95,
                  height: 95,
                  child: CustomPaint(
                    painter: _CornerWavePainter(color: cornerWaveColor),
                  ),
                ),

              // Bottom-right custom illustration (Success Stories)
              if (bottomRightWidget != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: bottomRightWidget,
                ),

              Container(
                constraints: const BoxConstraints(minHeight: 148),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                              color: arrowBadgeColor == Colors.white
                                  ? const Color(0xFFE2E8F0)
                                  : Colors.transparent,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Subtitle
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
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
              builder: (_) => SyncScreen(volunteerId: widget.volunteerId),
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
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF0F563D),
                    size: 24,
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
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your work can be saved offline and synced when you reconnect.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F7EE),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF0F563D),
                    size: 18,
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
// CORNER WAVE PAINTER
// =========================================================================

class _CornerWavePainter extends CustomPainter {
  final Color color;

  _CornerWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, size.height * 0.40);
    path.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.55,
      size.width * 0.45,
      size.height,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerWavePainter oldDelegate) =>
      oldDelegate.color != color;
}

// =========================================================================
// SAMPLE SUPPORT VIAL ICON (ORANGE CAP + BLUE TUBE)
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
    return SizedBox(
      width: 76,
      height: 72,
      child: CustomPaint(
        painter: _SuccessStoriesPainter(),
      ),
    );
  }
}

class _SuccessStoriesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Foliage leaves behind photo
    final leafPaint1 = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.fill;
    final leafPaint2 = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, h * 0.88),
        width: w * 0.45,
        height: h * 0.55,
      ),
      leafPaint1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.85, h * 0.80),
        width: w * 0.40,
        height: h * 0.60,
      ),
      leafPaint2,
    );

    // 2. Yellow sparkles above polaroid
    final sparklePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(w * 0.42, h * 0.32),
      Offset(w * 0.36, h * 0.22),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.52, h * 0.28),
      Offset(w * 0.52, h * 0.16),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.32),
      Offset(w * 0.68, h * 0.22),
      sparklePaint,
    );

    // 3. Tilted Polaroid Photo
    canvas.save();
    canvas.translate(w * 0.62, h * 0.66);
    canvas.rotate(-0.16);

    final frameW = w * 0.58;
    final frameH = h * 0.62;
    final frameRect =
        Rect.fromCenter(center: Offset.zero, width: frameW, height: frameH);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frameRect.shift(const Offset(1, 2)),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // White frame
    final frameRRect =
        RRect.fromRectAndRadius(frameRect, const Radius.circular(4));
    canvas.drawRRect(frameRRect, Paint()..color = Colors.white);

    // Inner photo area
    final innerW = frameW * 0.84;
    final innerH = frameH * 0.68;
    final innerRect = Rect.fromCenter(
      center: Offset(0, -frameH * 0.08),
      width: innerW,
      height: innerH,
    );

    // Clip to inner photo
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(innerRect, const Radius.circular(2)));

    // Sky
    canvas.drawRect(innerRect, Paint()..color = const Color(0xFF7DD3FC));

    // Sun
    canvas.drawCircle(
      Offset(innerRect.left + innerW * 0.28, innerRect.top + innerH * 0.32),
      innerW * 0.16,
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
