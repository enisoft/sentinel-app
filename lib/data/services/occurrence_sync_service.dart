import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/sync/sync_phase.dart';
import '../../core/sync/sync_state.dart';
import '../../core/auth/auth_messages.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/gateways/sync_gateway.dart';
import '../local/app_database.dart';
import '../remote/api_exception.dart';
import '../repositories/occurrence_repository.dart';
import '../repositories/sync_queue_repository.dart';

class OccurrenceSyncResult {
  const OccurrenceSyncResult({
    required this.synced,
    required this.failed,
    required this.skipped,
    this.unauthorized = false,
  });

  final int synced;
  final int failed;
  final int skipped;
  final bool unauthorized;
}

/// Orquestra a fila offline E8 — stub de mídia, POST JSON, confirmação por data.ids.
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

  static const _validationPrefix = 'validation:';

  Future<OccurrenceSyncResult> processPending() async {
    var synced = 0;
    var failed = 0;
    var skipped = 0;

    final pending = await _queue.getPendingOccurrences();

    for (final occurrence in pending) {
      if (occurrence.syncState == SyncState.synced) continue;

      if (_isNonRetryable(occurrence)) {
        skipped++;
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
          await _auth.signOut(loginNotice: AuthMessages.sessionExpired);
          return OccurrenceSyncResult(
            synced: synced,
            failed: failed,
            skipped: skipped,
            unauthorized: true,
          );
        }

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
        await _occurrences.recordFailure(
          occurrence.id,
          SyncPhase.jsonSyncing,
          e.message,
        );
        failed++;
      } on http.ClientException catch (e) {
        await _occurrences.recordFailure(
          occurrence.id,
          SyncPhase.jsonSyncing,
          e.message,
        );
        failed++;
      } on TimeoutException catch (e) {
        await _occurrences.recordFailure(
          occurrence.id,
          SyncPhase.jsonSyncing,
          e.message ?? 'timeout',
        );
        failed++;
      }
    }

    return OccurrenceSyncResult(
      synced: synced,
      failed: failed,
      skipped: skipped,
    );
  }

  bool _isNonRetryable(Occurrence occurrence) {
    return occurrence.syncState == SyncState.failed &&
        (occurrence.failedReason?.startsWith(_validationPrefix) ?? false);
  }

  Future<void> _advanceToJsonSync(String id) async {
    var occurrence = await _occurrences.getById(id);
    if (occurrence == null) return;

    if (occurrence.syncState == SyncState.failed) {
      occurrence = await _occurrences.retry(id);
    }

    if (occurrence.syncState == SyncState.localSaved) {
      await _occurrences.ensureStubRemotePaths(id);
      final hasMedia = await _occurrences.hasMedia(id);
      if (hasMedia) {
        occurrence = await _occurrences.beginMediaUpload(id);
        occurrence = await _occurrences.markMediaDone(id);
      } else {
        occurrence = await _occurrences.markMediaDone(id);
      }
    }

    if (occurrence.syncState == SyncState.mediaDone) {
      await _occurrences.beginJsonSync(id);
    }
  }
}
