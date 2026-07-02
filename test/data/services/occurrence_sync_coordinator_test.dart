import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/sync/occurrence_sync_coordinator_state.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_media_uploader.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/occurrence_sync_coordinator.dart';
import 'package:sentinel_app/data/services/occurrence_sync_service.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late FakeMediaUploader fakeMediaUploader;
  late FakeSyncGateway fakeGateway;
  late FakeAuthGateway fakeAuth;
  late OccurrenceSyncService syncService;
  late DefaultOccurrenceSyncCoordinator coordinator;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    queueRepo = SyncQueueRepository(db);
    fakeMediaUploader = FakeMediaUploader(occurrenceRepository: occurrenceRepo);
    fakeGateway = FakeSyncGateway(mediaUploader: fakeMediaUploader);
    fakeAuth = FakeAuthGateway();
    syncService = OccurrenceSyncService(
      queueRepository: queueRepo,
      occurrenceRepository: occurrenceRepo,
      syncGateway: fakeGateway,
      authGateway: fakeAuth,
    );
    coordinator = DefaultOccurrenceSyncCoordinator(
      syncService: syncService,
      queueRepository: queueRepo,
    );
  });

  tearDown(() async {
    coordinator.dispose();
    fakeAuth.dispose();
    await db.close();
  });

  Future<void> seedOccurrence({required String id, bool withMedia = false}) async {
    await occurrenceRepo.createOccurrence(
      id: id,
      title: 'Test',
      description: 'Desc',
      status: 'pending',
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
    );
    if (withMedia) {
      await occurrenceRepo.attachMedia(
        id: 'media-$id',
        occurrenceId: id,
        mediaType: 'image',
        localPath: '/tmp/photo-$id.jpg',
        mimeType: 'image/jpeg',
      );
    }
  }

  test('syncNow calls processPending once and transitions syncing to idle',
      () async {
    await seedOccurrence(id: 'occ-1', withMedia: true);
    fakeGateway.confirmedIds = ['occ-1'];

    final states = <OccurrenceSyncCoordinatorState>[];
    coordinator.state.addListener(() => states.add(coordinator.state.value));

    final result = await coordinator.syncNow();

    expect(result, isNotNull);
    expect(result!.synced, 1);
    expect(fakeGateway.syncCallCount, 1);
    expect(coordinator.state.value.status, OccurrenceSyncStatus.idle);
    expect(coordinator.state.value.lastResult?.success, isTrue);
    expect(
      states.map((s) => s.status),
      contains(OccurrenceSyncStatus.syncing),
    );
    expect(states.last.status, OccurrenceSyncStatus.idle);
  });

  test('concurrent syncNow calls do not run two cycles in parallel', () async {
    await seedOccurrence(id: 'occ-slow');

    final gate = Completer<void>();
    fakeGateway.onBeforeSync = () => gate.future;

    final first = coordinator.syncNow();
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.value.status, OccurrenceSyncStatus.syncing);

    final second = coordinator.syncNow();
    expect(await second, isNull);
    expect(fakeGateway.syncCallCount, 1);

    gate.complete();
    await first;

    expect(fakeGateway.syncCallCount, 1);
    expect(coordinator.state.value.status, OccurrenceSyncStatus.idle);
  });

  test('lastResult reflects failure when gateway fails', () async {
    await seedOccurrence(id: 'occ-fail', withMedia: true);
    fakeGateway.syncException = const SocketException('gateway down');

    await coordinator.syncNow();

    expect(coordinator.state.value.lastResult?.success, isFalse);
    expect(
      coordinator.state.value.lastResult?.errorMessage,
      contains('1 item(ns) falharam'),
    );
    expect(coordinator.state.value.status, OccurrenceSyncStatus.idle);
  });

  test('pending count is reflected in coordinator state', () async {
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.value.pendingCount, 0);

    await seedOccurrence(id: 'pending-a');
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.value.pendingCount, 1);

    await seedOccurrence(id: 'pending-b');
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.value.pendingCount, 2);

    fakeGateway.confirmedIds = ['pending-a', 'pending-b'];
    await coordinator.syncNow();
    await Future<void>.delayed(Duration.zero);

    expect(coordinator.state.value.pendingCount, 0);
    final occurrence = await occurrenceRepo.getById('pending-a');
    expect(occurrence!.syncState, SyncState.synced);
  });

  test('syncNow with empty queue returns idle without error', () async {
    final result = await coordinator.syncNow();

    expect(result, isNotNull);
    expect(result!.synced, 0);
    expect(coordinator.state.value.status, OccurrenceSyncStatus.idle);
    expect(coordinator.state.value.pendingCount, 0);
  });

  test('reportSyncProgress exposes current and total in state', () async {
    coordinator.reportSyncProgress(current: 2, total: 5);

    expect(coordinator.state.value.syncProgressCurrent, 2);
    expect(coordinator.state.value.syncProgressTotal, 5);
    expect(coordinator.state.value.isSyncInProgress, isTrue);

    coordinator.clearSyncProgress();

    expect(coordinator.state.value.syncProgressCurrent, isNull);
    expect(coordinator.state.value.syncProgressTotal, isNull);
    expect(coordinator.state.value.isSyncInProgress, isFalse);
  });
}
