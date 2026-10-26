// Dedicated Detail Screen for Awareness Activity
// File: lib/features/awareness/presentation/screen/awareness_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';
import '../../data/awareness_api_service.dart';
import '../../domain/awareness_models.dart';

class AwarenessDetailScreen extends StatefulWidget {
  final AwarenessItem activity;
  final int? awarenessId;

  const AwarenessDetailScreen({
    super.key,
    required this.activity,
    this.awarenessId,
  });

  @override
  State<AwarenessDetailScreen> createState() => _AwarenessDetailScreenState();
}

class _AwarenessDetailScreenState extends State<AwarenessDetailScreen> {
  late AwarenessItem _activity;
  bool _isLoading = false;
  final AwarenessApiService _apiService = AwarenessApiService();

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
    _activity = widget.activity;
    _fetchDetail();
  }

  int? get _resolvedAwarenessId {
    if (widget.awarenessId != null && widget.awarenessId! > 0) {
      return widget.awarenessId;
    }
    if (_activity.awarenessId != null && _activity.awarenessId! > 0) {
      return _activity.awarenessId;
    }
    // Extract trailing number from code like AWR-26-0006 -> 6
    final numericMatches = RegExp(r'\d+$').firstMatch(_activity.id);
    if (numericMatches != null) {
      return int.tryParse(numericMatches.group(0)!);
    }
    return null;
  }

  Future<void> _fetchDetail() async {
    final id = _resolvedAwarenessId;
    if (id == null) return;

    setState(() => _isLoading = true);

    try {
      final updated = await _apiService.fetchAwarenessDetail(id);
      if (updated != null && mounted) {
        setState(() => _activity = updated);
      }
    } catch (e) {
      debugPrint('[AWARENESS_DETAIL] Error fetching awareness detail $id: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  String _toTitleCase(String? val) {
    if (val == null || val.trim().isEmpty) return '—';
    final trimmed = val.trim();
    if (trimmed.length == 1) return trimmed.toUpperCase();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  String _formatGpsLocation() {
    if (_activity.latitude == null || _activity.longitude == null) {
      return '—';
    }
    if (_activity.latitude == 0.0 && _activity.longitude == 0.0) {
      return '—';
    }
    final latStr = _activity.latitude!.toStringAsFixed(6);
    final lngStr = _activity.longitude!.toStringAsFixed(6);
    if ((_activity.accuracy ?? 0) > 0) {
      return '$latStr, $lngStr · ±${_activity.accuracy} m';
    }
    return '$latStr, $lngStr';
  }

  String _formatSyncStatus() {
    final status = _activity.status.toLowerCase();
    final ver = _activity.verificationStatus?.toLowerCase();
    if (status == 'synced' || ver == 'submitted') {
      return 'Synced';
    }
    if (status.contains('pending') || ver == 'pending') {
      return 'Pending sync';
    }
    return _toTitleCase(_activity.status);
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
          title: 'Awareness Activity',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: _activity.volunteerId,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: _isLoading && _activity.peopleReached == 0 && _activity.village.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF136B4F)))
            : RefreshIndicator(
                onRefresh: _fetchDetail,
                color: const Color(0xFF136B4F),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Main White Card containing Header, Data Rows, and Attachments
                    _buildMainCard(),
                    const SizedBox(height: 20),

                    // "Back" Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF136B4F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Card Title (Activity Type)
          Text(
            _activity.activityType,
            style: const TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Awareness Code
          Text(
            _activity.id,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF136B4F),
            ),
          ),
          const SizedBox(height: 22),

          // Data Rows
          _buildDataRow(
            label: 'Activity',
            value: _activity.activityType,
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'Date',
            value: _formatDate(_activity.date),
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'Village / ward',
            value: _activity.village,
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'People reached',
            value: '${_activity.peopleReached}',
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'Topic covered',
            value: _activity.topicCovered.isNotEmpty
                ? _activity.topicCovered
                : 'General Awareness',
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'Departments /\nstakeholders',
            value: _activity.departmentInvolved,
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'Verification',
            value: _toTitleCase(_activity.verificationStatus ?? _activity.status),
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'Synchronisation',
            value: _formatSyncStatus(),
          ),
          _buildDivider(),
          _buildDataRow(
            label: 'GPS location',
            value: _formatGpsLocation(),
          ),
          _buildDivider(),

          // ATTACHMENTS SECTION
          const SizedBox(height: 6),
          AttachmentsSectionWidget(
            attachments: _activity.appAttachments,
            fallbackLatitude: _activity.latitude,
            fallbackLongitude: _activity.longitude,
            fallbackAccuracy: _activity.accuracy,
            fallbackDate: _activity.date,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF1F5F9),
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
        currentIndex: 1, // 'Actions' selected
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
