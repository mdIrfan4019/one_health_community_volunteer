// Dedicated Detail Screen for Awareness Activity
// File: lib/features/awareness/presentation/screen/awareness_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';
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
    if (_activity.latitude == 0.0 && _activity.longitude == 0.0) {
      return '—';
    }
    final latStr = _activity.latitude.toStringAsFixed(6);
    final lngStr = _activity.longitude.toStringAsFixed(6);
    if (_activity.accuracy > 0) {
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
          volunteerId: _activity.volunteerId,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: _isLoading && _activity.peopleReached == 0 && _activity.village.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _fetchDetail,
                color: AppColors.primary,
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
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
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
                            color: AppColors.primary,
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
              color: Color(0xFF9D174D),
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
          const Text(
            'ATTACHMENTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildAttachmentsSection(),
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

  Widget _buildAttachmentsSection() {
    final List<Widget> items = [];

    // 1. Structured Attachments from API
    if (_activity.attachments.isNotEmpty) {
      for (final att in _activity.attachments) {
        items.add(_buildAttachmentThumbnail(att));
      }
    }
    // 2. Fallback to mediaFiles (local files or paths)
    else if (_activity.mediaFiles.isNotEmpty) {
      for (final path in _activity.mediaFiles) {
        items.add(_buildLocalMediaThumbnail(path));
      }
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No attachments uploaded.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items,
    );
  }

  Widget _buildAttachmentThumbnail(AwarenessAttachmentItem att) {
    final isVideo = att.fileKind.toUpperCase() == 'VIDEO';
    final isDoc = att.fileKind.toUpperCase() == 'DOCUMENT';

    final candidateUrls = _buildCandidateUrls(att.storagePath);

    return InkWell(
      onTap: () => _showMediaDialog(
        title: att.fileName.isNotEmpty ? att.fileName : att.fileKind,
        urls: candidateUrls,
        isImage: !isVideo && !isDoc,
        isVideo: isVideo,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: isVideo
                ? _buildVideoPlaceholder()
                : isDoc
                    ? _buildDocPlaceholder(att.fileName)
                    : FallbackNetworkImage(
                        urls: candidateUrls,
                        fit: BoxFit.cover,
                        fallbackBuilder: (_) => _buildImagePlaceholder(),
                      ),
          ),
          // Small magenta circular indicator at bottom-right corner
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFDB2777),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo
                    ? Icons.videocam
                    : isDoc
                        ? Icons.description
                        : Icons.camera_alt,
                color: Colors.white,
                size: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalMediaThumbnail(String path) {
    final lower = path.toLowerCase();
    final isVideo = lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi');
    final isDoc = lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx');

    final candidateUrls = _buildCandidateUrls(path);

    return InkWell(
      onTap: () => _showMediaDialog(
        title: path.split(Platform.pathSeparator).last,
        urls: candidateUrls,
        localFilePath: path,
        isImage: !isVideo && !isDoc,
        isVideo: isVideo,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: isVideo
                ? _buildVideoPlaceholder()
                : isDoc
                    ? _buildDocPlaceholder(path.split(Platform.pathSeparator).last)
                    : FallbackNetworkImage(
                        urls: candidateUrls,
                        localFilePath: path,
                        fit: BoxFit.cover,
                        fallbackBuilder: (_) => _buildImagePlaceholder(),
                      ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFDB2777),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo
                    ? Icons.videocam
                    : isDoc
                        ? Icons.description
                        : Icons.camera_alt,
                color: Colors.white,
                size: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'VIDEO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 2),
          Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildDocPlaceholder(String name) {
    return Container(
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.all(4),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_rounded, color: Color(0xFFD97706), size: 24),
          SizedBox(height: 2),
          Text(
            'DOC',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.textLight, size: 28),
    );
  }

  List<String> _buildCandidateUrls(String rawPath) {
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return [rawPath];
    }
    final normalized = rawPath.replaceAll(r'\', '/');
    final cleanPath = normalized.startsWith('/') ? normalized : '/$normalized';

    return [
      '${ApiConstants.serverRoot}$cleanPath',
      '${ApiConstants.baseUrl}$cleanPath',
      '${ApiConstants.fileBaseUrl}$cleanPath',
    ];
  }

  void _showMediaDialog({
    required String title,
    List<String> urls = const [],
    String? localFilePath,
    bool isImage = true,
    bool isVideo = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: isImage
                      ? Container(
                          constraints: const BoxConstraints(maxHeight: 320),
                          width: double.infinity,
                          child: FallbackNetworkImage(
                            urls: urls,
                            localFilePath: localFilePath,
                            fit: BoxFit.contain,
                            fallbackBuilder: (_) => Container(
                              height: 180,
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textLight,
                                size: 40,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: const Color(0xFFF1F5F9),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isVideo ? Icons.videocam_rounded : Icons.description_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isVideo ? 'Video Attachment' : 'Document File',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
