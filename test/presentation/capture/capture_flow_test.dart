import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/config/app_config.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/data/remote/api_client.dart';
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
import 'package:sentinel_app/presentation/home/home_screen.dart';

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
      apiClient: ApiClient(
        config: AppConfig.fromMap({
          'SUPABASE_URL': 'http://localhost:54321',
          'SUPABASE_ANON_KEY': 'anon',
          'API_BASE_URL': 'http://localhost:8000/api/v1',
        }),
        authGateway: FakeAuthGateway(),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/messages')) {
            return http.Response(
              jsonEncode({'data': []}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      ),
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

  Future<void> captureAndStayOnPreview(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();
  }

  Future<void> finishDraftAndOpenForm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('finish_draft_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('capture stays on preview with cart — form only after Concluir',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);
    expect(find.byKey(const Key('draft_media_cart')), findsNothing);
    expect(find.byKey(const Key('finish_draft_button')), findsNothing);

    await captureAndStayOnPreview(tester);

    expect(find.byType(CaptureHomeScreen), findsOneWidget);
    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);
    expect(find.byKey(const Key('draft_media_cart')), findsOneWidget);
    expect(find.byKey(const Key('draft_media_count')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byKey(const Key('finish_draft_button')), findsOneWidget);
    expect(find.byKey(const Key('pending_sync_badge')), findsNothing);

    final pendingBeforeConfirm = await queueRepo.getPending();
    expect(pendingBeforeConfirm.occurrences, isEmpty);
  });

  Future<void> recordOneVideo(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('capture_button')));
    // startVideoRecording é async: 1º pump processa busy, 2º aplica _recording.
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('recording_timer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('sequential captures stay on preview with correct sort_order',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    // 2 vídeos + 1 foto sem sair do preview
    await tester.tap(find.text('Vídeo'));
    await tester.pumpAndSettle();
    await recordOneVideo(tester);
    await recordOneVideo(tester);

    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();
    await captureAndStayOnPreview(tester);

    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);
    expect(find.byKey(const Key('draft_media_cart')), findsOneWidget);
    expect(find.byKey(const Key('draft_media_count')), findsOneWidget);
    expect(
      tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('draft_media_count')),
        matching: find.byType(Text),
      )).data,
      '3',
    );

    final pending = await queueRepo.getPending();
    expect(pending.occurrences, isEmpty);

    final occurrences = await db.select(db.occurrences).get();
    expect(occurrences, hasLength(1));
    final media = await occurrenceRepo.getMedia(occurrences.single.id);
    expect(media, hasLength(3));
    expect(media.map((m) => m.sortOrder), [0, 1, 2]);
    expect(media[0].mediaType, 'video');
    expect(media[1].mediaType, 'video');
    expect(media[2].mediaType, 'image');
  });

  testWidgets('remove media from cart before finish updates draft', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await captureAndStayOnPreview(tester);
    await captureAndStayOnPreview(tester);
    await captureAndStayOnPreview(tester);

    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('draft_media_cart')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('draft_media_cart_sheet')), findsOneWidget);

    final occurrences = await db.select(db.occurrences).get();
    final mediaBefore = await occurrenceRepo.getMedia(occurrences.single.id);
    expect(mediaBefore, hasLength(3));

    final toRemove = mediaBefore.last;
    await tester.tap(find.byKey(Key('remove_media_${toRemove.id}')));
    await tester.pumpAndSettle();

    final mediaAfter = await occurrenceRepo.getMedia(occurrences.single.id);
    expect(mediaAfter, hasLength(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);
  });

  testWidgets('finish then confirm enqueues all draft media', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await captureAndStayOnPreview(tester);
    await captureAndStayOnPreview(tester);

    await finishDraftAndOpenForm(tester);

    expect(find.byType(OccurrenceDraftFormScreen), findsOneWidget);
    expect(find.byKey(const Key('category_field')), findsOneWidget);

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
    expect(find.byKey(const Key('draft_media_cart')), findsNothing);

    final pending = await queueRepo.getPending();
    expect(pending.occurrences, hasLength(1));

    final occurrence = await occurrenceRepo.getById(pending.occurrences.single.id);
    expect(occurrence!.status, 'pending');
    expect(occurrence.categoryId, 'cat-ui');
    expect(occurrence.observableId, 'obs-ui');
    expect(occurrence.description, 'Nota UI');
    expect(occurrence.syncState, SyncState.localSaved);

    final media = await occurrenceRepo.getMedia(occurrence.id);
    expect(media, hasLength(2));
  });

  testWidgets('confirm from FAB returns to home list with pending badge',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_occurrence_fab')));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureHomeScreen), findsOneWidget);

    await captureAndStayOnPreview(tester);
    await finishDraftAndOpenForm(tester);

    await tester.tap(find.byKey(const Key('category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evento').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('observable_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Político').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('note_field')), 'Via FAB');

    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CaptureHomeScreen), findsNothing);
    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);
    expect(find.text('1 pendente(s)'), findsOneWidget);
    expect(find.byKey(const Key('occurrences_list')), findsOneWidget);
    expect(find.text('Via FAB'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('remove one then finish confirm enqueues remaining media',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await captureAndStayOnPreview(tester);
    await captureAndStayOnPreview(tester);
    await captureAndStayOnPreview(tester);

    await tester.tap(find.byKey(const Key('draft_media_cart')));
    await tester.pumpAndSettle();

    final occurrences = await db.select(db.occurrences).get();
    final mediaBefore = await occurrenceRepo.getMedia(occurrences.single.id);
    final toRemove = mediaBefore.first;
    await tester.tap(find.byKey(Key('remove_media_${toRemove.id}')));
    await tester.pumpAndSettle();

    // Fecha o sheet (lista ainda tem itens).
    Navigator.of(tester.element(find.byKey(const Key('draft_media_cart_sheet'))))
        .pop();
    await tester.pumpAndSettle();

    await finishDraftAndOpenForm(tester);
    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();
    await tester.pump();

    final pending = await queueRepo.getPending();
    expect(pending.occurrences, hasLength(1));
    final media = await occurrenceRepo.getMedia(pending.occurrences.single.id);
    expect(media, hasLength(2));
  });

  testWidgets('confirming form does not trigger automatic sync', (tester) async {
    final countingRunner = installCountingForegroundRunner();

    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await captureAndStayOnPreview(tester);
    await finishDraftAndOpenForm(tester);

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

  testWidgets('sync now button is disabled when queue is empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('sync_now_button')),
    );
    expect(button.onPressed, isNull);
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
      const MaterialApp(home: HomeScreen()),
    );

    await tester.pumpAndSettle();

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
        home: HomeScreen(syncForegroundRunner: countingRunner),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('sync_now_button')),
    );
    expect(button.onPressed, isNotNull);

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

    await captureAndStayOnPreview(tester);
    await finishDraftAndOpenForm(tester);

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

    await captureAndStayOnPreview(tester);
    await finishDraftAndOpenForm(tester);

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

  testWidgets('capture mode toggle shows photo and video options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    expect(find.byKey(const Key('capture_mode_toggle')), findsOneWidget);
    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('Vídeo'), findsOneWidget);
  });

  testWidgets('video recording attaches video media to draft without leaving preview',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureHomeScreen(captureService: captureService),
      ),
    );

    await tester.tap(find.text('Vídeo'));
    await tester.pumpAndSettle();
    await recordOneVideo(tester);

    expect(find.byType(OccurrenceDraftFormScreen), findsNothing);
    expect(
      tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('draft_media_count')),
        matching: find.byType(Text),
      )).data,
      '1',
    );

    final occurrences = await db.select(db.occurrences).get();
    expect(occurrences, hasLength(1));
    final media = await occurrenceRepo.getMedia(occurrences.single.id);
    expect(media, hasLength(1));
    expect(media.single.mediaType, 'video');
    expect(media.single.mimeType, 'video/mp4');
    expect(media.single.durationSeconds, greaterThanOrEqualTo(0));
  });
}

