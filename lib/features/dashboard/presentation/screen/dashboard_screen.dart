import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/dashboard_api_service.dart';
import '../../domain/dashboard_models.dart';
import 'quick_actions_screen.dart';
import 'package:cohv/features/reports/presentation/screen/reports_screen.dart';
import 'package:cohv/features/profile/presentation/screen/profile_screen.dart';
import 'package:cohv/features/notifications/presentation/screen/notifications_screen.dart';
import 'package:cohv/features/sync/presentation/screen/sync_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reporting_screen.dart';


class DashboardScreen extends StatefulWidget {
  final String volunteerId;
  final String volunteerName;

  const DashboardScreen({
    super.key,
    this.volunteerId = 'COHV-26-0013',
    this.volunteerName = 'Ramu',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _apiService = DashboardApiService();

  int _selectedTabIndex = 0; // 0 = Dashboard, 1 = Actions
  bool _isLoading = false;

  late VolunteerProfile _profile;
  DashboardMetrics _metrics = DashboardMetrics();

  @override
  void initState() {
    super.initState();
    _profile = VolunteerProfile(
      fullName: widget.volunteerName,
      volunteerId: widget.volunteerId,
      status: 'Active',
      locationBreadcrumb: 'Mannanur · Amrabad · Nagarkurnool',
    );
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _apiService.getDashboardMetrics(widget.volunteerId);
      final profile = await _apiService.getVolunteerProfile(widget.volunteerId);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _profile = profile;
        });
      }
    } catch (_) {
      // Keep local state
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: Text(
            appBarTitle,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            // Notification Bell
                        // Notification Bell
            _buildAppBarButton(
              icon: Icons.notifications_none_rounded,
              onTap: () async {
                final selectedTab = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(volunteerId: widget.volunteerId),
                  ),
                );
                if (selectedTab != null && mounted) {
                  setState(() => _selectedTabIndex = selectedTab);
                }
              },
            ),

            const SizedBox(width: 8),

                        // Refresh / Sync Button
            _buildAppBarButton(
              icon: Icons.sync_rounded,
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
              },
            ),
            const SizedBox(width: 14),
          ],
        ),

        // Body switches smoothly across Dashboard, Actions, Reports, and Profile
        body: _selectedTabIndex == 1
            ? const QuickActionsScreen()
            : _selectedTabIndex == 2
                ? const ReportsScreen()
                : _selectedTabIndex == 3
                    ? ProfileScreen(volunteerId: widget.volunteerId)
                    : RefreshIndicator(
                        onRefresh: _loadDashboardData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(),
                              const SizedBox(height: 14),
                              _buildMetricsGrid(),
                              const SizedBox(height: 16),
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
  // APP BAR ACTIONS
  // =========================================================================

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // =========================================================================
  // PROFILE CARD
  // =========================================================================

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profile.volunteerId,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profile.locationBreadcrumb,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _profile.status,
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // "Report an Event" Banner Button switches to Actions or opens form
                    // "Report an Event" Banner Button
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventReportingScreen(volunteerId: widget.volunteerId),
                ),
              );
              if (result == true) {
                _loadDashboardData(); // Refreshes surveillance counters
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                'Report an Event',
                style: TextStyle(
                  color: Color(0xFFC2410C),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // METRICS GRID (8 Surveillance Cards)
  // =========================================================================

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // children: [
      //   _buildMetricCard(title: 'Total visits', value: _metrics.totalVisits.toString()),
      //   _buildMetricCard(title: 'Alerts generated', value: _metrics.alertsGenerated.toString(), hasAlertDot: true),
      //   _buildMetricCard(title: 'Referrals', value: _metrics.referrals.toString()),
      //   _buildMetricCard(title: 'Pending follow-ups', value: _metrics.pendingFollowUps.toString()),
      //   _buildMetricCard(title: 'Awareness activities', value: _metrics.awarenessActivities.toString()),
      //   _buildMetricCard(title: 'Trainings imparted', value: _metrics.trainingsImparted.toString()),
      //   _buildMetricCard(title: 'Trainings attended', value: _metrics.trainingsAttended.toString()),
      //   _buildMetricCard(title: 'Data pending for synchronization', value: _metrics.pendingSyncCount.toString()),
      // ],
      children: [
        _buildMetricCard(title: 'Total visits', value: _metrics.totalVisits.toString()),
        _buildMetricCard(title: 'Alerts generated', value: _metrics.alertsGenerated.toString(), hasAlertDot: true),
        _buildMetricCard(title: 'Referrals', value: _metrics.referrals.toString()),
        _buildMetricCard(title: 'Pending follow-ups', value: _metrics.pendingFollowUps.toString()),
        _buildMetricCard(title: 'Awareness activities', value: _metrics.awarenessActivities.toString()),
        _buildMetricCard(title: 'Trainings imparted', value: _metrics.trainingsImparted.toString()),
        _buildMetricCard(title: 'Trainings attended', value: _metrics.trainingsAttended.toString()),
        InkWell(
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
          },
          borderRadius: BorderRadius.circular(14),
          child: _buildMetricCard(
            title: 'Data pending for synchronization',
            value: _metrics.pendingSyncCount.toString(),
          ),
        ),
      ],

    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    bool hasAlertDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ),
              if (hasAlertDot)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 2, left: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA580C),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        // onTap: (index) {
        //   if (index < 3) {
        //     setState(() => _selectedTabIndex = index);
        //   } else {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //         content: Text('Profile module coming soon.'),
        //         duration: Duration(milliseconds: 900),
        //       ),
        //     );
        //   }
        // },

        onTap: (index) => setState(() => _selectedTabIndex = index),

        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
