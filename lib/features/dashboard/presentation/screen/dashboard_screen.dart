import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../../data/dashboard_api_service.dart';
import '../../domain/dashboard_models.dart';

import 'package:cohv/features/reports/presentation/screen/reports_screen.dart';
import 'package:cohv/features/profile/presentation/screen/profile_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reporting_screen.dart';
import 'package:cohv/features/sync/presentation/screen/sync_screen.dart';

import 'quick_actions_screen.dart';
import '../../domain/department_config.dart';
import '../widgets/dashboard_hero_card.dart';

class DashboardScreen extends StatefulWidget {
  final String volunteerId;
  final String volunteerName;

  const DashboardScreen({
    super.key,
    this.volunteerId = '',
    this.volunteerName = '',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _apiService = DashboardApiService();
  int _selectedTabIndex = 0; // 0 = Dashboard, 1 = Actions, 2 = Reports, 3 = Profile
  bool _isLoading = false;
  bool _hasInitializedData = false;

  late VolunteerProfile _profile;
  DashboardMetrics _metrics = DashboardMetrics();

  @override
  void initState() {
    super.initState();
    _profile = VolunteerProfile(
      fullName: widget.volunteerName.trim().isNotEmpty
          ? widget.volunteerName.trim()
          : 'Alex',
      volunteerId: widget.volunteerId,
      status: 'Active',
      locationBreadcrumb: 'Mannanur · Amrabad · Nagarkurnool',
      departmentName: 'Public Health Department',
    );
    _initDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volunteerId != widget.volunteerId ||
        oldWidget.volunteerName != widget.volunteerName) {
      _selectedTabIndex = 0;
      _profile = VolunteerProfile(
        fullName: widget.volunteerName.trim().isNotEmpty
            ? widget.volunteerName.trim()
            : 'Alex',
        volunteerId: widget.volunteerId,
        status: 'Active',
        locationBreadcrumb: 'Mannanur · Amrabad · Nagarkurnool',
        departmentName: 'Public Health Department',
      );
      _initDashboard();
    }
  }

  /// Initialize with cached metrics first for instant UI, then fetch fresh API data
  Future<void> _initDashboard() async {
    final session = await SessionManager.getUserSession();
    final effectiveVolunteerId = widget.volunteerId.trim().isNotEmpty
        ? widget.volunteerId.trim()
        : (session?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');

    if (session != null && mounted) {
      setState(() {
        _profile = VolunteerProfile(
          fullName: session.fullName.isNotEmpty
              ? session.fullName
              : _profile.fullName,
          volunteerId: session.volunteerId.isNotEmpty
              ? session.volunteerId
              : _profile.volunteerId,
          status: session.status.toUpperCase() == 'ACTIVE'
              ? 'Active'
              : session.status,
          locationBreadcrumb: session.locationBreadcrumb.isNotEmpty
              ? session.locationBreadcrumb
              : _profile.locationBreadcrumb,
          photoUrl: session.photoPath,
          departmentName: session.sector.isNotEmpty
              ? session.sector
              : _profile.departmentName,
        );
      });
    }

    if (effectiveVolunteerId.isNotEmpty) {
      final cached =
          await SessionManager.getCachedDashboardMetrics(effectiveVolunteerId);
      if (cached != null && mounted) {
        setState(() {
          _metrics = cached;
          _hasInitializedData = true;
        });
      }
    }

    // Fetch fresh dynamic counts from GET /api/volunteers/summary
    await _loadDashboardData(isSilent: _hasInitializedData);
  }

  Future<void> _loadDashboardData({bool isSilent = false}) async {
    if (!isSilent && !_hasInitializedData) {
      setState(() => _isLoading = true);
    }
    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId = widget.volunteerId.trim().isNotEmpty
          ? widget.volunteerId.trim()
          : (session?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');
      final effectiveVolunteerName = widget.volunteerName.trim().isNotEmpty
          ? widget.volunteerName.trim()
          : (session?.fullName.isNotEmpty == true ? session!.fullName : '');

      final metrics =
          await _apiService.getDashboardMetrics(effectiveVolunteerId);
      final profile =
          await _apiService.getVolunteerProfile(effectiveVolunteerId);

      final String resolvedName = (metrics.volunteerName != null &&
              metrics.volunteerName!.trim().isNotEmpty &&
              metrics.volunteerName!.trim() != 'Alex')
          ? metrics.volunteerName!.trim()
          : (profile.fullName.isNotEmpty && profile.fullName != 'Alex'
              ? profile.fullName
              : (effectiveVolunteerName.isNotEmpty
                  ? effectiveVolunteerName
                  : profile.fullName));

      final String resolvedId = (metrics.volunteerCode != null &&
              metrics.volunteerCode!.trim().isNotEmpty)
          ? metrics.volunteerCode!.trim()
          : (profile.volunteerId.isNotEmpty
              ? profile.volunteerId
              : effectiveVolunteerId);

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _hasInitializedData = true;
          _profile = VolunteerProfile(
            fullName: resolvedName,
            volunteerId: resolvedId,
            status: profile.status,
            locationBreadcrumb: profile.locationBreadcrumb,
            photoUrl: profile.photoUrl,
            departmentName: profile.departmentName,
          );
        });
      }
    } catch (e) {
      debugPrint('[DASHBOARD] Error loading dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic AppBar title based on selected tab
    String appBarTitle = 'Dashboard';
    if (_selectedTabIndex == 1) {
      appBarTitle = 'Quick Actions';
    } else if (_selectedTabIndex == 2) {
      appBarTitle = 'Reports';
    } else if (_selectedTabIndex == 3) {
      appBarTitle = 'Profile';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.setuBackground,
        appBar: AuthenticatedAppBar(
          title: appBarTitle,
          backgroundColor: AppColors.setuGreen,
          automaticallyImplyLeading: false,
          volunteerId: widget.volunteerId,
          onTabReturned: (tab) {
            if (mounted) {
              setState(() => _selectedTabIndex = tab);
              if (tab == 0) {
                _loadDashboardData(isSilent: true);
              }
            }
          },
        ),

        // Body switches smoothly across Dashboard, Actions, Reports, and Profile
        body: _selectedTabIndex == 1
            ? QuickActionsScreen(
                volunteerId: widget.volunteerId,
                department: _profile.departmentName,
                onTabSelected: (tabIndex) {
                  setState(() => _selectedTabIndex = tabIndex);
                  if (tabIndex == 0) {
                    _loadDashboardData(isSilent: true);
                  }
                },
              )
            : _selectedTabIndex == 2
            ? const ReportsScreen()
            : _selectedTabIndex == 3
            ? ProfileScreen(volunteerId: widget.volunteerId)
            : (_isLoading && !_hasInitializedData)
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.setuGreen),
              )
            : RefreshIndicator(
                onRefresh: () => _loadDashboardData(isSilent: true),
                color: AppColors.setuGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 22),
                      _buildSnapshotHeader(),
                      const SizedBox(height: 14),
                      _buildMetricsGrid(),
                      const SizedBox(height: 16),
                      _buildFieldLocationCard(),
                      const SizedBox(height: 16),
                      _buildSyncStatusRow(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

        // Bottom Navigation Bar
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // =========================================================================
  // SETU FIELDSPACE HERO CARD
  // =========================================================================

  Widget _buildHeroCard() {
    final deptConfig = DepartmentConfig.fromCohvType(_profile.departmentName);

    return DashboardHeroCard(
      departmentConfig: deptConfig,
      volunteerName: _profile.fullName,
      volunteerId: _profile.volunteerId,
      photoPath: _profile.photoUrl,
      locationBreadcrumb: _profile.locationBreadcrumb,
      onAvatarTap: () => setState(() => _selectedTabIndex = 3),
      onReportEventTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventReportingScreen(
              volunteerId: widget.volunteerId,
            ),
          ),
        );
        if (result == true) {
          _loadDashboardData();
        }
      },
    );
  }

  // =========================================================================
  // YOUR SNAPSHOT & FIELD ACTIVITY HEADER
  // =========================================================================

  Widget _buildSnapshotHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR SNAPSHOT',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Field activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _selectedTabIndex = 2),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View reports',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.setuGreen,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: AppColors.setuGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // METRICS GRID (8 Surveillance Cards Bound to Live API)
  // =========================================================================

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.82,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          title: 'Total visits',
          value: _metrics.totalVisits.toString(),
          backgroundColor: const Color(0xFFE8F7EE),
          badgeColor: const Color(0xFFD1F2DD),
          borderColor: const Color(0xFFA7E8C1),
          valueColor: const Color(0xFF0F563D),
          icon: const _FootprintsIcon(color: Color(0xFF0F563D), size: 22),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Alerts generated',
          value: _metrics.alertsGenerated.toString(),
          backgroundColor: const Color(0xFFFEF3E8),
          badgeColor: const Color(0xFFFED7AA),
          borderColor: const Color(0xFFFDBA74),
          valueColor: const Color(0xFFEA580C),
          icon: const Icon(
            Icons.notifications_rounded,
            color: Color(0xFFEA580C),
            size: 24,
          ),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Referrals',
          value: _metrics.referrals.toString(),
          backgroundColor: const Color(0xFFFDF2F8),
          badgeColor: const Color(0xFFFBCFE8),
          borderColor: const Color(0xFFF9A8D4),
          valueColor: const Color(0xFFBE185D),
          icon: const Icon(
            Icons.person_add_rounded,
            color: Color(0xFFBE185D),
            size: 22,
          ),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Pending follow-ups',
          value: _metrics.pendingFollowUps.toString(),
          backgroundColor: const Color(0xFFFEF9EE),
          badgeColor: const Color(0xFFFDE68A),
          borderColor: const Color(0xFFFCD34D),
          valueColor: const Color(0xFFB45309),
          icon: const Icon(
            Icons.access_time_rounded,
            color: Color(0xFFB45309),
            size: 22,
          ),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Awareness activities',
          value: _metrics.awarenessActivities.toString(),
          backgroundColor: const Color(0xFFF5F3FF),
          badgeColor: const Color(0xFFDDD6FE),
          borderColor: const Color(0xFFC4B5FD),
          valueColor: const Color(0xFF7C3AED),
          icon: const Icon(
            Icons.campaign_rounded,
            color: Color(0xFF7C3AED),
            size: 24,
          ),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Trainings imparted',
          value: _metrics.trainingsImparted.toString(),
          backgroundColor: const Color(0xFFF0F9FF),
          badgeColor: const Color(0xFFBAE6FD),
          borderColor: const Color(0xFF7DD3FC),
          valueColor: const Color(0xFF0284C7),
          icon: const Icon(
            Icons.school_rounded,
            color: Color(0xFF0284C7),
            size: 22,
          ),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Trainings attended',
          value: _metrics.trainingsAttended.toString(),
          backgroundColor: const Color(0xFFF0FDFA),
          badgeColor: const Color(0xFF99F6E4),
          borderColor: const Color(0xFF5EEAD4),
          valueColor: const Color(0xFF0F766E),
          icon: const Icon(
            Icons.groups_rounded,
            color: Color(0xFF0F766E),
            size: 22,
          ),
          // Static: no navigation
        ),
        _buildMetricCard(
          title: 'Data pending for synchronization',
          value: _metrics.pendingSyncCount.toString(),
          backgroundColor: const Color(0xFFF1F5F9),
          badgeColor: const Color(0xFFE2E8F0),
          borderColor: const Color(0xFFCBD5E1),
          valueColor: const Color(0xFF475569),
          icon: const Icon(
            Icons.cloud_upload_rounded,
            color: Color(0xFF475569),
            size: 22,
          ),
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => SyncScreen(volunteerId: widget.volunteerId),
              ),
            );
            if (selectedTab != null && mounted) {
              setState(() => _selectedTabIndex = selectedTab);
            }
            _loadDashboardData(isSilent: true);
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color backgroundColor,
    required Color badgeColor,
    required Color borderColor,
    required Widget icon,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  // =========================================================================
  // FIELD LOCATION CARD & STATUS
  // =========================================================================

  Widget _buildFieldLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF0F563D),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field location',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '28.584065, 77.371091',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.gps_fixed_rounded,
                      size: 13,
                      color: Color(0xFF0F766E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '±11 m accuracy',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Field location updated'),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF0F563D),
                    size: 18,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: Color(0xFF0F563D),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    width: 0,
                    height: 0,
                    child: OverflowBox(
                      maxWidth: 0,
                      maxHeight: 0,
                      child: Text('Capture'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusRow() {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Connected · reports save locally before sync',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Dashboard',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.grid_view_rounded,
            label: 'Actions',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.article_outlined,
            label: 'Reports',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 0) {
          _loadDashboardData(isSilent: true);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.setuGreen : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.setuGreen : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM FOOTPRINTS ICON (DUAL FOOTPRINTS SILHOUETTE)
// =========================================================================

class _FootprintsIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _FootprintsIcon({
    required this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FootprintsPainter(color: color),
    );
  }
}

class _FootprintsPainter extends CustomPainter {
  final Color color;

  _FootprintsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Left footprint (lower)
    canvas.save();
    canvas.translate(w * 0.30, h * 0.52);
    canvas.rotate(-0.16);
    _drawFootprint(canvas, paint, w * 0.36, h * 0.65);
    canvas.restore();

    // Right footprint (higher)
    canvas.save();
    canvas.translate(w * 0.70, h * 0.40);
    canvas.rotate(0.14);
    _drawFootprint(canvas, paint, w * 0.36, h * 0.65);
    canvas.restore();
  }

  void _drawFootprint(Canvas canvas, Paint paint, double fw, double fh) {
    // Heel
    final heelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, fh * 0.28),
        width: fw * 0.72,
        height: fh * 0.34,
      ),
      Radius.circular(fw * 0.36),
    );
    canvas.drawRRect(heelRect, paint);

    // Sole
    final soleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -fh * 0.14),
        width: fw * 0.88,
        height: fh * 0.46,
      ),
      Radius.circular(fw * 0.44),
    );
    canvas.drawRRect(soleRect, paint);

    // Toes
    final r = fw * 0.085;
    canvas.drawCircle(Offset(-fw * 0.30, -fh * 0.45), r * 0.85, paint);
    canvas.drawCircle(Offset(-fw * 0.10, -fh * 0.48), r * 0.95, paint);
    canvas.drawCircle(Offset(fw * 0.10, -fh * 0.47), r * 1.05, paint);
    canvas.drawCircle(Offset(fw * 0.30, -fh * 0.42), r * 1.25, paint);
  }

  @override
  bool shouldRepaint(covariant _FootprintsPainter oldDelegate) =>
      oldDelegate.color != color;
}

