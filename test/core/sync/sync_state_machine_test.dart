import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/sync/invalid_sync_transition_exception.dart';
import 'package:sentinel_app/core/sync/sync_entity_type.dart';
import 'package:sentinel_app/core/sync/sync_phase.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/core/sync/sync_state_machine.dart';

void main() {
  const machine = SyncStateMachine();

  group('occurrence with media', () {
    test('localSaved -> mediaUploading -> mediaDone -> jsonSyncing -> synced', () {
      machine.assertTransition(
        from: SyncState.localSaved,
        to: SyncState.mediaUploading,
        entityType: SyncEntityType.occurrence,
        hasMedia: true,
      );
      machine.assertTransition(
        from: SyncState.mediaUploading,
        to: SyncState.mediaDone,
        entityType: SyncEntityType.occurrence,
        hasMedia: true,
      );
      machine.assertTransition(
        from: SyncState.mediaDone,
        to: SyncState.jsonSyncing,
        entityType: SyncEntityType.occurrence,
        hasMedia: true,
      );
      machine.assertTransition(
        from: SyncState.jsonSyncing,
        to: SyncState.synced,
        entityType: SyncEntityType.occurrence,
      );
    });

    test('rejects mediaUploading when occurrence has no media', () {
      expect(
        () => machine.assertTransition(
          from: SyncState.localSaved,
          to: SyncState.mediaUploading,
          entityType: SyncEntityType.occurrence,
          hasMedia: false,
        ),
        throwsA(isA<InvalidSyncTransitionException>()),
      );
    });
  });

  group('occurrence without media', () {
    test('localSaved -> mediaDone -> jsonSyncing -> synced', () {
      machine.assertTransition(
        from: SyncState.localSaved,
        to: SyncState.mediaDone,
        entityType: SyncEntityType.occurrence,
        hasMedia: false,
      );
      machine.assertTransition(
        from: SyncState.mediaDone,
        to: SyncState.jsonSyncing,
        entityType: SyncEntityType.occurrence,
        hasMedia: false,
      );
      machine.assertTransition(
        from: SyncState.jsonSyncing,
        to: SyncState.synced,
        entityType: SyncEntityType.occurrence,
      );
    });
  });

  group('check-in', () {
    test('localSaved -> jsonSyncing -> synced', () {
      machine.assertTransition(
        from: SyncState.localSaved,
        to: SyncState.jsonSyncing,
        entityType: SyncEntityType.checkIn,
      );
      machine.assertTransition(
        from: SyncState.jsonSyncing,
        to: SyncState.synced,
        entityType: SyncEntityType.checkIn,
      );
    });

    test('rejects media pipeline for check-in', () {
      expect(
        () => machine.assertTransition(
          from: SyncState.localSaved,
          to: SyncState.mediaUploading,
          entityType: SyncEntityType.checkIn,
        ),
        throwsA(isA<InvalidSyncTransitionException>()),
      );
    });
  });

  group('failure and retry', () {
    test('canFail excludes synced and failed', () {
      expect(machine.canFail(SyncState.jsonSyncing), isTrue);
      expect(machine.canFail(SyncState.synced), isFalse);
      expect(machine.canFail(SyncState.failed), isFalse);
    });

    test('stateForFailedPhase maps phase to active state', () {
      expect(
        machine.stateForFailedPhase(SyncPhase.mediaUploading),
        SyncState.mediaUploading,
      );
      expect(
        machine.stateForFailedPhase(SyncPhase.jsonSyncing),
        SyncState.jsonSyncing,
      );
    });

    test('retry from failed restores failed phase state', () {
      expect(
        machine.isRetryTransition(
          from: SyncState.failed,
          to: SyncState.jsonSyncing,
          failedPhase: SyncPhase.jsonSyncing,
        ),
        isTrue,
      );
      machine.assertTransition(
        from: SyncState.failed,
        to: SyncState.jsonSyncing,
        entityType: SyncEntityType.checkIn,
        failedPhase: SyncPhase.jsonSyncing,
      );
    });

    test('invalid transition is rejected', () {
      expect(
        () => machine.assertTransition(
          from: SyncState.localSaved,
          to: SyncState.synced,
          entityType: SyncEntityType.occurrence,
        ),
        throwsA(isA<InvalidSyncTransitionException>()),
      );
    });
  });
}
