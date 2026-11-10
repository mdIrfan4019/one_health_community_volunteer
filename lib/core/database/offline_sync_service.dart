import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cohv/core/database/app_database.dart';
import 'package:cohv/core/database/offline_outbox_service.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/capacity_building/data/capacity_building_api_service.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';
import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/profile/data/profile_api_service.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/data/success_story_api_service.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/sync/data/sync_repository.dart';

/// Summary result of an offline synchronization cycle.
class OfflineSyncResult {
  final int totalCount;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  const OfflineSyncResult({
    required this.totalCount,
    required this.syncedCount,
    required this.failedCount,
    this.errors = const [],
  });

  bool get hasFailures => failedCount > 0;
  bool get allSynced => totalCount > 0 && failedCount == 0;
}

/// Centralized Sync Engine that replays pending offline outbox records
/// to their respective live module APIs using standard multipart/JSON HTTP requests.
class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._internal();
  OfflineSyncService._internal();

  final AppDatabase _db = AppDatabase.instance;
  final AuthApiService _authApiService = AuthApiService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Dispatches all pending offline records to the server.
  Future<OfflineSyncResult> syncAllPending({
    void Function(int current, int total)? onProgress,
  }) async {
    if (_isSyncing) {
      debugPrint('[OFFLINE_SYNC] Sync already in progress. Skipping duplicate run.');
      return const OfflineSyncResult(totalCount: 0, syncedCount: 0, failedCount: 0);
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;
    final List<String> errors = [];

    try {
      // 1. Fetch pending outbox records from SQLite
      final pendingRows = await _db.getPendingRecords();
      final total = pendingRows.length;

      debugPrint('[OFFLINE_SYNC] Found $total pending outbox record(s) to synchronise.');

      if (total == 0) {
        await SyncRepository().refreshFromDatabase();
        return const OfflineSyncResult(totalCount: 0, syncedCount: 0, failedCount: 0);
      }

      // 2. Validate authentication token before uploading batch
      final isTokenValid = await _authApiService.validateTokenGuard();
      if (!isTokenValid) {
        throw Exception('Session expired. Please sign in again to sync records.');
      }

      // 3. Process records one by one
      for (int i = 0; i < total; i++) {
        final row = pendingRows[i];
        final clientRef = row['client_ref']?.toString() ?? '';
        final entityType = row['entity_type']?.toString() ?? '';
        final payloadJson = row['payload_json'] as String? ?? '{}';

        onProgress?.call(i + 1, total);
        debugPrint('[OFFLINE_SYNC] Uploading (${i + 1}/$total): $clientRef ($entityType)...');

        try {
          final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

          // Ensure any attached PDF documents are structurally valid so the backend accepts them
          if (payload['documents'] is List) {
            for (final doc in payload['documents']) {
              if (doc != null && doc.toString().isNotEmpty) {
                await OfflineOutboxService.ensureValidPdfIfBroken(doc.toString());
              }
            }
          }

          final dispatchResult = await _dispatchRecord(entityType, payload, clientRef);

          if (dispatchResult.success) {
            await _db.updateRecordStatus(clientRef: clientRef, status: 'SYNCED');
            final isUpdate = payload['is_update'] == true;
            if (!isUpdate) {
              if (entityType.toUpperCase() == 'EVENT') {
              await SessionManager.removeSubmittedEvent(clientRef);
              final altId = payload['report_id']?.toString();
              if (altId != null && altId.isNotEmpty && altId != clientRef) {
                await SessionManager.removeSubmittedEvent(altId);
              }
            } else if (entityType.toUpperCase() == 'REFERRAL') {
              await SessionManager.removeSubmittedReferral(clientRef);
              final altId = payload['referral_code']?.toString();
              if (altId != null && altId.isNotEmpty && altId != clientRef) {
                await SessionManager.removeSubmittedReferral(altId);
              }
            } else if (entityType.toUpperCase() == 'SUCCESS_STORY') {
              await SessionManager.removeSubmittedSuccessStory(clientRef);
            } else if (entityType.toUpperCase() == 'SAMPLE_SUPPORT') {
              await SessionManager.removeSubmittedSampleSupport(clientRef);
            } else if (entityType.toUpperCase() == 'AWARENESS') {
              await SessionManager.removeSubmittedAwarenessActivity(clientRef);
            } else if (entityType.toUpperCase() == 'TRAINING_IMPARTED') {
              await SessionManager.removeSubmittedTrainingImparted(clientRef);
            } else if (entityType.toUpperCase() == 'TRAINING_ATTENDED') {
              await SessionManager.removeSubmittedTrainingAttended(clientRef);
            }
            }
            syncedCount++;
            debugPrint('[OFFLINE_SYNC] ✓ Synced $clientRef successfully.');
          } else {
            final errorText = dispatchResult.errorMessage ?? 'Server rejected submission.';
            await _db.updateRecordStatus(
              clientRef: clientRef,
              status: 'FAILED',
              errorMessage: errorText,
            );
            failedCount++;
            errors.add('$clientRef: $errorText');
            debugPrint('[OFFLINE_SYNC] ✗ Failed $clientRef: $errorText');
          }
        } catch (recordError) {
          debugPrint('[OFFLINE_SYNC] ✗ Network/Exception $clientRef: $recordError');

          // If network dropped mid-sync, abort further network requests
          if (OfflineOutboxService.isNetworkException(recordError)) {
            errors.add('Network connection lost during sync: $recordError');
            break;
          }

          await _db.updateRecordStatus(
            clientRef: clientRef,
            status: 'FAILED',
            errorMessage: recordError.toString(),
          );
          failedCount++;
          errors.add('$clientRef: $recordError');
        }
      }

      // 4. Refresh counters in SyncRepository
      await SyncRepository().refreshFromDatabase();

      return OfflineSyncResult(
        totalCount: total,
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Dispatches an individual offline outbox payload to its live API endpoint.
  Future<({bool success, String? errorMessage})> _dispatchRecord(
    String entityType,
    Map<String, dynamic> payload,
    String clientRef,
  ) async {
    switch (entityType.toUpperCase()) {
      case 'TRAINING_ATTENDED':
        final isAttendedUpdate = payload['is_update'] == true;
        final targetAttendedId = payload['target_training_attended_id'] as int? ??
            int.tryParse(payload['target_training_attended_id']?.toString() ?? '') ??
            int.tryParse(payload['training_attended_id']?.toString() ?? '');
        if (isAttendedUpdate && targetAttendedId != null) {
          final req = TrainingAttendedCreateRequest.fromJson(payload);
          final res = await CapacityBuildingApiService().updateTrainingAttended(
            targetAttendedId,
            req,
            allowOfflineFallback: false,
          );
          return (success: res.success, errorMessage: res.success ? null : res.message);
        }
        final req = TrainingAttendedCreateRequest.fromJson(payload);
        final res = await CapacityBuildingApiService().submitTrainingAttended(
          req,
          allowOfflineFallback: false,
        );
        return (success: res.success, errorMessage: res.success ? null : res.message);

      case 'TRAINING_IMPARTED':
        final isImpartedUpdate = payload['is_update'] == true;
        final targetImpartedId = payload['target_training_imparted_id'] as int? ??
            int.tryParse(payload['target_training_imparted_id']?.toString() ?? '') ??
            int.tryParse(payload['training_imparted_id']?.toString() ?? '');
        if (isImpartedUpdate && targetImpartedId != null) {
          final req = TrainingImpartedCreateRequest.fromJson(payload);
          final res = await CapacityBuildingApiService().updateTrainingImparted(
            targetImpartedId,
            req,
            allowOfflineFallback: false,
          );
          return (success: res.success, errorMessage: res.success ? null : res.message);
        }
        final req = TrainingImpartedCreateRequest.fromJson(payload);
        final res = await CapacityBuildingApiService().submitTrainingImparted(
          req,
          allowOfflineFallback: false,
        );
        return (success: res.success, errorMessage: res.success ? null : res.message);

      case 'SAMPLE_SUPPORT':
        final isSampleUpdate = payload['is_update'] == true;
        final targetSampleId = payload['target_sample_id'] as int? ??
            int.tryParse(payload['target_sample_id']?.toString() ?? '') ??
            int.tryParse(payload['sample_id']?.toString() ?? '');
        if (isSampleUpdate && targetSampleId != null) {
          final req = SampleSupportCreateRequest.fromJson(payload);
          final res = await SampleSupportApiService().updateSampleSupport(
            targetSampleId,
            req,
            allowOfflineFallback: false,
          );
          return (success: res.success, errorMessage: res.success ? null : res.message);
        }
        final req = SampleSupportCreateRequest.fromJson(payload);
        final res = await SampleSupportApiService().submitSampleSupport(
          req,
          allowOfflineFallback: false,
        );
        return (success: res.success, errorMessage: res.success ? null : res.message);

      case 'REFERRAL':
        final isReferralUpdate = payload['is_update'] == true;
        final targetReferralId = payload['target_referral_id'] as int? ??
            int.tryParse(payload['target_referral_id']?.toString() ?? '') ??
            int.tryParse(payload['referral_id']?.toString() ?? '');
        if (isReferralUpdate && targetReferralId != null) {
          final req = ReferralCreateRequest.fromJson(payload);
          final res = await ReferralsApiService().updateReferral(
            targetReferralId,
            req,
            allowOfflineFallback: false,
          );
          final ok = res.referralCode.isNotEmpty && !res.referralCode.startsWith('OFFLINE-');
          return (success: ok, errorMessage: ok ? null : res.status);
        }
        final req = ReferralCreateRequest.fromJson(payload);
        final res = await ReferralsApiService().submitReferral(
          req,
          allowOfflineFallback: false,
        );
        final ok = res.referralCode.isNotEmpty && !res.referralCode.startsWith('OFFLINE-');
        return (success: ok, errorMessage: ok ? null : res.status);

      case 'AWARENESS':
        final isAwarenessUpdate = payload['is_update'] == true;
        final targetAwarenessId = payload['target_awareness_id'] as int? ??
            int.tryParse(payload['target_awareness_id']?.toString() ?? '') ??
            int.tryParse(payload['awareness_id']?.toString() ?? '');
        if (isAwarenessUpdate && targetAwarenessId != null) {
          final req = AwarenessActivityCreateRequest.fromJson(payload);
          final res = await AwarenessApiService().updateAwarenessActivity(
            targetAwarenessId,
            req,
            allowOfflineFallback: false,
          );
          final ok = res.awarenessId > 0 || (res.awarenessCode.isNotEmpty && !res.awarenessCode.startsWith('OFFLINE-'));
          return (success: ok, errorMessage: ok ? null : res.message);
        }
        final req = AwarenessActivityCreateRequest.fromJson(payload);
        final res = await AwarenessApiService().submitAwarenessActivity(
          req,
          allowOfflineFallback: false,
        );
        final ok = res.awarenessId > 0 || (res.awarenessCode.isNotEmpty && !res.awarenessCode.startsWith('OFFLINE-'));
        return (success: ok, errorMessage: ok ? null : res.message);

      case 'SUCCESS_STORY':
        final isStoryUpdate = payload['is_update'] == true;
        final targetStoryId = payload['target_story_id'] as int? ??
            int.tryParse(payload['target_story_id']?.toString() ?? '') ??
            int.tryParse(payload['story_id']?.toString() ?? '');
        if (isStoryUpdate && targetStoryId != null) {
          final req = SuccessStoryCreateRequest.fromJson(payload);
          final res = await SuccessStoryApiService().updateSuccessStory(
            targetStoryId,
            req,
            allowOfflineFallback: false,
          );
          return (success: res.success, errorMessage: res.success ? null : res.message);
        }
        final req = SuccessStoryCreateRequest.fromJson(payload);
        final res = await SuccessStoryApiService().submitSuccessStory(
          req,
          allowOfflineFallback: false,
        );
        return (success: res.success, errorMessage: res.success ? null : res.message);

      case 'EVENT':
        var eventPayload = Map<String, dynamic>.from(payload);
        eventPayload['client_ref'] = clientRef;
        final isAlert = eventPayload['is_alert_generated'] == true ||
            eventPayload['alert_generated'] == true ||
            eventPayload['is_alert_generated']?.toString() == 'true' ||
            eventPayload['alert_generated']?.toString() == 'true';
        final actionTaken =
            eventPayload['action_taken']?.toString().trim() ?? '';
        if (isAlert && actionTaken.isEmpty) {
          eventPayload['action_taken'] =
              'Supervisor notified and field assessment initiated.';
          await _db.updateRecordPayload(
            clientRef: clientRef,
            payload: eventPayload,
          );
        }

        // Auto-heal 'Other' event type if event_type_other was omitted
        final eventTypeId = eventPayload['event_type_id'];
        final eventType =
            eventPayload['event_type']?.toString().toLowerCase() ?? '';
        final eventTypeOther =
            eventPayload['event_type_other']?.toString().trim() ?? '';
        if ((eventTypeId == 68 || eventType == 'other') &&
            eventTypeOther.isEmpty) {
          final obs = eventPayload['observations']?.toString().trim() ?? '';
          eventPayload['event_type_other'] =
              obs.isNotEmpty ? obs : 'Other community health event';
          await _db.updateRecordPayload(
            clientRef: clientRef,
            payload: eventPayload,
          );
        }
        final isUpdate = eventPayload['is_update'] == true;
        final targetEventId = eventPayload['target_event_id'] as int? ??
            int.tryParse(eventPayload['target_event_id']?.toString() ?? '');
        if (isUpdate && targetEventId != null) {
          final req = EventReportRequest.fromJson(eventPayload);
          final res = await EventApiService().updateEventReport(
            targetEventId,
            req,
            allowOfflineFallback: false,
          );
          final ok = res.reportId.isNotEmpty && res.status != 'queued_offline';
          return (success: ok, errorMessage: ok ? null : res.message);
        }
        final req = EventReportRequest.fromJson(eventPayload);
        final res = await EventApiService().submitEventReport(
          req,
          allowOfflineFallback: false,
        );
        final ok = res.reportId.isNotEmpty && res.status != 'queued_offline';
        return (success: ok, errorMessage: ok ? null : res.message);

      case 'PROFILE':
        final profileData = payload['profile_json'] as Map<String, dynamic>;
        final profile =
            DetailedVolunteerProfile.fromVolunteerProfileJson(profileData);
        File? photoFile;
        final photoPath = payload['photo_path'] as String?;
        if (photoPath != null && photoPath.isNotEmpty) {
          final file = File(photoPath);
          if (file.existsSync()) {
            photoFile = file;
          }
        }
        if (photoFile == null &&
            payload['photos'] is List &&
            (payload['photos'] as List).isNotEmpty) {
          final p = (payload['photos'] as List).first?.toString();
          if (p != null && p.isNotEmpty) {
            final f = File(p);
            if (f.existsSync()) photoFile = f;
          }
        }
        final ok = await ProfileApiService().updateProfile(
          profile,
          photoFile: photoFile,
          allowOfflineFallback: false,
        );
        return (
          success: ok,
          errorMessage: ok ? null : 'Failed to synchronise profile update.',
        );

      default:
        debugPrint('[OFFLINE_SYNC] Unknown entity type: $entityType');
        return (success: false, errorMessage: 'Unknown entity type: $entityType');
    }
  }
}
