import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/sync/sync_phase.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';
import 'package:sentinel_app/data/repositories/check_in_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';

/// Espelha o loop de sync de check-ins (E8) até existir serviço dedicado em produção.
Future<int> processPendingCheckIns({
  required SyncQueueRepository queue,
  required CheckInRepository checkIns,
  required FakeSyncGateway gateway,
}) async {
  var synced = 0;
  final pending = await queue.getPendingCheckIns();

  for (final checkIn in pending) {
    if (checkIn.syncState == SyncState.synced) continue;

    try {
      var current = checkIn;
      if (current.syncState == SyncState.failed) {
        current = await checkIns.retry(current.id);
      }
      if (current.syncState == SyncState.localSaved) {
        current = await checkIns.beginJsonSync(current.id);
      }
      if (current.syncState != SyncState.jsonSyncing) continue;

      final confirmedIds = await gateway.syncCheckIns(checkInIds: [current.id]);
      if (confirmedIds.contains(current.id)) {
        await checkIns.markSynced(current.id);
        synced++;
      }
    } on ApiException catch (e) {
      await checkIns.recordFailure(
        checkIn.id,
        SyncPhase.jsonSyncing,
        e.message,
      );
    }
  }

  return synced;
}

void main() {
  late AppDatabase db;
  late CheckInRepository checkInRepo;
  late SyncQueueRepository queueRepo;
  late FakeSyncGateway fakeGateway;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkInRepo = CheckInRepository(db);
    queueRepo = SyncQueueRepository(db);
    fakeGateway = FakeSyncGateway();
  });

  tearDown(() async {
    await db.close();
  });

  test('check-in sync failure records json_syncing phase and retries on next cycle',
      () async {
    await checkInRepo.createCheckIn(
      id: 'ci-retry',
      latitude: -25.5,
      longitude: -49.1,
      accuracy: 10,
      capturedAt: DateTime.utc(2026, 6, 18, 12, 0),
    );
    fakeGateway.checkInSyncException = ApiException(500, 'Erro interno.');

    final firstPass = await processPendingCheckIns(
      queue: queueRepo,
      checkIns: checkInRepo,
      gateway: fakeGateway,
    );

    expect(firstPass, 0);
    expect(fakeGateway.checkInSyncCallCount, 1);

    var checkIn = await checkInRepo.getById('ci-retry');
    expect(checkIn!.syncState, SyncState.failed);
    expect(checkIn.failedPhase, SyncPhase.jsonSyncing);
    expect(checkIn.retryCount, 1);

    fakeGateway.checkInSyncException = null;
    fakeGateway.confirmedCheckInIds = ['ci-retry'];

    final secondPass = await processPendingCheckIns(
      queue: queueRepo,
      checkIns: checkInRepo,
      gateway: fakeGateway,
    );

    expect(secondPass, 1);
    expect(fakeGateway.checkInSyncCallCount, 2);

    checkIn = await checkInRepo.getById('ci-retry');
    expect(checkIn!.syncState, SyncState.synced);
    expect(checkIn.syncedAt, isNotNull);
  });
}
