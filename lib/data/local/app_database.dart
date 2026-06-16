import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/sync/sync_phase.dart';
import '../../core/sync/sync_state.dart';
import 'converters/sync_enums.dart';
import 'tables/check_ins.dart';
import 'tables/occurrence_media.dart';
import 'tables/occurrences.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Occurrences, OccurrenceMedia, CheckIns])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

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
        },
      );

  static Future<AppDatabase> openDefault() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sentinel.db'));
    return AppDatabase(NativeDatabase(file));
  }
}
