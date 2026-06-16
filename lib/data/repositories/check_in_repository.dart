import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/invalid_sync_transition_exception.dart';
import '../../core/sync/sync_entity_type.dart';
import '../../core/sync/sync_phase.dart';
import '../../core/sync/sync_state.dart';
import '../../core/sync/sync_state_machine.dart';
import '../local/app_database.dart';

class CheckInRepository {
  CheckInRepository(this._db, {SyncStateMachine? stateMachine, Uuid? uuid})
      : _stateMachine = stateMachine ?? const SyncStateMachine(),
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final SyncStateMachine _stateMachine;
  final Uuid _uuid;

  Future<CheckIn> createCheckIn({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime capturedAt,
    String? note,
    String? id,
    DateTime? createdLocalAt,
  }) async {
    final now = createdLocalAt ?? DateTime.now().toUtc();
    final checkInId = id ?? _uuid.v4();

    await _db.into(_db.checkIns).insert(
          CheckInsCompanion.insert(
            id: checkInId,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            capturedAt: capturedAt,
            createdLocalAt: now,
            note: Value(note),
          ),
        );

    return (_db.select(_db.checkIns)..where((t) => t.id.equals(checkInId))).getSingle();
  }

  Future<CheckIn?> getById(String id) =>
      (_db.select(_db.checkIns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<CheckIn> beginJsonSync(String id) async {
    final checkIn = await _requireCheckIn(id);

    _stateMachine.assertTransition(
      from: checkIn.syncState,
      to: SyncState.jsonSyncing,
      entityType: SyncEntityType.checkIn,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(_db.checkIns)..where((t) => t.id.equals(id))).write(
          CheckInsCompanion(
            syncState: Value(SyncState.jsonSyncing),
            lastAttemptAt: Value(now),
          ),
        );

    return _requireCheckIn(id);
  }

  Future<CheckIn> markSynced(String id) async {
    final checkIn = await _requireCheckIn(id);

    _stateMachine.assertTransition(
      from: checkIn.syncState,
      to: SyncState.synced,
      entityType: SyncEntityType.checkIn,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(_db.checkIns)..where((t) => t.id.equals(id))).write(
          CheckInsCompanion(
            syncState: Value(SyncState.synced),
            syncedAt: Value(now),
            lastAttemptAt: Value(now),
            failedPhase: const Value(null),
            failedReason: const Value(null),
          ),
        );

    return _requireCheckIn(id);
  }

  Future<CheckIn> recordFailure(
    String id,
    SyncPhase phase,
    String reason,
  ) async {
    final checkIn = await _requireCheckIn(id);

    if (!_stateMachine.canFail(checkIn.syncState)) {
      throw InvalidSyncTransitionException(checkIn.syncState, SyncState.failed);
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.checkIns)..where((t) => t.id.equals(id))).write(
          CheckInsCompanion(
            syncState: Value(SyncState.failed),
            failedPhase: Value(phase),
            failedReason: Value(reason),
            retryCount: Value(checkIn.retryCount + 1),
            lastAttemptAt: Value(now),
          ),
        );

    return _requireCheckIn(id);
  }

  Future<CheckIn> retry(String id) async {
    final checkIn = await _requireCheckIn(id);
    final failedPhase = checkIn.failedPhase;
    if (failedPhase == null) {
      throw InvalidSyncTransitionException(
        SyncState.failed,
        SyncState.localSaved,
        'missing failed_phase',
      );
    }

    final target = _stateMachine.stateForRetry(failedPhase);

    _stateMachine.assertTransition(
      from: SyncState.failed,
      to: target,
      entityType: SyncEntityType.checkIn,
      failedPhase: failedPhase,
    );

    await (_db.update(_db.checkIns)..where((t) => t.id.equals(id))).write(
          CheckInsCompanion(
            syncState: Value(target),
            lastAttemptAt: Value(DateTime.now().toUtc()),
          ),
        );

    return _requireCheckIn(id);
  }

  Future<CheckIn> _requireCheckIn(String id) async {
    final checkIn = await getById(id);
    if (checkIn == null) {
      throw StateError('CheckIn not found: $id');
    }
    return checkIn;
  }
}
