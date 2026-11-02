import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';

/// Central service for persistent offline caching and retrieval of media attachments
/// (photos, videos, documents/PDFs).
class LocalMediaCacheService {
  static final LocalMediaCacheService instance = LocalMediaCacheService._internal();
  LocalMediaCacheService._internal();

  Directory? _mediaDir;

  /// Returns the persistent offline media directory under app documents
  Future<Directory> getOfflineMediaDir() async {
    if (_mediaDir != null && await _mediaDir!.exists()) {
      return _mediaDir!;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/offline_media');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _mediaDir = dir;
    return dir;
  }

  /// Copies a newly picked/captured device file into the persistent offline media directory.
  /// Guarantees that files in cache/temporary directories are permanently preserved.
  Future<String?> persistLocalFile(String sourcePath, {String? targetFileName}) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final dir = await getOfflineMediaDir();
      final cleanName = targetFileName?.trim().isNotEmpty == true
          ? targetFileName!.trim()
          : source.uri.pathSegments.last;

      final destFile = File('${dir.path}/$cleanName');
      if (source.path != destFile.path) {
        await source.copy(destFile.path);
        debugPrint('[MEDIA_CACHE] Persisted file to: ${destFile.path}');
      }
      return destFile.path;
    } catch (e) {
      debugPrint('[MEDIA_CACHE] Error persisting file $sourcePath: $e');
      return sourcePath;
    }
  }

  /// Attempts to find a local file for an attachment by inspecting:
  /// 1. storagePath (exact file check)
  /// 2. <offlineMediaDir>/<fileName>
  /// 3. <appDocDir>/<fileName>
  /// 4. <tempDir>/<fileName>
  /// 5. <tempDir>/image_picker/<fileName>
  Future<File?> findLocalFile({String? storagePath, String? fileName}) async {
    // 1. Direct path check
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      final trimmed = storagePath.trim();
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        final f = File(trimmed);
        if (f.existsSync()) return f;
      }
    }

    // Determine clean filename
    String? cleanName = fileName?.trim();
    if (cleanName == null || cleanName.isEmpty) {
      if (storagePath != null && storagePath.trim().isNotEmpty) {
        cleanName = storagePath.trim().split(Platform.pathSeparator).last.split('/').last;
      }
    }
    if (cleanName == null || cleanName.isEmpty) return null;

    try {
      // 2. Check offline media directory
      final mediaDir = await getOfflineMediaDir();
      final mediaFile = File('${mediaDir.path}/$cleanName');
      if (mediaFile.existsSync()) return mediaFile;

      final docDir = await getApplicationDocumentsDirectory();

      // 3. Check offline_vault subdirectories (photos, documents, videos)
      final dotIdx = cleanName.lastIndexOf('.');
      final nameWithoutExt = dotIdx != -1 ? cleanName.substring(0, dotIdx) : cleanName;
      final ext = dotIdx != -1 ? cleanName.substring(dotIdx).toLowerCase() : '';

      for (final subDirName in ['photos', 'documents', 'videos']) {
        final vaultSubDir = Directory('${docDir.path}/offline_vault/$subDirName');
        if (vaultSubDir.existsSync()) {
          final exactVaultFile = File('${vaultSubDir.path}/$cleanName');
          if (exactVaultFile.existsSync()) return exactVaultFile;

          // Check for files starting with nameWithoutExt in case a timestamp was appended
          try {
            final entities = vaultSubDir.listSync();
            for (final entity in entities) {
              if (entity is File) {
                final base = entity.uri.pathSegments.last;
                if (base.toLowerCase().startsWith(nameWithoutExt.toLowerCase()) &&
                    (ext.isEmpty || base.toLowerCase().endsWith(ext))) {
                  return entity;
                }
              }
            }
          } catch (_) {}
        }
      }

      // 4. Check application documents directory
      final docFile = File('${docDir.path}/$cleanName');
      if (docFile.existsSync()) return docFile;

      // 5. Check temporary / cache directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$cleanName');
      if (tempFile.existsSync()) {
        // Auto-promote to persistent offline media
        try {
          await tempFile.copy(mediaFile.path);
          return mediaFile;
        } catch (_) {
          return tempFile;
        }
      }

      // 6. Check image_picker subdirectory
      final pickerDir = Directory('${tempDir.path}/image_picker');
      if (pickerDir.existsSync()) {
        final pickerFile = File('${pickerDir.path}/$cleanName');
        if (pickerFile.existsSync()) {
          try {
            await pickerFile.copy(mediaFile.path);
            return mediaFile;
          } catch (_) {
            return pickerFile;
          }
        }

        try {
          final entities = pickerDir.listSync();
          for (final entity in entities) {
            if (entity is File) {
              final base = entity.uri.pathSegments.last;
              if (base.toLowerCase().startsWith(nameWithoutExt.toLowerCase()) &&
                  (ext.isEmpty || base.toLowerCase().endsWith(ext))) {
                return entity;
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[MEDIA_CACHE] Error locating local file for $cleanName: $e');
    }

    return null;
  }

  /// Synchronous fallback check for already resolved or cached files
  File? findLocalFileSync({String? storagePath, String? fileName}) {
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      final trimmed = storagePath.trim();
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        final f = File(trimmed);
        if (f.existsSync()) return f;
      }
    }
    return null;
  }

  /// Downloads and caches a remote attachment for offline viewing when online
  Future<File?> cacheRemoteMedia(String url, String fileName) async {
    try {
      final dir = await getOfflineMediaDir();
      final target = File('${dir.path}/$fileName');
      if (await target.exists()) return target;

      final token = await SessionManager.getToken();
      final headers = ApiConstants.defaultHeaders(token: token);

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await target.writeAsBytes(response.bodyBytes);
        debugPrint('[MEDIA_CACHE] Downloaded and cached remote file: ${target.path}');
        return target;
      }
    } catch (e) {
      debugPrint('[MEDIA_CACHE] Error downloading remote media ($url): $e');
    }
    return null;
  }
}
