import 'invalid_sync_transition_exception.dart';
import 'sync_entity_type.dart';
import 'sync_phase.dart';
import 'sync_state.dart';

class SyncStateMachine {
  const SyncStateMachine();

  void assertTransition({
    required SyncState from,
    required SyncState to,
    required SyncEntityType entityType,
    bool hasMedia = false,
    SyncPhase? failedPhase,
  }) {
    if (from == SyncState.failed) {
      if (!isRetryTransition(from: from, to: to, failedPhase: failedPhase)) {
        throw InvalidSyncTransitionException(from, to, 'invalid retry');
      }
      return;
    }

    if (!_isAllowed(from: from, to: to, entityType: entityType, hasMedia: hasMedia)) {
      throw InvalidSyncTransitionException(from, to);
    }
  }

  SyncState stateForFailedPhase(SyncPhase phase) => phase.correspondingState;

  SyncState stateForRetry(SyncPhase failedPhase) => failedPhase.correspondingState;

  bool isRetryTransition({
    required SyncState from,
    required SyncState to,
    required SyncPhase? failedPhase,
  }) {
    if (from != SyncState.failed || failedPhase == null) {
      return false;
    }
    return to == stateForRetry(failedPhase);
  }

  bool canFail(SyncState from) =>
      from != SyncState.synced && from != SyncState.failed;

  bool _isAllowed({
    required SyncState from,
    required SyncState to,
    required SyncEntityType entityType,
    required bool hasMedia,
  }) {
    if (to == SyncState.failed) {
      return canFail(from);
    }

    return switch ((from, to, entityType)) {
      (SyncState.localSaved, SyncState.mediaUploading, SyncEntityType.occurrence) =>
        hasMedia,
      (SyncState.localSaved, SyncState.mediaDone, SyncEntityType.occurrence) => !hasMedia,
      (SyncState.localSaved, SyncState.jsonSyncing, SyncEntityType.checkIn) => true,
      (SyncState.mediaUploading, SyncState.mediaDone, SyncEntityType.occurrence) => true,
      (SyncState.mediaDone, SyncState.jsonSyncing, SyncEntityType.occurrence) => true,
      (SyncState.jsonSyncing, SyncState.synced, _) => true,
      _ => false,
    };
  }
}
