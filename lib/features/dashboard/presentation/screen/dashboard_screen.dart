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
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          title: 'Total visits',
          value: _metrics.totalVisits.toString(),
          onTap: () => setState(() => _selectedTabIndex = 2),
        ),
        _buildMetricCard(
          title: 'Alerts generated',
          value: _metrics.alertsGenerated.toString(),
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => EventReportsListScreen(
                  volunteerId: widget.volunteerId,
                ),
              ),
            );
            if (selectedTab != null && mounted) {
              setState(() => _selectedTabIndex = selectedTab);
            }
            _loadDashboardData(isSilent: true);
          },
        ),
        _buildMetricCard(
          title: 'Referrals',
          value: _metrics.referrals.toString(),
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => ReferralsListScreen(
                  volunteerId: widget.volunteerId,
                ),
              ),
            );
            if (selectedTab != null && mounted) {
              setState(() => _selectedTabIndex = selectedTab);
            }
            _loadDashboardData(isSilent: true);
          },
        ),
        _buildMetricCard(
          title: 'Pending follow-ups',
          value: _metrics.pendingFollowUps.toString(),
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => ReferralsListScreen(
                  volunteerId: widget.volunteerId,
                ),
              ),
            );
            if (selectedTab != null && mounted) {
              setState(() => _selectedTabIndex = selectedTab);
            }
            _loadDashboardData(isSilent: true);
          },
        ),
        _buildMetricCard(
          title: 'Awareness activities',
          value: _metrics.awarenessActivities.toString(),
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => AwarenessListScreen(
                  volunteerId: widget.volunteerId,
                ),
              ),
            );
            if (selectedTab != null && mounted) {
              setState(() => _selectedTabIndex = selectedTab);
            }
            _loadDashboardData(isSilent: true);
          },
        ),
        _buildMetricCard(
          title: 'Trainings imparted',
          value: _metrics.trainingsImparted.toString(),
        ),
        _buildMetricCard(
          title: 'Trainings attended',
          value: _metrics.trainingsAttended.toString(),
        ),
        _buildMetricCard(
          title: 'Data pending for synchronization',
          value: _metrics.pendingSyncCount.toString(),
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
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.25,
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
          borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.setuGreen,
              size: 24,
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '28.584065, 77.371091',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
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
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Capture',
                style: TextStyle(
                  color: AppColors.setuGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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
