// Screen displaying the list of submitted Health Event Reports
// File: lib/features/events/presentation/screen/event_reports_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/widgets/authenticated_header.dart';
import '../../data/event_api_service.dart';
import '../../../../core/storage/volunteer_ownership_filter.dart';
import '../../domain/event_models.dart';
import 'event_report_detail_screen.dart';
import 'event_reporting_screen.dart';

class EventReportsListScreen extends StatefulWidget {
  final String? volunteerId;
  final bool isStandalone;
  final VoidCallback? onBackToDashboard;

  const EventReportsListScreen({
    super.key,
    this.volunteerId,
    this.isStandalone = false,
    this.onBackToDashboard,
  });

  @override
  State<EventReportsListScreen> createState() => EventReportsListScreenState();
}

class EventReportsListScreenState extends State<EventReportsListScreen> {
  List<EventReportItem> _events = [];
  bool _isLoading = true;
  final EventApiService _apiService = EventApiService();

  final List<String> _months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// Public reload method callable by parent / AppBar sync button
  Future<void> reload() async {
    await _loadEvents();
  }

  /// Add a newly created event report to the list
  void addEvent(EventReportItem item) {
    setState(() {
      _events.removeWhere((e) => e.id == item.id);
      _events.insert(0, item);
    });
  }

  /// Clear events (used for testing empty state)
  void clearEvents() async {
    setState(() {
      _events.clear();
    });
    final session = await SessionManager.getUserSession();
    final effectiveVolunteerId =
        (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
            ? widget.volunteerId!.trim()
            : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');
    final effectiveNumericId =
        session?.numericVolunteerId ??
        await SessionManager.getNumericVolunteerId();
    await SessionManager.saveSubmittedEventsList(
      [],
      volunteerId: effectiveVolunteerId,
      numericVolunteerId: effectiveNumericId,
    );
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId =
          (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
              ? widget.volunteerId!.trim()
              : (session?.volunteerId ??
                  await SessionManager.getVolunteerId() ??
                  '');
      final effectiveNumericId =
          session?.numericVolunteerId ??
          await SessionManager.getNumericVolunteerId() ??
          VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);

      final remoteEvents = await _apiService.fetchEventReports(
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
      if (mounted) {
        setState(() => _events = remoteEvents);
      }
    } catch (e) {
      debugPrint('[EVENT_REPORTS_LIST] Error loading events from API: $e');
      try {
        final session = await SessionManager.getUserSession();
        final effectiveVolunteerId =
            (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
                ? widget.volunteerId!.trim()
                : (session?.volunteerId ??
                    await SessionManager.getVolunteerId() ??
                    '');
        final effectiveNumericId =
            session?.numericVolunteerId ??
            await SessionManager.getNumericVolunteerId() ??
            VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);

        final stored = await SessionManager.getSubmittedEvents(
          volunteerId: effectiveVolunteerId,
          numericVolunteerId: effectiveNumericId,
        );
        if (mounted) {
          setState(() => _events = stored);
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Submitted';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDateTime(DateTime dt) {
    final monthStr = _months[dt.month - 1];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthStr ${dt.year} $hourStr:$minStr';
  }

  Future<void> _openReportEventScreen() async {
    final session = await SessionManager.getUserSession();
    final effectiveVolunteerId =
        (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
            ? widget.volunteerId!.trim()
            : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');

    if (!mounted) return;
    final created = await Navigator.push<EventReportItem>(
      context,
      MaterialPageRoute(
        builder: (_) => EventReportingScreen(volunteerId: effectiveVolunteerId),
      ),
    );

    if (created != null && mounted) {
      setState(() {
        _events.removeWhere((e) => e.id == created.id);
        _events.insert(0, created);
      });
    } else if (mounted) {
      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalone) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AuthenticatedAppBar(
            title: 'Event Reports',
            volunteerId: widget.volunteerId ?? '',
            onBackPressed: () {
              if (widget.onBackToDashboard != null) {
                widget.onBackToDashboard!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          body: _buildBody(),
          floatingActionButton: _buildReportEventFab(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      );
    }

    // Embedded inside DashboardScreen
    return Stack(
      children: [
        _buildBody(),
        Positioned(right: 16, bottom: 16, child: _buildReportEventFab()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [_buildEmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          88,
        ), // Extra bottom padding for FAB
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  // =========================================================================
  // 📋 EVENT REPORT CARD (Matches Screenshot 1 Prototype Exactly)
  // =========================================================================

  Widget _buildEventCard(EventReportItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventReportDetailScreen(
                  event: item,
                  volunteerId: widget.volunteerId,
                  onBackToDashboard: widget.onBackToDashboard,
                ),
              ),
            );
            if (mounted) {
              await _loadEvents();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vertical Soft Indigo Accent Bar (Matching Prototype Image 1)
                Container(
                  width: 3.5,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C6EAF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 2. Middle Column: Title + Badges, Code/Date/Village, Sector/Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with Status & Alert Badges
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.eventType,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Alert Badge (if alert generated)
                          if (item.isAlert) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFEE2E2,
                                ), // Light red/pink
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'alert',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Status Badge: Synced / Pending
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.status == 'synced'
                                  ? const Color(0xFFDCFCE7) // Soft mint green
                                  : const Color(0xFFFEF3C7), // Soft amber
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.status == 'synced' ? 'synced' : 'pending',
                              style: TextStyle(
                                color: item.status == 'synced'
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Code · Date · Village
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                          children: [
                            TextSpan(
                              text: item.id,
                              style: const TextStyle(
                                color: Color(
                                  0xFF9D174D,
                                ), // Burgundy / Mauve code
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' · ${_formatDateTime(item.eventDate)} · ${item.village}',
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Sector · Status · Follow-up
                      Text(
                        '${item.primarySector} · ${_formatStatus(item.verificationStatus)}${item.isFollowUp ? " · follow-up" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Right Chevron Indicator
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
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
  // 📭 EMPTY STATE
  // =========================================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No events reported yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use Report Event to file one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ➕ FLOATING "REPORT EVENT" BUTTON (Matches Prototype Pill Exactly)
  // =========================================================================

  Widget _buildReportEventFab() {
    return ElevatedButton.icon(
      key: const ValueKey('report_event_fab'),
      onPressed: _openReportEventScreen,
      icon: const Icon(Icons.add, color: Colors.white, size: 20),
      label: const Text(
        'Report Event',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }




  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Highlight 'Actions'
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
