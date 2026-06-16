import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';
import 'package:sentinel_app/presentation/capture/capture_home_screen.dart';
import 'package:sentinel_app/presentation/capture/occurrence_draft_form_screen.dart';

void main() {
  late AppDatabase db;
  late CaptureOccurrenceService captureService;
  late OccurrenceRepository occurrenceRepo;
  late SyncQueueRepository queueRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await configureDependenciesForTesting(
      db,
      cameraSource: FakeCameraSource(),
      locationSource: FakeLocationSource(),
      hashService: FakeHashService(),
    );
    captureService = getIt<CaptureOccurrenceService>();
    occurrenceRepo = getIt<OccurrenceRepository>();
    queueRepo = getIt<SyncQueueRepository>();
  });

  tearDown(() async {
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

    final pendingBeforeConfirm = await queueRepo.getPending();
    expect(pendingBeforeConfirm.occurrences, hasLength(1));
    expect(pendingBeforeConfirm.occurrences.single.syncState, SyncState.localSaved);
  });

  testWidgets('confirming form enqueues occurrence for sync', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('category_field')), 'cat-ui');
    await tester.enterText(find.byKey(const Key('observable_field')), 'obs-ui');
    await tester.enterText(find.byKey(const Key('note_field')), 'Nota UI');

    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureHomeScreen), findsOneWidget);
    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);

    final pending = await queueRepo.getPending();
    expect(pending.occurrences, hasLength(1));

    final occurrence = await occurrenceRepo.getById(pending.occurrences.single.id);
    expect(occurrence!.status, 'pending');
    expect(occurrence.categoryId, 'cat-ui');
    expect(occurrence.observableId, 'obs-ui');
    expect(occurrence.description, 'Nota UI');
    expect(occurrence.syncState, SyncState.localSaved);
  });
}
