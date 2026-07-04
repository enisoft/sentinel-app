import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/app/di.dart';
import 'package:sentinel_app/core/capture/occurrence_lifecycle_status.dart';
import 'package:sentinel_app/data/fakes/fake_camera_source.dart';
import 'package:sentinel_app/data/fakes/fake_hash_service.dart';
import 'package:sentinel_app/data/fakes/fake_location_source.dart';
import 'package:sentinel_app/data/local/app_database.dart';
import 'package:sentinel_app/data/repositories/catalog_repository.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';
import 'package:sentinel_app/data/repositories/operator_profile_repository.dart';
import 'package:sentinel_app/data/repositories/sync_queue_repository.dart';
import 'package:sentinel_app/data/services/capture_occurrence_service.dart';
import 'package:sentinel_app/domain/models/operator_zone.dart';
import 'package:sentinel_app/presentation/capture/occurrence_draft_form_screen.dart';

void main() {
  late AppDatabase db;
  late CaptureOccurrenceService captureService;
  late OccurrenceRepository occurrenceRepo;
  late CatalogRepository catalogRepo;
  late OperatorProfileRepository profileRepo;
  late SyncQueueRepository queueRepo;

  const zoneDefault = OperatorZone(
    id: 'zone-default',
    nome: 'Manaus',
    tipo: 'municipio',
  );

  Future<void> seedProfile() async {
    await db.into(db.cachedOperatorProfiles).insertOnConflictUpdate(
          CachedOperatorProfilesCompanion.insert(
            id: 'user-1',
            name: 'Operador',
            role: 'agente',
            municipalityId: const Value('mun-1'),
            zonesJson: const Value(
              '[{"id":"zone-default","nome":"Manaus","tipo":"municipio"}]',
            ),
            defaultZoneId: const Value('zone-default'),
            cachedAt: DateTime.utc(2026, 7, 4),
          ),
        );
  }

  Future<void> pumpForm(WidgetTester tester, String occurrenceId) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OccurrenceDraftFormScreen(
          occurrenceId: occurrenceId,
          captureService: captureService,
          catalogRepository: catalogRepo,
          operatorProfileRepository: profileRepo,
          occurrenceRepository: occurrenceRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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
    catalogRepo = getIt<CatalogRepository>();
    profileRepo = getIt<OperatorProfileRepository>();
    queueRepo = getIt<SyncQueueRepository>();

    await catalogRepo.seedForTesting(
      categories: const [CatalogItem(id: 'cat-1', name: 'Evento')],
      observables: const [
        CatalogItem(id: 'obs-1', name: 'Político', type: 'person'),
      ],
    );
    await seedProfile();
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  testWidgets('reopening draft repopulates category observable note zone and media',
      (tester) async {
    final draft = await captureService.captureDraft();
    await captureService.updateDraftForm(
      occurrenceId: draft.occurrence.id,
      categoryId: 'cat-1',
      observableId: 'obs-1',
      zonaId: 'zone-default',
      note: 'Nota salva no rascunho',
    );

    await pumpForm(tester, draft.occurrence.id);

    expect(find.text('Evento'), findsOneWidget);
    expect(find.text('Político'), findsOneWidget);
    expect(find.text('Manaus'), findsOneWidget);
    expect(find.text('Nota salva no rascunho'), findsOneWidget);
    expect(find.byKey(const Key('media_grid')), findsOneWidget);
  });

  testWidgets('resume draft confirm enqueues for sync', (tester) async {
    final draft = await captureService.captureDraft();
    await captureService.updateDraftForm(
      occurrenceId: draft.occurrence.id,
      categoryId: 'cat-1',
      observableId: 'obs-1',
      zonaId: 'zone-default',
      note: 'Retomado e confirmado',
    );

    await pumpForm(tester, draft.occurrence.id);
    await tester.tap(find.byKey(const Key('confirm_button')));
    await tester.pumpAndSettle();

    final occurrence = await occurrenceRepo.getById(draft.occurrence.id);
    expect(occurrence!.status, OccurrenceLifecycleStatus.pending);

    final pending = await queueRepo.getPending();
    expect(
      pending.occurrences.map((o) => o.id),
      contains(draft.occurrence.id),
    );
  });
}
