// Screen displaying full details of a specific Health Event Report
// File: lib/features/events/presentation/screen/event_report_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_header.dart';
import '../../data/event_api_service.dart';
import '../../domain/event_models.dart';

class EventReportDetailScreen extends StatefulWidget {
  final EventReportItem event;
  final String? volunteerId;
  final VoidCallback? onBackToDashboard;

  const EventReportDetailScreen({
    super.key,
    required this.event,
    this.volunteerId,
    this.onBackToDashboard,
  });

  @override
  State<EventReportDetailScreen> createState() => _EventReportDetailScreenState();
}

class _EventReportDetailScreenState extends State<EventReportDetailScreen> {
  late EventReportItem _event;
  bool _isRefreshing = false;
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
    _event = widget.event;
    _refreshIfPossible();
  }

  Future<void> _refreshIfPossible() async {
    if (_event.numericId == null) return;
    try {
      final updated = await _apiService.fetchEventDetail(_event.numericId!);
      if (updated != null && mounted) {
        setState(() => _event = updated);
      }
    } catch (e) {
      debugPrint('[EVENT_DETAIL] Error refreshing detail: $e');
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _isRefreshing = true);
    await _refreshIfPossible();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatDetailDateTime(DateTime dt) {
    final monthStr = _months[dt.month - 1];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthStr ${dt.year} · $hourStr:$minStr';
  }

  String _toTitleCase(String? val) {
    if (val == null || val.trim().isEmpty) return '—';
    final trimmed = val.trim();
    if (trimmed.length == 1) return trimmed.toUpperCase();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  String _formatLocation() {
    if (_event.latitude == null || _event.longitude == null) {
      return '—';
    }
    final latStr = _event.latitude!.toStringAsFixed(6);
    final lngStr = _event.longitude!.toStringAsFixed(6);
    if (_event.gpsAccuracyM != null && _event.gpsAccuracyM! > 0) {
      return '$latStr, $lngStr · ±${_event.gpsAccuracyM} m';
    }
    return '$latStr, $lngStr';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AuthenticatedAppBar(
          title: 'Event Report',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        body: _isRefreshing
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF136B4F)),
              )
            : RefreshIndicator(
                onRefresh: _manualRefresh,
                color: const Color(0xFF136B4F),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Detail Card (Matches Prototype Exactly)
                      _buildDetailCard(),

                      const SizedBox(height: 16),

                      // 2. Back Action Button
                      _buildBackButton(),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Title
          Text(
            _event.eventType,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Code · Sector
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
              ),
              children: [
                TextSpan(
                  text: _event.id,
                  style: const TextStyle(
                    color: Color(0xFF136B4F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' · ${_event.primarySector}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 13 Detail Rows with Dividers
          _buildRow('Date', _formatDetailDateTime(_event.eventDate)),
          _buildRow('Village / ward', _event.village),
          _buildRow(
            'Purpose of visit',
            _event.purposeOfVisit?.isNotEmpty == true
                ? _event.purposeOfVisit!
                : 'testing',
          ),
          _buildRow(
            'Type of location',
            _event.locationType?.isNotEmpty == true
                ? _toTitleCase(_event.locationType)
                : 'Urban',
          ),
          _buildRow('Total visits', '${_event.totalVisits}'),
          _buildRow(
            'Population',
            _event.targetPopulation?.isNotEmpty == true
                ? _event.targetPopulation!
                : (_event.primarySector.toLowerCase().contains('animal')
                    ? 'Livestock'
                    : 'General population'),
          ),
          _buildRow(
            'Description',
            _event.description?.isNotEmpty == true
                ? _event.description!
                : 'testing',
          ),
          _buildRow(
            'Observations',
            _event.observations?.isNotEmpty == true
                ? _event.observations!
                : 'testing',
          ),
          _buildRow(
            'Immediate action taken',
            _event.actionTaken?.isNotEmpty == true
                ? _event.actionTaken!
                : 'testing',
          ),
          _buildRow(
            'Referral generated',
            _event.referralGenerated ? 'Yes' : 'No',
          ),
          _buildRow(
            'Verification',
            _toTitleCase(_event.verificationStatus),
          ),
          _buildRow(
            'Synchronisation',
            _toTitleCase(_event.status),
          ),
          _buildRow(
            'Location',
            _formatLocation(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label (Left Column)
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Value (Right Column)
              Expanded(
                flex: 6,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF136B4F),
                ),
              ),
            ),
          ),
        ),
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
        selectedItemColor: const Color(0xFF136B4F),
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
