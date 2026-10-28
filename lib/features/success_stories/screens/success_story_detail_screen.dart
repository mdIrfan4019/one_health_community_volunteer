// Detail Screen for a Success Story fetched from GET /api/success-stories/{id}
// Matches Screenshot 2 & 3 exact design
// File: lib/features/success_stories/screens/success_story_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import '../data/success_story_api_service.dart';
import '../domain/success_story_models.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';
import 'new_success_story_screen.dart';

const Color storyPink = Color(0xFF136B4F);
const Color storyBackground = Color(0xFFF2F7F4);
const Color storyMuted = Color(0xFF89838F);
const Color storyBorder = Color(0xFFE9E3EA);

class SuccessStoryDetailScreen extends StatefulWidget {
  final int? storyId;
  final SuccessStoryRecordModel? initialStory;
  final SuccessStoryApiService? apiService;
  final String? volunteerId;
  final Map<String, dynamic>? story; // Legacy parameter compatibility

  const SuccessStoryDetailScreen({
    super.key,
    this.storyId,
    this.initialStory,
    this.apiService,
    this.volunteerId,
    this.story,
  });

  @override
  State<SuccessStoryDetailScreen> createState() =>
      _SuccessStoryDetailScreenState();
}

class _SuccessStoryDetailScreenState extends State<SuccessStoryDetailScreen> {
  late final SuccessStoryApiService _apiService;
  SuccessStoryRecordModel? _record;
  bool _isLoading = false;
  int _selectedIndex = 1; // Actions tab

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SuccessStoryApiService();

    if (widget.initialStory != null) {
      _record = widget.initialStory;
    } else if (widget.story != null) {
      _record = SuccessStoryRecordModel.fromJson(widget.story!);
    }

