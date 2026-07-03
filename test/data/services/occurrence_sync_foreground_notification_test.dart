import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/capture/occurrence_lifecycle_status.dart';
import 'package:sentinel_app/core/sync/sync_foreground_notification_text.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/fakes/fake_media_uploader.dart';
import 'package:sentinel_app/data/fakes/fake_sync_foreground_platform.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/remote/api_exception.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/occurrence_sync_coordinator.dart';
import 'package:sentinel_app/data/services/occurrence_sync_foreground_runner.dart';
import 'package:sentinel_app/data/services/occurrence_sync_service.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late FakeSyncForegroundPlatform platform;
  late FakeSyncGateway fakeGateway;
  late FakeAuthGateway fakeAuth;
  late DefaultOccurrenceSyncCoordinator coordinator;
  late OccurrenceSyncForegroundRunner runner;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    occurrenceRepo = OccurrenceRepository(db);
    queueRepo = SyncQueueRepository(db);
    platform = FakeSyncForegroundPlatform();
    fakeGateway = FakeSyncGateway();
    fakeAuth = FakeAuthGateway();
    final syncService = OccurrenceSyncService(
      queueRepository: queueRepo,
      occurrenceRepository: occurrenceRepo,
      syncGateway: fakeGateway,
      authGateway: fakeAuth,
    );
    coordinator = DefaultOccurrenceSyncCoordinator(
      syncService: syncService,
      queueRepository: queueRepo,
    );
    runner = OccurrenceSyncForegroundRunner(
      coordinator: coordinator,
      queueRepository: queueRepo,
      platform: platform,
    );
  });

  tearDown(() async {
    coordinator.dispose();
    fakeAuth.dispose();
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

  test('notification shows waiting for connection when offline', () async {
    await seedPendingOccurrence('occ-offline');
    fakeGateway.syncException = ApiException.network('connection failed');

    await runner.runIfPending();

    expect(platform.notificationUpdates, isNotEmpty);
    final last = platform.notificationUpdates.last;
    expect(last.title, SyncForegroundNotificationText.titleWaiting);
    expect(
      last.text,
      SyncForegroundNotificationText.waitingForConnection(1),
    );
    expect((await queueRepo.getPending()).totalCount, 1);
    expect(platform.stopCallCount, 0);
  });

  test('notification shows sending progress while online', () async {
    await seedPendingOccurrence('occ-online-a');
    await seedPendingOccurrence('occ-online-b');
    fakeGateway.confirmedIds = ['occ-online-a', 'occ-online-b'];

    await runner.runIfPending();

    expect(
      platform.notificationUpdates.any(
        (update) =>
            update.title == SyncForegroundNotificationText.titleSending &&
            update.text ==
                SyncForegroundNotificationText.sendingProgress(
                  current: 1,
                  total: 2,
                ),
      ),
      isTrue,
    );
    expect((await queueRepo.getPending()).totalCount, 0);
    expect(platform.stopCallCount, 1);
  });
}
