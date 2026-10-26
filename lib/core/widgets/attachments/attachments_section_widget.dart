import 'package:flutter/material.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';
import 'attachment_preview_dialog.dart';

/// Shared widget displaying the "ATTACHMENTS" section with 78x78 thumbnail cards
/// and bottom-right circular green badge matching Screenshot 1.
class AttachmentsSectionWidget extends StatelessWidget {
  final List<AppAttachmentItem> attachments;
  final double? fallbackLatitude;
  final double? fallbackLongitude;
  final int? fallbackAccuracy;
  final DateTime? fallbackDate;
  final bool hideWhenEmpty;

  const AttachmentsSectionWidget({
    super.key,
    required this.attachments,
    this.fallbackLatitude,
    this.fallbackLongitude,
    this.fallbackAccuracy,
    this.fallbackDate,
    this.hideWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty && hideWhenEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "ATTACHMENTS" in uppercase grey font
        const Text(
          'ATTACHMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        if (attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No attachments uploaded.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: attachments.map((att) => _buildThumbnailCard(context, att)).toList(),
          ),
      ],
    );
  }

  Widget _buildThumbnailCard(BuildContext context, AppAttachmentItem att) {
    final Widget cardContent;

    if (att.isVideo) {
      cardContent = _buildVideoThumbnail();
    } else if (att.isDocument) {
      cardContent = _buildDocThumbnail(att.fileName);
    } else {
      cardContent = _buildPhotoThumbnail(att);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AttachmentPreviewDialog.show(
          context,
          attachment: att,
          fallbackLatitude: fallbackLatitude,
          fallbackLongitude: fallbackLongitude,
          fallbackAccuracy: fallbackAccuracy,
          fallbackDate: fallbackDate,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: cardContent,
            ),

            // Circular Green Indicator Badge at bottom-right (Matching Screenshot 1)
            Positioned(
              right: 4,
              bottom: 4,
              child: _buildCircularBadge(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(AppAttachmentItem att) {
    final candidateUrls = att.getCandidateUrls();

    return FallbackNetworkImage(
      urls: candidateUrls,
      localFilePath: att.storagePath,
      fit: BoxFit.cover,
      fallbackBuilder: (_) => Container(
        color: const Color(0xFFE2E8F0),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFF94A3B8),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
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

  Widget _buildDocThumbnail(String fileName) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 0.8),
        ),
        child: const Text(
          'DOC',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF136B4F),
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularBadge() {
    return Container(
      width: 17,
      height: 17,
      decoration: const BoxDecoration(
        color: Color(0xFF136B4F),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 9.5,
        ),
      ),
    );
  }
}
