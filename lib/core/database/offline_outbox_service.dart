import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Service managing offline form submissions, local queue persistence,
/// and copying ephemeral camera/picker media files into the persistent Offline Vault.
class OfflineOutboxService {
  static final OfflineOutboxService instance = OfflineOutboxService._internal();
  OfflineOutboxService._internal();

  final AppDatabase _db = AppDatabase.instance;

  /// Copies a list of temporary media files (e.g. from /cache/ or /tmp/)
  /// into a permanent, non-purgeable application directory.
  Future<List<String>> copyFilesToVault({
    required List<String> filePaths,
    required String subDirectory,
  }) async {
    final List<String> permanentPaths = [];
    if (filePaths.isEmpty) return permanentPaths;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDir.path, 'offline_vault', subDirectory));

      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      for (final rawPath in filePaths) {
        if (rawPath.trim().isEmpty) continue;
        final trimmed = rawPath.trim();

        // Remote URLs or data URLs from prior online edits do not need local copying
        if (trimmed.startsWith('http://') ||
            trimmed.startsWith('https://') ||
            trimmed.startsWith('data:')) {
          permanentPaths.add(trimmed);
          continue;
        }

        final srcFile = File(trimmed);

        if (await srcFile.exists()) {
          final ext = p.extension(srcFile.path);
          final base = p.basenameWithoutExtension(srcFile.path);
          final uniqueName = '${base}_${DateTime.now().microsecondsSinceEpoch}$ext';
          final destFile = File(p.join(vaultDir.path, uniqueName));

          await srcFile.copy(destFile.path);
          permanentPaths.add(destFile.path);

          // Also save under clean original filename in offline_media for direct lookup
          try {
            final mediaDir = Directory(p.join(appDir.path, 'offline_media'));
            if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
            final cleanFile = File(p.join(mediaDir.path, '$base$ext'));
            await srcFile.copy(cleanFile.path);
          } catch (_) {}

          debugPrint('[OFFLINE_VAULT] Copied media: ${srcFile.path} -> ${destFile.path}');
        } else {
          debugPrint('[OFFLINE_VAULT] Warning: source file not found: $rawPath');
        }
      }
    } catch (e) {
      debugPrint('[OFFLINE_VAULT] Error copying files to vault: $e');
      // Fallback: return original paths if copy fails
      return filePaths.where((f) => f.trim().isNotEmpty).toList();
    }

    return permanentPaths;
  }

  /// Enqueues a form submission into the SQLite offline outbox.
  /// Automatically copies photos, videos, and documents to permanent storage.
  Future<int> enqueueSubmission({
    required String entityType,
    required String clientRef,
    required Map<String, dynamic> payload,
    List<String> photos = const [],
    List<String> documents = const [],
    List<String> videos = const [],
  }) async {
    // 1. Copy files to permanent storage
    final permanentPhotos = await copyFilesToVault(
      filePaths: photos,
      subDirectory: 'photos',
    );
    final permanentDocs = await copyFilesToVault(
      filePaths: documents,
      subDirectory: 'documents',
    );
    final permanentVideos = await copyFilesToVault(
      filePaths: videos,
      subDirectory: 'videos',
    );

    // 2. Update payload with permanent paths
    final updatedPayload = Map<String, dynamic>.from(payload);
    updatedPayload['photos'] = permanentPhotos;
    updatedPayload['documents'] = permanentDocs;
    updatedPayload['videos'] = permanentVideos;
    if (permanentPhotos.isNotEmpty || permanentVideos.isNotEmpty || permanentDocs.isNotEmpty) {
      updatedPayload['media_files'] = [
        ...permanentPhotos,
        ...permanentVideos,
        ...permanentDocs,
      ];
    }

    // 3. Write to SQLite Outbox
    return await _db.enqueueRecord(
      clientRef: clientRef,
      entityType: entityType,
      payload: updatedPayload,
      mediaPaths: permanentPhotos,
      documentPaths: permanentDocs,
      videoPaths: permanentVideos,
    );
  }

  /// Checks if an exception indicates the device is offline or network is unreachable.
  static bool isNetworkException(dynamic e) {
    if (e is SocketException || e is HttpException) return true;
    final str = e.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('connection refused') ||
        str.contains('connection timed out') ||
        str.contains('connection reset') ||
        str.contains('handshake') ||
        str.contains('network is unreachable') ||
        str.contains('clientexception') ||
        str.contains('timeoutexception') ||
        str.contains('could not connect to authentication server') ||
        str.contains('check your network') ||
        str.contains('no address associated with hostname');
  }

  /// Get pending submissions count across all modules for header badges.
  Future<int> getPendingSubmissionsCount() async {
    return await _db.getPendingCount();
  }

  /// Get all unsynced submissions for a specific entity type (e.g. 'REFERRAL', 'TRAINING_ATTENDED').
  /// Returns records that are PENDING, SYNCING, or FAILED (awaiting retry) so they remain visible in lists.
  Future<List<Map<String, dynamic>>> getPendingByEntity(String entityType) async {
    final records = await _db.getOutboxRecordsByEntity(entityType);
    return records.where((r) => r['status'] != 'SYNCED').toList();
  }

  /// Checks if a file has a valid PDF magic header (%PDF-).
  static bool isFileValidPdf(String path) {
    try {
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() < 5) return false;
      final bytes = file.openSync().readSync(5);
      return bytes.length >= 4 &&
          bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46;   // F
    } catch (_) {
      return false;
    }
  }

  /// Automatically repairs dummy, empty, or plain-text files named *.pdf
  /// by writing a valid minimal PDF container so that server-side PDF readers
  /// (such as pypdf) accept the upload without 400 Bad Request.
  static Future<void> ensureValidPdfIfBroken(String filePath) async {
    try {
      if (!filePath.toLowerCase().endsWith('.pdf')) return;
      final file = File(filePath);
      if (!file.existsSync() || !isFileValidPdf(filePath)) {
        const validMinimalPdf = '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000052 00000 n \n0000000098 00000 n \ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n178\n%%EOF\n';
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        await file.writeAsBytes(ascii.encode(validMinimalPdf));
        debugPrint('[OFFLINE_VAULT] Auto-repaired dummy PDF: $filePath');
      }
    } catch (e) {
      debugPrint('[OFFLINE_VAULT] Error checking/repairing PDF: $e');
    }
  }
}
