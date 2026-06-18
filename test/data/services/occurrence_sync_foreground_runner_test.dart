import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/capture/occurrence_lifecycle_status.dart';
import 'package:sentinel_app/core/sync/occurrence_sync_coordinator_state.dart';
import 'package:sentinel_app/data/fakes/fake_occurrence_sync_coordinator.dart';
import 'package:sentinel_app/data/fakes/fake_sync_foreground_platform.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/occurrence_sync_foreground_runner.dart';
import 'package:sentinel_app/data/services/occurrence_sync_service.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late FakeOccurrenceSyncCoordinator coordinator;
  late FakeSyncForegroundPlatform platform;
  late OccurrenceSyncForegroundRunner runner;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    queueRepo = SyncQueueRepository(db);
    coordinator = FakeOccurrenceSyncCoordinator();
    platform = FakeSyncForegroundPlatform();
    runner = OccurrenceSyncForegroundRunner(
      coordinator: coordinator,
      queueRepository: queueRepo,
      platform: platform,
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await db.close();
  });

  Future<void> seedPendingOccurrence(String id) async {
    await occurrenceRepo.createOccurrence(
      id: id,
      title: 'T',
      description: 'D',
      status: OccurrenceLifecycleStatus.pending,
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('runIfPending starts foreground before sync and stops when queue empty',
      () async {
    await seedPendingOccurrence('occ-1');

    coordinator.onSyncNow = () async {
      expect(platform.startCallCount, 1);
      await occurrenceRepo.markMediaDone('occ-1');
      await occurrenceRepo.beginJsonSync('occ-1');
      await occurrenceRepo.markSynced('occ-1');
      return const OccurrenceSyncResult(synced: 1, failed: 0, skipped: 0);
    };

    final result = await runner.runIfPending();

    expect(result!.synced, 1);
    expect(coordinator.syncNowCallCount, 1);
    expect(platform.permissionRequestCount, 1);
    expect(platform.startCallCount, 1);
    expect(platform.stopCallCount, 1);
  });

  test('runIfPending skips when pending count is zero', () async {
    final result = await runner.runIfPending();

    expect(result, isNull);
    expect(coordinator.syncNowCallCount, 0);
    expect(platform.startCallCount, 0);
    expect(platform.stopCallCount, 0);
  });

  test('runIfPending does not stop foreground when queue still has items',
      () async {
    await seedPendingOccurrence('occ-a');
    await seedPendingOccurrence('occ-b');

    coordinator.onSyncNow = () async {
      await occurrenceRepo.markMediaDone('occ-a');
      await occurrenceRepo.beginJsonSync('occ-a');
      await occurrenceRepo.markSynced('occ-a');
      return const OccurrenceSyncResult(synced: 1, failed: 0, skipped: 0);
    };

    await runner.runIfPending();

    expect(platform.startCallCount, 1);
    expect(platform.stopCallCount, 0);
    expect((await queueRepo.getPending()).totalCount, 1);
  });
}
