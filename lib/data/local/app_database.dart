import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/sync/sync_phase.dart';
import '../../core/sync/sync_state.dart';
import 'converters/sync_enums.dart';
import 'tables/cached_operator_profiles.dart';
import 'tables/catalog_sync_cursors.dart';
import 'tables/categories.dart';
import 'tables/check_ins.dart';
import 'tables/municipalities.dart';
import 'tables/observables.dart';
import 'tables/occurrence_media.dart';
import 'tables/occurrences.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Occurrences,
  OccurrenceMedia,
  CheckIns,
  CachedOperatorProfiles,
  Categories,
  Observables,
  Municipalities,
  CatalogSyncCursors,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.deleteTable('occurrence_media');
            await m.deleteTable('check_ins');
            await m.deleteTable('occurrences');
            await m.createAll();
          }
          if (from < 3) {
            await m.addColumn(occurrenceMedia, occurrenceMedia.contentHash);
          }
          if (from < 4) {
            await m.createTable(cachedOperatorProfiles);
            await m.createTable(categories);
            await m.createTable(observables);
            await m.createTable(municipalities);
            await m.createTable(catalogSyncCursors);
          }
        },
      );

  static Future<AppDatabase> openDefault() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sentinel.db'));
    return AppDatabase(NativeDatabase(file));
  }
}
