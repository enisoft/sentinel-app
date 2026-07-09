import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../repositories/sync_queue_repository.dart';
import 'occurrence_sync_service.dart';

abstract class OccurrenceSyncCoordinator {
  ValueListenable<OccurrenceSyncCoordinatorState> get state;

  Future<OccurrenceSyncResult?> syncNow();

  void reportSyncProgress({required int current, required int total});

  void clearSyncProgress();

  /// Libera guard de reentrância após timeout externo no drain (ENI-105).
  void recoverFromExternalTimeout();

  void dispose();
}

/// Orquestra disparos sob demanda de [OccurrenceSyncService.processPending]
/// com estado observável e guard de reentrância.
class DefaultOccurrenceSyncCoordinator implements OccurrenceSyncCoordinator {
  DefaultOccurrenceSyncCoordinator({
    required OccurrenceSyncService syncService,
    required SyncQueueRepository queueRepository,
    Duration? syncCycleTimeout,
  })  : _syncService = syncService,
        _queueRepository = queueRepository,
        _syncCycleTimeout =
            syncCycleTimeout ?? const Duration(minutes: 30) {
    _pendingSubscription = _queueRepository.watchPending().listen((snapshot) {
      _emitState(_state.value.copyWith(pendingCount: snapshot.totalCount));
    });
  }

  final OccurrenceSyncService _syncService;
  final SyncQueueRepository _queueRepository;
  final Duration _syncCycleTimeout;

  final ValueNotifier<OccurrenceSyncCoordinatorState> _state =
      ValueNotifier(const OccurrenceSyncCoordinatorState());

  @override
  ValueListenable<OccurrenceSyncCoordinatorState> get state => _state;

  StreamSubscription<dynamic>? _pendingSubscription;
  bool _running = false;

  @override
  Future<OccurrenceSyncResult?> syncNow() async {
    if (_running) return null;

    _running = true;
    _emitState(_state.value.copyWith(status: OccurrenceSyncStatus.syncing));

    try {
      final result = await _syncService.processPending().timeout(
        _syncCycleTimeout,
        onTimeout: () => const OccurrenceSyncResult(
          synced: 0,
          failed: 0,
          skipped: 0,
          hadNetworkFailure: true,
        ),
      );
      final success = result.failed == 0 &&
          !result.unauthorized &&
          !result.hadNetworkFailure;
      _emitState(
        _state.value.copyWith(
          status: OccurrenceSyncStatus.idle,
          lastResult: OccurrenceSyncLastResult(
            success: success,
            at: DateTime.now(),
            syncResult: result,
            errorMessage: success
                ? null
                : result.unauthorized
                    ? 'Sessão expirada'
                    : result.hadNetworkFailure
                        ? 'Conexão indisponível'
                        : '${result.failed} item(ns) falharam',
          ),
        ),
      );
      return result;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      _emitState(
        _state.value.copyWith(
          status: OccurrenceSyncStatus.idle,
          lastResult: OccurrenceSyncLastResult(
            success: false,
            at: DateTime.now(),
            errorMessage: error.toString(),
          ),
        ),
      );
      return null;
    } finally {
      _running = false;
      if (_state.value.status == OccurrenceSyncStatus.syncing) {
        _emitState(_state.value.copyWith(status: OccurrenceSyncStatus.idle));
      }
    }
  }

  @override
  void reportSyncProgress({required int current, required int total}) {
    _emitState(
      _state.value.copyWith(
        syncProgressCurrent: current,
        syncProgressTotal: total,
      ),
    );
  }

  @override
  void clearSyncProgress() {
    _emitState(_state.value.copyWith(clearSyncProgress: true));
  }

  @override
  void recoverFromExternalTimeout() {
    _running = false;
    if (_state.value.status == OccurrenceSyncStatus.syncing) {
      _emitState(_state.value.copyWith(status: OccurrenceSyncStatus.idle));
    }
  }

  void _emitState(OccurrenceSyncCoordinatorState next) {
    _state.value = next;
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _state.dispose();
  }
}
