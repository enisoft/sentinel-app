import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/sync/sync_failure_reason.dart';
import '../../core/sync/sync_phase.dart';
import '../../core/sync/sync_state.dart';
import '../../core/auth/auth_messages.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/gateways/sync_gateway.dart';
import '../local/app_database.dart';
import '../remote/api_exception.dart';
import '../remote/media_upload_exception.dart';
import '../repositories/occurrence_repository.dart';
import '../repositories/sync_queue_repository.dart';

class OccurrenceSyncResult {
  const OccurrenceSyncResult({
    required this.synced,
    required this.failed,
    required this.skipped,
    this.unauthorized = false,
    this.hadNetworkFailure = false,
  });

  final int synced;
  final int failed;
  final int skipped;
  final bool unauthorized;
  final bool hadNetworkFailure;

  OccurrenceSyncResult merge(OccurrenceSyncResult other) {
    return OccurrenceSyncResult(
      synced: synced + other.synced,
      failed: failed + other.failed,
      skipped: skipped + other.skipped,
      unauthorized: unauthorized || other.unauthorized,
      hadNetworkFailure: hadNetworkFailure || other.hadNetworkFailure,
    );
  }
}

/// Orquestra a fila offline E8 — upload TUS, POST JSON, confirmação por data.ids.
class OccurrenceSyncService {
  OccurrenceSyncService({
    required SyncQueueRepository queueRepository,
    required OccurrenceRepository occurrenceRepository,
    required SyncGateway syncGateway,
    required AuthGateway authGateway,
  })  : _queue = queueRepository,
        _occurrences = occurrenceRepository,
        _gateway = syncGateway,
        _auth = authGateway;

  final SyncQueueRepository _queue;
  final OccurrenceRepository _occurrences;
  final SyncGateway _gateway;
  final AuthGateway _auth;

  static const _validationPrefix = SyncFailureReason.validationPrefix;

  Future<OccurrenceSyncResult> processPending() async {
    var synced = 0;
    var failed = 0;
    var skipped = 0;
    var hadNetworkFailure = false;
    final attemptedThisCycle = <String>{};

    while (true) {
      final pending = await _queue.getPendingOccurrences();
      var madeAttempt = false;

      for (final occurrence in pending) {
        if (attemptedThisCycle.contains(occurrence.id)) continue;
        if (occurrence.syncState == SyncState.synced) continue;

        if (_isNonRetryable(occurrence)) {
          attemptedThisCycle.add(occurrence.id);
          skipped++;
          madeAttempt = true;
          continue;
        }

        attemptedThisCycle.add(occurrence.id);
        madeAttempt = true;

        try {
          await _advanceMedia(occurrence.id);
        } on MediaUploadException catch (e) {
          if (e.isUnauthorized) {
            if (await _auth.shouldSignOutForUnauthorized(
              statusCode: e.statusCode,
              isNetworkError: e.isNetworkError,
            )) {
              await _auth.signOut(loginNotice: AuthMessages.sessionExpired);
              return OccurrenceSyncResult(
                synced: synced,
                failed: failed,
                skipped: skipped,
                unauthorized: true,
                hadNetworkFailure: hadNetworkFailure,
              );
            }
            hadNetworkFailure = true;
            await _occurrences.recordFailure(
              occurrence.id,
              SyncPhase.mediaUploading,
              e.message,
            );
            failed++;
            continue;
          }
          if (e.isNetworkError) hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.mediaUploading,
            e.message,
          );
          failed++;
          continue;
        } on SocketException catch (e) {
          hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.mediaUploading,
            e.message,
          );
          failed++;
          continue;
        } on http.ClientException catch (e) {
          hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.mediaUploading,
            e.message,
          );
          failed++;
          continue;
        } on TimeoutException catch (e) {
          hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.mediaUploading,
            e.message ?? 'timeout',
          );
          failed++;
          continue;
        }

        try {
          await _advanceToJsonSync(occurrence.id);

          final current = await _occurrences.getById(occurrence.id);
          if (current == null || current.syncState != SyncState.jsonSyncing) {
            continue;
          }

          final confirmedIds = await _gateway.syncOccurrences(
            occurrenceIds: [occurrence.id],
          );

          if (confirmedIds.contains(occurrence.id)) {
            await _occurrences.markSynced(occurrence.id);
            synced++;
          }
        } on ApiException catch (e) {
          if (e.isUnauthorized) {
            if (await _auth.shouldSignOutForUnauthorized(
              statusCode: e.statusCode,
              isNetworkError: e.isNetworkError,
            )) {
              await _auth.signOut(loginNotice: AuthMessages.sessionExpired);
              return OccurrenceSyncResult(
                synced: synced,
                failed: failed,
                skipped: skipped,
                unauthorized: true,
                hadNetworkFailure: hadNetworkFailure,
              );
            }
            hadNetworkFailure = true;
            await _occurrences.recordFailure(
              occurrence.id,
              SyncPhase.jsonSyncing,
              e.message,
            );
            failed++;
            continue;
          }

          if (e.isNetworkError) hadNetworkFailure = true;

          if (e.isValidation) {
            final reason = '$_validationPrefix${e.message}';
            await _occurrences.recordFailure(
              occurrence.id,
              SyncPhase.jsonSyncing,
              reason,
            );
            debugPrint('OccurrenceSync validation failure (${occurrence.id}): ${e.message}');
          } else {
            await _occurrences.recordFailure(
              occurrence.id,
              SyncPhase.jsonSyncing,
              e.message,
            );
          }
          failed++;
        } on SocketException catch (e) {
          hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.jsonSyncing,
            e.message,
          );
          failed++;
        } on http.ClientException catch (e) {
          hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.jsonSyncing,
            e.message,
          );
          failed++;
        } on TimeoutException catch (e) {
          hadNetworkFailure = true;
          await _occurrences.recordFailure(
            occurrence.id,
            SyncPhase.jsonSyncing,
            e.message ?? 'timeout',
          );
          failed++;
        }
      }

      if (!madeAttempt) break;
    }

    return OccurrenceSyncResult(
      synced: synced,
      failed: failed,
      skipped: skipped,
      hadNetworkFailure: hadNetworkFailure,
    );
  }

  bool _isNonRetryable(Occurrence occurrence) {
    return occurrence.syncState == SyncState.failed &&
        (occurrence.failedReason?.startsWith(_validationPrefix) ?? false);
  }

  Future<void> _advanceMedia(String id) async {
    var occurrence = await _occurrences.getById(id);
    if (occurrence == null) return;

    if (occurrence.syncState == SyncState.failed) {
      occurrence = await _occurrences.retry(id);
    }

    if (occurrence.syncState == SyncState.localSaved) {
      final hasMedia = await _occurrences.hasMedia(id);
      if (hasMedia) {
        occurrence = await _occurrences.beginMediaUpload(id);
      } else {
        await _occurrences.markMediaDone(id);
        return;
      }
    }

    if (occurrence.syncState == SyncState.mediaUploading) {
      await _gateway.uploadOccurrenceMedia(occurrenceId: id);
      if (!await _occurrences.allMediaUploaded(id)) {
        throw MediaUploadException(null, 'Upload incompleto: mídia sem remote_path.');
      }
      await _occurrences.markMediaDone(id);
    }
  }

  Future<void> _advanceToJsonSync(String id) async {
    final occurrence = await _occurrences.getById(id);
    if (occurrence == null) return;

    if (occurrence.syncState == SyncState.mediaDone) {
      await _occurrences.beginJsonSync(id);
    }
  }
}
