// Quick Actions Tab Grid Screen
// File: lib/features/dashboard/presentation/screen/quick_actions_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.cloud_off_outlined,
                    color: Color(0xFF64748B),
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
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
