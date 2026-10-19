// Screen displaying the list of submitted Health Event Reports
// File: lib/features/events/presentation/screen/event_reports_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';
import '../../domain/event_models.dart';
import 'event_reporting_screen.dart';

class EventReportsListScreen extends StatefulWidget {
  final String volunteerId;
  final bool isStandalone;
  final VoidCallback? onBackToDashboard;

  const EventReportsListScreen({
    super.key,
    this.volunteerId = 'COHV-26-0005',
    this.isStandalone = false,
    this.onBackToDashboard,
  });

  @override
  State<EventReportsListScreen> createState() => EventReportsListScreenState();
}

class EventReportsListScreenState extends State<EventReportsListScreen> {
  List<EventReportItem> _events = [];
  bool _isLoading = true;

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
  void clearEvents() {
    setState(() {
      _events.clear();
    });
    SessionManager.saveSubmittedEventsList([]);
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final stored = await SessionManager.getSubmittedEvents();
      if (stored.isNotEmpty) {
        if (mounted) setState(() => _events = stored);
      } else {
        // Initial sample events matching reference design screenshot
        final initialEvents = [
          EventReportItem(
            id: 'VISIT-26-0011',
            eventType: 'Animal-borne disease events',
            primarySector: 'Human Health',
            eventDate: DateTime(2026, 10, 13, 11, 33),
            village: 'Rampur',
            status: 'synced',
            isAlert: false,
            isFollowUp: true,
            verificationStatus: 'Submitted',
            totalVisits: 1,
            targetPopulation: 'General population',
            observations: 'Suspected fever cluster observed in domestic zone.',
            actionTaken: 'Notified local surveillance team.',
          ),
          EventReportItem(
            id: 'VISIT-26-0002',
            eventType: 'Chemical exposure',
            primarySector: 'Human Health',
            eventDate: DateTime(2026, 10, 13, 10, 8),
            village: 'Amrabad',
            status: 'synced',
            isAlert: true,
            isFollowUp: true,
            verificationStatus: 'Submitted',
            totalVisits: 1,
            targetPopulation: 'General population',
            observations: 'Acute irritant exposure reported near local stream.',
            actionTaken: 'Advised protective measures and reported to CHC.',
          ),
        ];

        await SessionManager.saveSubmittedEventsList(initialEvents);
        if (mounted) setState(() => _events = initialEvents);
      }
    } catch (e) {
      debugPrint('[EVENT_REPORTS_LIST] Error loading events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    final monthStr = _months[dt.month - 1];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthStr ${dt.year} $hourStr:$minStr';
  }

  Future<void> _openReportEventScreen() async {
    final created = await Navigator.push<EventReportItem>(
      context,
      MaterialPageRoute(
        builder: (_) => EventReportingScreen(volunteerId: widget.volunteerId),
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
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 19,
              ),
              onPressed: () {
                if (widget.onBackToDashboard != null) {
                  widget.onBackToDashboard!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text(
              'Event Reports',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              _buildAppBarCircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildAppBarCircleButton(
                icon: Icons.sync_rounded,
                onTap: _loadEvents,
              ),
              const SizedBox(width: 14),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: _buildReportEventFab(),
        ),
      );
    }

    // Embedded inside DashboardScreen
    return Stack(
      children: [
        _buildBody(),
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildReportEventFab(),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            _buildEmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88), // Extra bottom padding for FAB
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
          onTap: () => _showEventDetailsSheet(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vertical Blue Accent Bar
                Container(
                  width: 3.5,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB), // Vibrant blue matching prototype
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
                                color: const Color(0xFFFEE2E2), // Light red/pink
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
                                color: Color(0xFF9D174D), // Burgundy / Mauve code
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
                        '${item.primarySector} · ${item.verificationStatus}${item.isFollowUp ? " · follow-up" : ""}',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Event Reports Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You haven\'t submitted any event reports yet.\nTap "Report Event" below to report a new health event.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _openReportEventScreen,
            icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
            label: const Text(
              'Report First Event',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }

  // =========================================================================
  // 🔍 EVENT DETAILS BOTTOM SHEET
  // =========================================================================

  void _showEventDetailsSheet(EventReportItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.id,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.status == 'synced'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: TextStyle(
                        color: item.status == 'synced'
                            ? const Color(0xFF15803D)
                            : const Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.eventType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 14),
              _buildDetailRow('Sector', item.primarySector),
              _buildDetailRow('Village', item.village),
              _buildDetailRow('Date & Time', _formatDateTime(item.eventDate)),
              if (item.targetPopulation != null && item.targetPopulation!.isNotEmpty)
                _buildDetailRow('Target Population', item.targetPopulation!),
              _buildDetailRow('Verification', item.verificationStatus),
              _buildDetailRow('Follow-up Required', item.isFollowUp ? 'Yes' : 'No'),
              _buildDetailRow('Alert Generated', item.isAlert ? 'Yes (Urgent)' : 'No'),
              if (item.observations != null && item.observations!.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text(
                  'Observations:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.observations!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              if (item.actionTaken != null && item.actionTaken!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Action Taken:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.actionTaken!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarCircleButton({
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
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
