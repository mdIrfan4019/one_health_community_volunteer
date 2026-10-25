// Dedicated Screen displaying full details of a specific Referral
// File: lib/features/referrals/presentation/screen/referral_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';
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
    if (_referral.latitude == 0.0 && _referral.longitude == 0.0) {
      return '—';
    }
    final latStr = _referral.latitude.toStringAsFixed(6);
    final lngStr = _referral.longitude.toStringAsFixed(6);
    if (_referral.accuracy > 0) {
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
          volunteerId: _referral.volunteerId,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchDetail,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) ...[
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primary,
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 10),
                ],

                // 1. Main Referral Details Card (Matching Image 2 exact structure)
                _buildReferralDetailCard(),
                const SizedBox(height: 16),

                // 2. Attached Media & Documents (if any)
                if (_referral.attachments.isNotEmpty ||
                    _referral.mediaFiles.isNotEmpty) ...[
                  _buildAttachmentsCard(),
                  const SizedBox(height: 16),
                ],

                // 3. Back Button (Matching Image 2 exact style)
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
              color: Color(0xFF9D174D),
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
        ],
      ),
    );
  }

  // =========================================================================
  // CARD 2: ATTACHED MEDIA & DOCUMENTS (Image, Video, Document previews)
  // =========================================================================

  Widget _buildAttachmentsCard() {
    final count = _referral.attachments.isNotEmpty
        ? _referral.attachments.length
        : _referral.mediaFiles.length;

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
          Row(
            children: [
              const Text(
                'Attached Media & Documents',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9D174D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render structured attachments
          if (_referral.attachments.isNotEmpty)
            ..._referral.attachments.map((att) => _buildAttachmentItem(att))
          else
            ..._referral.mediaFiles.map((path) => _buildLocalMediaItem(path)),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(ReferralAttachmentItem att) {
    final isImage = att.fileKind.toUpperCase() == 'IMAGE';
    final isVideo = att.fileKind.toUpperCase() == 'VIDEO';

    final Color badgeBg;
    final Color badgeText;
    final IconData icon;

    if (isImage) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      icon = Icons.image_outlined;
    } else if (isVideo) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFDC2626);
      icon = Icons.videocam_outlined;
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFD97706);
      icon = Icons.description_outlined;
    }

    final sizeStr = att.sizeBytes > 0
        ? ' · ${(att.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeText, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.fileName.isNotEmpty ? att.fileName : att.storagePath,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${att.fileKind}$sizeStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isImage && att.storagePath.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF9D174D),
                size: 20,
              ),
              onPressed: () => _showPhotoPreview(att.storagePath),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalMediaItem(String path) {
    final isVideo = path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.mov');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isVideo ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVideo ? Icons.videocam_outlined : Icons.image_outlined,
              color: isVideo ? const Color(0xFFDC2626) : const Color(0xFF15803D),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path.split('/').last,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoPreview(String storagePath) {
    final candidateUrls = ApiConstants.resolveImageCandidateUrls(storagePath);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 320,
                      color: const Color(0xFFF1F5F9),
                      child: FallbackNetworkImage(
                        urls: candidateUrls,
                        fallbackBuilder: (_) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
            color: Color(0xFF9D174D),
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
