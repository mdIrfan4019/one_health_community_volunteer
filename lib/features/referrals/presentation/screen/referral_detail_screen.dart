// Dedicated Screen displaying full details of a specific Referral
// File: lib/features/referrals/presentation/screen/referral_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';
import '../../data/referrals_api_service.dart';
import '../../domain/referral_models.dart';

class ReferralDetailScreen extends StatefulWidget {
  final ReferralItem referral;
  final int? referralId;

  const ReferralDetailScreen({
    super.key,
    required this.referral,
    this.referralId,
  });

  @override
  State<ReferralDetailScreen> createState() => _ReferralDetailScreenState();
}

class _ReferralDetailScreenState extends State<ReferralDetailScreen> {
  late ReferralItem _referral;
  bool _isLoading = false;
  final ReferralsApiService _apiService = ReferralsApiService();

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
    _referral = widget.referral;
    _fetchDetail();
  }

  int? get _resolvedReferralId {
    if (widget.referralId != null && widget.referralId! > 0) {
      return widget.referralId;
    }
    if (_referral.referralId != null && _referral.referralId! > 0) {
      return _referral.referralId;
    }
    // Attempt parsing numeric id if embedded in string id
    final numericMatches = RegExp(r'\d+$').firstMatch(_referral.id);
    if (numericMatches != null) {
      return int.tryParse(numericMatches.group(0)!);
    }
    return null;
  }

  Future<void> _fetchDetail() async {
    final id = _resolvedReferralId;
    if (id == null) return;

    setState(() => _isLoading = true);

    try {
      final updated = await _apiService.fetchReferralDetail(id);
      if (updated != null && mounted) {
        setState(() => _referral = updated);
      }
    } catch (e) {
      debugPrint('[REFERRAL_DETAIL] Error fetching referral $id: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatStream(String stream) {
    final s = stream.toLowerCase();
    if (s.contains('animal') || s.contains('vet')) return 'Animal';
    if (s.contains('env')) return 'Environmental';
    return 'Human';
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
    if (_referral.latitude == null || _referral.longitude == null) {
      return '—';
    }
    if (_referral.latitude == 0.0 && _referral.longitude == 0.0) {
      return '—';
    }
    final latStr = _referral.latitude!.toStringAsFixed(6);
    final lngStr = _referral.longitude!.toStringAsFixed(6);
    if ((_referral.accuracy ?? 0) > 0) {
      return '$latStr, $lngStr · ±${_referral.accuracy} m';
    }
    return '$latStr, $lngStr';
  }

  String _formatSyncStatus() {
    final status = _referral.status.toLowerCase();
    final ver = _referral.verificationStatus?.toLowerCase();
    if (status == 'synced' || ver == 'submitted') {
      return 'Synced';
    }
    if (status.contains('pending') || ver == 'pending') {
      return 'Pending sync';
    }
    return _toTitleCase(_referral.status);
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
          title: 'Referral',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: _referral.volunteerId,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchDetail,
          color: const Color(0xFF136B4F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) ...[
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF136B4F),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 10),
                ],

                // 1. Main Referral Details Card (Matching Image 1 & 2 exact structure)
                _buildReferralDetailCard(),
                const SizedBox(height: 16),

                // 2. Back Button (Matching Image 1 exact style)
                _buildBackButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // =========================================================================
  // CARD 1: MAIN REFERRAL DETAILS CARD
  // =========================================================================

  Widget _buildReferralDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        children: [
          // Header: Facility Name (bold) and Referral Code (secondary color)
          Text(
            _referral.facilityName.isNotEmpty
                ? _referral.facilityName
                : 'Referral Facility',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _referral.id,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF136B4F),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),

          // 10 Key-Value rows matching Image 2
          _buildDetailRow(
            label: 'Referral stream',
            value: _formatStream(_referral.stream),
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Referral type',
            value: _referral.facilityName,
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Village / ward',
            value: _referral.village,
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Event date',
            value: _formatDate(_referral.eventDate),
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Referral date',
            value: _formatDate(_referral.referralDate),
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Reason',
            value: _referral.reason != null &&
                    _referral.reason!.trim().isNotEmpty
                ? _referral.reason!
                : '—',
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Followed up',
            value: _referral.isFollowedUp ? 'Yes' : 'No',
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Verification',
            value: _toTitleCase(_referral.verificationStatus ?? 'Submitted'),
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Synchronisation',
            value: _formatSyncStatus(),
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'GPS location',
            value: _formatGpsLocation(),
          ),
          if (_referral.appAttachments.isNotEmpty) ...[
            _buildDivider(),
            const SizedBox(height: 14),
            AttachmentsSectionWidget(
              attachments: _referral.appAttachments,
              fallbackLatitude: _referral.latitude,
              fallbackLongitude: _referral.longitude,
              fallbackAccuracy: _referral.accuracy,
              fallbackDate: _referral.capturedAt ?? _referral.referralDate,
            ),
          ],
        ],
      ),
    );
  }


  // =========================================================================
  // BUTTON: BACK
  // =========================================================================

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
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
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF136B4F),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // REUSABLE BUILDERS
  // =========================================================================

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.divider, height: 1);
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