    final effectiveId = widget.storyId ?? _record?.storyId;
    if (effectiveId != null && effectiveId > 0) {
      if (_record == null) {
        _isLoading = true;
      }
      _fetchDetail(effectiveId);
    }
  }

  /// Fetches individual success story record by id from GET /api/success-stories/{id}
  Future<void> _fetchDetail([int? id]) async {
    final targetId = id ?? widget.storyId ?? _record?.storyId;
    if (targetId == null || targetId <= 0) return;

    try {
      final detail = await _apiService.fetchSuccessStoryDetail(targetId);
      if (detail != null && mounted) {
        setState(() {
          _record = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_DETAIL] Error fetching detail: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBottomNavigationTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStory = _record ??
        SuccessStoryRecordModel(
          storyId: widget.storyId ?? 1,
          storyCode: 'STY-26-0001',
          title: 'Success Story',
          storyDate: '2026-10-25',
          locationText: 'Location',
          oneHealthIssue: 'One Health Issue',
          situation: 'Situation / problem',
          actionTaken: 'Action taken',
          outcome: 'Outcome',
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: storyBackground,
        appBar: AuthenticatedAppBar(
          title: 'Success Story Details',
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () => Navigator.pop(context),
          backgroundColor: const Color(0xFF136B4F),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: storyPink),
              )
            : RefreshIndicator(
                onRefresh: _fetchDetail,
                color: storyPink,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Details Card
                      _buildDetailCard(effectiveStory),

                      const SizedBox(height: 18),

                      // 2. Outlined Back Button and Edit Button
                      _buildBackButton(effectiveStory),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildDetailCard(SuccessStoryRecordModel record) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Story Code
          Text(
            record.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF29252C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.storyCode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: storyPink,
            ),
          ),
          const SizedBox(height: 16),

          // 14 Key-value rows with dividers matching Screenshot 2 & 3
          _buildDetailRow('Title', record.title),
          _buildDivider(),
          _buildDetailRow('Date', record.formattedDate),
          _buildDivider(),
          _buildDetailRow('Location', record.locationText.isNotEmpty ? record.locationText : '—'),
          _buildDivider(),
          _buildDetailRow('One Health issue', record.oneHealthIssue.isNotEmpty ? record.oneHealthIssue : '—'),
          _buildDivider(),
          _buildDetailRow('Situation / problem', record.situation.isNotEmpty ? record.situation : '—'),
          _buildDivider(),
          _buildDetailRow('Action taken by COHV', record.actionTaken.isNotEmpty ? record.actionTaken : '—'),
          _buildDivider(),
          _buildDetailRow(
            'Departments / stakeholders',
            record.departmentName?.isNotEmpty == true
                ? record.departmentName!
                : (record.departmentOther?.isNotEmpty == true
                    ? record.departmentOther!
                    : '—'),
          ),
          _buildDivider(),
          _buildDetailRow('Outcome', record.outcome.isNotEmpty ? record.outcome : '—'),
          _buildDivider(),
          _buildDetailRow('Community benefit', record.communityBenefit?.isNotEmpty == true ? record.communityBenefit! : '—'),
          _buildDivider(),
          _buildDetailRow('Lessons learned', record.lessonsLearned?.isNotEmpty == true ? record.lessonsLearned! : '—'),
          _buildDivider(),
          _buildDetailRow('Innovation / best practice', record.formattedInnovation),
          _buildDivider(),
          _buildDetailRow('Verification', record.formattedVerificationStatus),
          _buildDivider(),
          _buildDetailRow('Synchronisation', record.formattedSyncStatus),
          _buildDivider(),
          _buildDetailRow('GPS location', record.formattedGpsLocation),

          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 14),

          // ATTACHMENTS Section
          AttachmentsSectionWidget(
            attachments: record.appAttachments,
            fallbackLatitude: record.latitude is num
                ? (record.latitude as num).toDouble()
                : double.tryParse(record.latitude?.toString() ?? ''),
            fallbackLongitude: record.longitude is num
                ? (record.longitude as num).toDouble()
                : double.tryParse(record.longitude?.toString() ?? ''),
            fallbackAccuracy: record.gpsAccuracyM,
            fallbackDate: DateTime.tryParse(record.capturedAt ?? record.storyDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        color: Color(0xFFF1F2F6),
        height: 1,
        thickness: 1,
      );

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: storyMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF29252C),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Attachments row displaying photo/video/doc thumbnail preview matching Screenshot 3
  Widget _buildAttachmentsRow(SuccessStoryRecordModel record) {
    return Row(
      children: [
        // 1. Photo Thumbnail
        _buildPhotoThumbnail(record),
        const SizedBox(width: 12),

        // 2. Video Thumbnail (if present or secondary placeholder)
        if (record.videos.isNotEmpty) ...[
          _buildVideoThumbnail(record),
          const SizedBox(width: 12),
        ],

        // 3. Document Thumbnail (if present)
        if (record.documents.isNotEmpty)
          _buildDocThumbnail(record),
      ],
    );
  }

  Widget _buildPhotoThumbnail(SuccessStoryRecordModel record) {
    Widget content;
    final hasPhoto = record.photos.isNotEmpty;

    if (hasPhoto) {
      final photoPath = record.photos.first;
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        content = Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPhotoFallback(),
        );
      } else {
        final file = File(photoPath);
        if (file.existsSync()) {
          content = Image.file(file, fit: BoxFit.cover);
        } else {
          content = _buildPhotoFallback();
        }
      }
    } else {
      content = _buildPhotoFallback();
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: content,
          ),
        ),
        // Circular badge at bottom right matching Screenshot 3
        Positioned(
          bottom: 3,
          right: 3,
          child: _buildCircularBadge(),
        ),
      ],
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      color: const Color(0xFF26262A),
      child: const Center(
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white70,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(SuccessStoryRecordModel record) {
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFD3D5DC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD0DC)),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF136B4F),
                    ),
                  ),
                ),
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 3,
          right: 3,
          child: _buildCircularBadge(),
        ),
      ],
    );
  }

  Widget _buildDocThumbnail(SuccessStoryRecordModel record) {
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEBF1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5DEE8)),
          ),
          child: const Center(
            child: Icon(
              Icons.description_rounded,
              size: 26,
              color: storyPink,
            ),
          ),
        ),
        Positioned(
          bottom: 3,
          right: 3,
          child: _buildCircularBadge(),
        ),
      ],
    );
  }

  Widget _buildCircularBadge() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF136B4F),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.camera_alt,
          size: 10,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBackButton(SuccessStoryRecordModel effectiveStory) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: storyPink,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewSuccessStoryScreen(
                      editStory: _record ?? effectiveStory,
                      initialVolunteerId: widget.volunteerId,
                    ),
                  ),
                );
                if (result != null) {
                  _fetchDetail();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: storyPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavigationTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: storyPink,
        unselectedItemColor: storyMuted,
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
            icon: Icon(Icons.apps_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
