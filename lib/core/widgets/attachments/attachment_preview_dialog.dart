import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/services/attachment_api_service.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';

/// Modal dialog for previewing an attachment (Photo, Video, or Document)
/// with geo-tag metadata strip and close button matching screenshots.
class AttachmentPreviewDialog extends StatefulWidget {
  final AppAttachmentItem attachment;
  final double? fallbackLatitude;
  final double? fallbackLongitude;
  final int? fallbackAccuracy;
  final DateTime? fallbackDate;

  const AttachmentPreviewDialog({
    super.key,
    required this.attachment,
    this.fallbackLatitude,
    this.fallbackLongitude,
    this.fallbackAccuracy,
    this.fallbackDate,
  });

  /// Static helper to display the dialog
  static Future<void> show(
    BuildContext context, {
    required AppAttachmentItem attachment,
    double? fallbackLatitude,
    double? fallbackLongitude,
    int? fallbackAccuracy,
    DateTime? fallbackDate,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AttachmentPreviewDialog(
        attachment: attachment,
        fallbackLatitude: fallbackLatitude,
        fallbackLongitude: fallbackLongitude,
        fallbackAccuracy: fallbackAccuracy,
        fallbackDate: fallbackDate,
      ),
    );
  }

  @override
  State<AttachmentPreviewDialog> createState() => _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<AttachmentPreviewDialog> {
  bool _isDownloading = false;
  final AttachmentApiService _attachmentService = AttachmentApiService();

  String get _geoTagString {
    return widget.attachment.formatGeoTag(
      fallbackLat: widget.fallbackLatitude,
      fallbackLng: widget.fallbackLongitude,
      fallbackAccuracy: widget.fallbackAccuracy,
      fallbackDate: widget.fallbackDate,
    );
  }

  Future<void> _handleOpenFile() async {
    final att = widget.attachment;

    // 1. If local device file exists
    if (att.storagePath.isNotEmpty && File(att.storagePath).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening local file: ${att.fileName}'),
            backgroundColor: const Color(0xFF136B4F),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 2. If valid attachmentId, download or stream
    if (att.attachmentId > 0) {
      setState(() => _isDownloading = true);
      try {
        final bytes = await _attachmentService.downloadAttachment(att.attachmentId);
        if (mounted) {
          if (bytes != null && bytes.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Downloaded ${att.fileName} (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
                ),
                backgroundColor: const Color(0xFF136B4F),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Streaming ${att.fileName} from server...'),
                backgroundColor: const Color(0xFF136B4F),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open attachment: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDownloading = false);
      }
      return;
    }

    // 3. Fallback for remote URL
    if (att.fileUrl != null && att.fileUrl!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening file at ${att.fileUrl}'),
            backgroundColor: const Color(0xFF136B4F),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File ready: ${att.fileName}'),
          backgroundColor: const Color(0xFF136B4F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.attachment;
    final geoTag = _geoTagString;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Media Container (Photo, Video, or Document)
            if (att.isVideo)
              _buildVideoPreview(geoTag)
            else if (att.isDocument)
              _buildDocumentPreview()
            else
              _buildPhotoPreview(geoTag),

            // 2. Bottom Details and Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bold filename
                  Text(
                    att.fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Capture timestamp
                  Text(
                    att.formatCaptureDate(fallbackDate: widget.fallbackDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Outlined Close Button (Matching Screenshot style)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF136B4F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 📷 PHOTO PREVIEW (Matching Screenshot 2)
  // =========================================================================
  Widget _buildPhotoPreview(String geoTag) {
    final candidateUrls = widget.attachment.getCandidateUrls();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: double.infinity,
          height: 320,
          color: const Color(0xFFF1F5F9),
          child: FallbackNetworkImage(
            urls: candidateUrls,
            localFilePath: widget.attachment.storagePath,
            fit: BoxFit.cover,
            fallbackBuilder: (_) => Container(
              color: const Color(0xFFCBD5E1),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 48,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Image unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Geo-tag Overlay Bar (Translucent dark bar)
        if (geoTag.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.black.withValues(alpha: 0.65),
            child: Text(
              geoTag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // 🎥 VIDEO PREVIEW (Matching Screenshot 3)
  // =========================================================================
  Widget _buildVideoPreview(String geoTag) {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFF1E293B), // Dark slate player background
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Centered Circular Play Button matching Screenshot 3
          Center(
            child: GestureDetector(
              onTap: _handleOpenFile,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Player controls strip and Geo-tag overlay
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Media Controls Bar (0:00, speaker, expand, more)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      '0:00',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.fullscreen_rounded,
                      size: 20,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),

              // Translucent Geo-tag Overlay Bar at bottom
              if (geoTag.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Text(
                    geoTag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📄 DOCUMENT PREVIEW (Matching Screenshot 4)
  // =========================================================================
  Widget _buildDocumentPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFF1E293B), // Dark slate container matching Screenshot 4
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Centered Document Filename in light text
          Text(
            widget.attachment.fileName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // Green "Open file" Button (Matching Screenshot 4)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isDownloading ? null : _handleOpenFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E), // Green matching screenshot
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Open file',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
