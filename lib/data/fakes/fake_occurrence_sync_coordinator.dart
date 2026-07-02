import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/sync/occurrence_sync_coordinator_state.dart';
import '../services/occurrence_sync_coordinator.dart';
import '../services/occurrence_sync_service.dart';

/// Fake controlável para testes de UI e injeção em [configureDependenciesForTesting].
class FakeOccurrenceSyncCoordinator implements OccurrenceSyncCoordinator {
  FakeOccurrenceSyncCoordinator({
    OccurrenceSyncCoordinatorState initialState =
        const OccurrenceSyncCoordinatorState(),
  }) : _state = ValueNotifier(initialState);

  final ValueNotifier<OccurrenceSyncCoordinatorState> _state;

  @override
  ValueListenable<OccurrenceSyncCoordinatorState> get state => _state;

  int syncNowCallCount = 0;
  bool running = false;
  Future<OccurrenceSyncResult> Function()? onSyncNow;
  final List<Completer<void>> _barriers = [];

  void setState(OccurrenceSyncCoordinatorState next) {
    _state.value = next;
  }

  @override
  Future<OccurrenceSyncResult?> syncNow() async {
    if (running) return null;

    syncNowCallCount++;
    running = true;
    _state.value = _state.value.copyWith(status: OccurrenceSyncStatus.syncing);

    try {
      for (final barrier in _barriers) {
        await barrier.future;
      }

      if (onSyncNow != null) {
        final result = await onSyncNow!();
        final success = result.failed == 0 && !result.unauthorized;
        _state.value = _state.value.copyWith(
          status: OccurrenceSyncStatus.idle,
          lastResult: OccurrenceSyncLastResult(
            success: success,
            at: DateTime.now(),
            syncResult: result,
            errorMessage: success ? null : '${result.failed} item(ns) falharam',
          ),
        );
        return result;
      }

      _state.value = _state.value.copyWith(status: OccurrenceSyncStatus.idle);
      return const OccurrenceSyncResult(synced: 0, failed: 0, skipped: 0);
    } finally {
      running = false;
    }
  }

  /// Bloqueia [syncNow] no meio da execução — útil para testar reentrância.
  void holdUntilReleased() {
    _barriers.add(Completer<void>());
  }

  void releaseBarriers() {
    for (final barrier in _barriers) {
      if (!barrier.isCompleted) barrier.complete();
    }
    _barriers.clear();
  }

  @override
  void reportSyncProgress({required int current, required int total}) {
    _state.value = _state.value.copyWith(
      syncProgressCurrent: current,
      syncProgressTotal: total,
    );
  }

  @override
  void clearSyncProgress() {
    _state.value = _state.value.copyWith(clearSyncProgress: true);
  }

  @override
  void dispose() {
    _state.dispose();
  }
}
