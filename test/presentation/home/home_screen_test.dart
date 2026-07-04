import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/capture/occurrence_lifecycle_status.dart';
import 'package:sentinel_app/core/sync/sync_state.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/fakes/fake_media_uploader.dart';
import 'package:sentinel_app/data/fakes/fake_sync_gateway.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/presentation/capture/capture_home_screen.dart';
import 'package:sentinel_app/presentation/home/home_screen.dart';
import 'package:sentinel_app/presentation/home/occurrences_tab.dart';
import 'package:sentinel_app/presentation/settings/settings_screen.dart';

void main() {
  late AppDatabase db;
  late OccurrenceRepository occurrenceRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await configureDependenciesForTesting(
      db,
      cameraSource: FakeCameraSource(),
      locationSource: FakeLocationSource(),
      hashService: FakeHashService(),
      syncGateway: FakeSyncGateway(mediaUploader: FakeMediaUploader()),
    );
    occurrenceRepo = getIt<OccurrenceRepository>();
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on occurrences tab with FAB and empty list', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('home_screen')), findsOneWidget);
    expect(find.byKey(const Key('add_occurrence_fab')), findsOneWidget);
    expect(find.text('Adicionar ocorrência'), findsOneWidget);
    expect(find.byKey(const Key('occurrences_empty')), findsOneWidget);
    expect(find.byKey(const Key('tasks_placeholder')), findsNothing);
    expect(find.byKey(const Key('sync_now_button')), findsOneWidget);
    expect(find.byKey(const Key('pending_sync_badge')), findsNothing);
    expect(
      tester.widget<Badge>(find.byKey(const Key('occurrences_tab_badge'))).isLabelVisible,
      isFalse,
    );
  });

  testWidgets('tasks tab shows placeholder without API calls', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tasks_placeholder')), findsOneWidget);
    expect(find.text('Em breve'), findsOneWidget);
    expect(find.byKey(const Key('occurrences_empty')), findsNothing);
  });

  testWidgets('FAB opens capture flow', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('add_occurrence_fab')));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureHomeScreen), findsOneWidget);
    expect(find.byKey(const Key('capture_button')), findsOneWidget);
  });

  testWidgets('settings button opens settings screen', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byKey(const Key('settings_photo_hd')), findsOneWidget);
    expect(find.byKey(const Key('settings_video_hd')), findsOneWidget);
  });

  testWidgets('list shows draft as não confirmada and pending as pendente',
      (tester) async {
    await occurrenceRepo.createOccurrence(
      id: 'draft-1',
      title: '',
      description: 'Rascunho local',
      status: OccurrenceLifecycleStatus.draft,
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 1, 10),
    );
    await occurrenceRepo.createOccurrence(
      id: 'pending-1',
      title: 'Confirmada',
      description: 'Na fila',
      status: OccurrenceLifecycleStatus.pending,
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 2, 11),
    );
    await occurrenceRepo.createOccurrence(
      id: 'synced-1',
      title: 'Enviada',
      description: 'Ok',
      status: OccurrenceLifecycleStatus.pending,
      priority: 'medium',
      occurredAt: DateTime.utc(2026, 1, 3, 12),
    );
    await occurrenceRepo.markMediaDone('synced-1');
    await occurrenceRepo.beginJsonSync('synced-1');
    await occurrenceRepo.markSynced('synced-1');

    await pumpHome(tester);

    expect(find.byKey(const Key('occurrences_list')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_item_draft-1')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_item_pending-1')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_item_synced-1')), findsOneWidget);

    expect(find.byKey(const Key('occurrence_id_badge_draft-1')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_id_badge_pending-1')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_id_badge_synced-1')), findsOneWidget);
    expect(find.text('draft-'), findsOneWidget);
    expect(find.text('pendin'), findsOneWidget);
    expect(find.text('synced'), findsOneWidget);

    expect(find.text('Rascunho local'), findsOneWidget);
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);

    expect(
      tester.widget<Text>(find.byKey(const Key('occurrence_status_draft-1'))).data,
      'Não confirmada',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('occurrence_status_pending-1'))).data,
      'Pendente',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('occurrence_status_synced-1'))).data,
      'Sincronizada',
    );

    // Rascunho aparece na lista, mas não entra no badge de pendentes (ENI-44).
    expect(find.byKey(const Key('pending_sync_badge')), findsOneWidget);
    expect(find.text('1 pendente(s)'), findsOneWidget);

    final tabBadge = tester.widget<Badge>(
      find.byKey(const Key('occurrences_tab_badge')),
    );
    expect(tabBadge.isLabelVisible, isTrue);
    expect(
      tester.widget<Text>(find.byKey(const Key('occurrences_tab_badge_count'))).data,
      '1',
    );

    // Badge do menu permanece visível na aba Tasks.
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Badge>(find.byKey(const Key('occurrences_tab_badge'))).isLabelVisible,
      isTrue,
    );
  });

  test('occurrenceShortId keeps first six characters', () {
    expect(occurrenceShortId('a1b2c3d4-e5f6-7890'), 'a1b2c3');
    expect(occurrenceShortId('abc'), 'abc');
    expect(occurrenceShortId('draft-1'), 'draft-');
  });

  test('occurrenceListStatusLabel maps lifecycle and sync states', () {
    Occurrence build({
      required String status,
      required SyncState syncState,
    }) {
      return Occurrence(
        id: 'x',
        title: 't',
        description: 'd',
        status: status,
        priority: 'medium',
        occurredAt: DateTime.utc(2026, 1, 1),
        createdAt: DateTime.utc(2026, 1, 1),
        syncState: syncState,
        retryCount: 0,
        createdLocalAt: DateTime.utc(2026, 1, 1),
      );
    }

    expect(
      occurrenceListStatusLabel(
        build(status: OccurrenceLifecycleStatus.draft, syncState: SyncState.localSaved),
      ),
      'Não confirmada',
    );
    expect(
      occurrenceListStatusLabel(
        build(status: OccurrenceLifecycleStatus.pending, syncState: SyncState.localSaved),
      ),
      'Pendente',
    );
    expect(
      occurrenceListStatusLabel(
        build(status: OccurrenceLifecycleStatus.pending, syncState: SyncState.synced),
      ),
      'Sincronizada',
    );
    expect(
      occurrenceListStatusLabel(
        build(status: OccurrenceLifecycleStatus.pending, syncState: SyncState.failed),
      ),
      'Falha',
    );
  });
}
