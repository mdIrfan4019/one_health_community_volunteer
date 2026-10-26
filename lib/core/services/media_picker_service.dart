import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cohv/core/theme/app_colors.dart';

/// Centralized media selection and capture service enforcing runtime permissions
/// for camera, microphone, photo library, and system document pickers.
class MediaPickerService {
  static MediaPickerService _instance = MediaPickerService._internal();
  factory MediaPickerService() => _instance;
  MediaPickerService._internal();
  MediaPickerService.base();

  /// Inject mock service for unit and widget testing.
  static void setMockInstance(MediaPickerService? mock) {
    _instance = mock ?? MediaPickerService._internal();
  }

  final ImagePicker _picker = ImagePicker();

  /// Request camera permission and take a photograph.
  Future<XFile?> capturePhoto(BuildContext context) async {
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (result.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDialog(
              context,
              title: 'Camera Permission Required',
              message:
                  'Camera access is required to take field photographs. Please enable Camera permissions in App Settings.',
            );
          }
          return null;
        }
        if (!result.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera permission was denied. Cannot take photo.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return null;
        }
      }

      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[MEDIA_PICKER] Error capturing photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  /// Request camera and microphone permissions and record a video.
  Future<XFile?> recordVideo(BuildContext context) async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        final statuses = await [Permission.camera, Permission.microphone].request();
        final camResult = statuses[Permission.camera] ?? PermissionStatus.denied;
        final micResult = statuses[Permission.microphone] ?? PermissionStatus.denied;

        if (camResult.isPermanentlyDenied || micResult.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDialog(
              context,
              title: 'Camera & Microphone Required',
              message:
                  'Camera and Microphone access are required to record video reports with sound. Please enable them in App Settings.',
            );
          }
          return null;
        }

        if (!camResult.isGranted || !micResult.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera or microphone permission was denied. Cannot record video.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return null;
        }
      }

      return await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      debugPrint('[MEDIA_PICKER] Error recording video: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  /// Select multiple images from device photo gallery using the modern system picker.
  Future<List<XFile>> pickImagesFromGallery(
    BuildContext context, {
    bool allowMultiple = true,
  }) async {
    try {
      if (allowMultiple) {
        final images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        return images;
      } else {
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        return image != null ? [image] : [];
      }
    } catch (e) {
      debugPrint('[MEDIA_PICKER] Error picking images from gallery: $e');
      return [];
    }
  }

  /// Select multiple image files via system picker, returning PlatformFile instances.
  Future<List<PlatformFile>> pickImageFiles(
    BuildContext context, {
    bool allowMultiple = true,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (result.isNotEmpty) {
        return result.where((f) => f.path != null && f.path!.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[MEDIA_PICKER] Error picking image files: $e');
      return [];
    }
  }

  /// Select a single video from gallery.
  Future<XFile?> pickVideoFromGallery(BuildContext context) async {
    try {
      return await _picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      debugPrint('[MEDIA_PICKER] Error picking video from gallery: $e');
      return null;
    }
  }

  /// Select document files via system document picker.
  Future<List<PlatformFile>> pickDocuments(
    BuildContext context, {
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: allowedExtensions != null && allowedExtensions.isNotEmpty
            ? FileType.custom
            : FileType.any,
        allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );

      if (result.isNotEmpty) {
        return result.where((f) => f.path != null && f.path!.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[MEDIA_PICKER] Error picking documents: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return [];
    }
  }

  void _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
