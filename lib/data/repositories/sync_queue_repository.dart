import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/capture/occurrence_lifecycle_status.dart';
import '../../core/sync/sync_state.dart';
import '../local/app_database.dart';

class PendingSyncSnapshot {
  const PendingSyncSnapshot({
    required this.occurrences,
    required this.checkIns,
  });

  final List<Occurrence> occurrences;
  final List<CheckIn> checkIns;

  int get totalCount => occurrences.length + checkIns.length;
}

class SyncQueueRepository {
  SyncQueueRepository(this._db);

  final AppDatabase _db;

  Stream<PendingSyncSnapshot> watchPending() {
    final controller = StreamController<PendingSyncSnapshot>();
    StreamSubscription<List<Occurrence>>? occurrenceSub;
    StreamSubscription<List<CheckIn>>? checkInSub;

    Future<void> emitPending() async {
      if (!controller.isClosed) {
        controller.add(await getPending());
      }
    }

    controller.onListen = () {
      emitPending();
      occurrenceSub = _db.select(_db.occurrences).watch().listen((_) {
        emitPending();
      });
      checkInSub = _db.select(_db.checkIns).watch().listen((_) {
        emitPending();
      });
    };

    controller.onCancel = () async {
      await occurrenceSub?.cancel();
      await checkInSub?.cancel();
    };

    return controller.stream;
  }

  Future<PendingSyncSnapshot> getPending() async {
    final occurrences = await getPendingOccurrences();
    final checkIns = await getPendingCheckIns();
    return PendingSyncSnapshot(occurrences: occurrences, checkIns: checkIns);
  }

  Future<List<Occurrence>> getPendingOccurrences() {
    return (_db.select(_db.occurrences)
          ..where((t) => t.syncState.isNotValue(SyncState.synced.storageValue))
          ..where(
            (t) => t.status.equals(OccurrenceLifecycleStatus.pending),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdLocalAt)]))
        .get();
  }

  Future<List<CheckIn>> getPendingCheckIns() {
    return (_db.select(_db.checkIns)
          ..where((t) => t.syncState.isNotValue(SyncState.synced.storageValue))
          ..orderBy([(t) => OrderingTerm.asc(t.createdLocalAt)]))
        .get();
  }
}
