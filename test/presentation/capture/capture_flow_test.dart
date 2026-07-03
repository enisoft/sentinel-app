import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/fakes/fake_media_uploader.dart';
import 'package:sentinel_app/data/fakes/fake_sync_foreground_platform.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/catalog_repository.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';
import 'package:sentinel_app/data/services/occurrence_sync_coordinator.dart';
import 'package:sentinel_app/presentation/capture/capture_home_screen.dart';
import 'package:sentinel_app/presentation/capture/in_app_capture_screen.dart';
import 'package:sentinel_app/presentation/capture/occurrence_draft_form_screen.dart';

import '../../support/counting_occurrence_sync_foreground_runner.dart';

void main() {
  late AppDatabase db;
  late CaptureOccurrenceService captureService;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;
  late CatalogRepository catalogRepo;
  late FakeMediaUploader fakeMediaUploader;
  late FakeSyncGateway fakeGateway;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeMediaUploader = FakeMediaUploader();
    fakeGateway = FakeSyncGateway(mediaUploader: fakeMediaUploader);
    await configureDependenciesForTesting(
      db,
      cameraSource: FakeCameraSource(),
      locationSource: FakeLocationSource(),
      hashService: FakeHashService(),
      syncGateway: fakeGateway,
    );
    fakeMediaUploader.occurrenceRepository = getIt<OccurrenceRepository>();
    captureService = getIt<CaptureOccurrenceService>();
    occurrenceRepo = getIt<OccurrenceRepository>();
    queueRepo = getIt<SyncQueueRepository>();
    catalogRepo = getIt<CatalogRepository>();

    await catalogRepo.seedForTesting(
      categories: const [
        CatalogItem(id: 'cat-ui', name: 'Evento'),
      ],
      observables: const [
        CatalogItem(id: 'obs-ui', name: 'Político', type: 'person'),
      ],
    );
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  testWidgets('capture button creates draft then shows form without blocking',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    expect(find.byType(OccurrenceDraftFormScreen), findsOneWidget);
    expect(find.byKey(const Key('category_field')), findsOneWidget);
    expect(find.byKey(const Key('pending_sync_badge')), findsNothing);

    final pendingBeforeConfirm = await queueRepo.getPending();
    expect(pendingBeforeConfirm.occurrences, isEmpty);
  });

  testWidgets('confirming form enqueues occurrence for sync', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evento').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('observable_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Político').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('note_field')), 'Nota UI');

    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byType(CaptureHomeScreen), findsOneWidget);
    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);
    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);
    expect(find.text('1 pendente(s)'), findsOneWidget);

    final pending = await queueRepo.getPending();
    expect(pending.occurrences, hasLength(1));

    final occurrence = await occurrenceRepo.getById(pending.occurrences.single.id);
    expect(occurrence!.status, 'pending');
    expect(occurrence.categoryId, 'cat-ui');
    expect(occurrence.observableId, 'obs-ui');
    expect(occurrence.description, 'Nota UI');
    expect(occurrence.syncState, SyncState.localSaved);
  });

  testWidgets('confirming form does not trigger automatic sync', (tester) async {
    final countingRunner = installCountingForegroundRunner();

    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evento').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('observable_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Político').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();
    await tester.pump();

    final pending = await queueRepo.getPending();
    expect(pending.occurrences, hasLength(1));
    expect(countingRunner.runIfPendingCallCount, 0);
  });

  testWidgets('manual sync clears pending badge', (tester) async {
    await occurrenceRepo.createOccurrence(
      id: 'pending-home',
      title: 'Test',
      description: 'Desc',
      status: 'pending',
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
    );
    fakeGateway.confirmedIds = ['pending-home'];

    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);
    expect(find.text('1 pendente(s)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync_now_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pending_sync_badge')), findsNothing);
  });

  testWidgets('sync now button calls runIfPending', (tester) async {
    await occurrenceRepo.createOccurrence(
      id: 'pending-manual',
      title: 'Test',
      description: 'Desc',
      status: 'pending',
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1),
    );

    final countingRunner = CountingOccurrenceSyncForegroundRunner(
      coordinator: getIt<OccurrenceSyncCoordinator>(),
      queueRepository: queueRepo,
      platform: FakeSyncForegroundPlatform(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(
          captureService: captureService,
          syncForegroundRunner: countingRunner,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync_now_button')));
    await tester.pumpAndSettle();

    expect(countingRunner.runIfPendingCallCount, 1);
  });

  testWidgets('add media opens capture preview screen before attaching',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_media_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('in_app_capture_screen')), findsOneWidget);
    expect(find.byType(InAppCaptureScreen), findsOneWidget);
    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    expect(find.byType(OccurrenceDraftFormScreen), findsOneWidget);
    expect(find.byType(InAppCaptureScreen), findsNothing);
  });

  testWidgets('add and remove media on draft form updates attached media',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    final form = tester.widget<OccurrenceDraftFormScreen>(
      find.byType(OccurrenceDraftFormScreen),
    );
    final occurrenceId = form.occurrenceId;

    expect(find.byKey(const Key('media_grid')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_media_button')));
    await tester.pumpAndSettle();

    expect(find.byType(InAppCaptureScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    var media = await occurrenceRepo.getMedia(occurrenceId);
    expect(media, hasLength(2));

    final toRemove = media.last;
    await tester.tap(find.byKey(Key('remove_media_${toRemove.id}')));
    await tester.pumpAndSettle();

    media = await occurrenceRepo.getMedia(occurrenceId);
    expect(media, hasLength(1));
    expect(media.single.sortOrder, 0);
  });
}
