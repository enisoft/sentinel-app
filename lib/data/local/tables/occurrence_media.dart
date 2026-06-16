import 'package:drift/drift.dart';

import 'occurrences.dart';

class OccurrenceMedia extends Table {
  TextColumn get id => text()();
  TextColumn get occurrenceId =>
      text().references(Occurrences, #id, onDelete: KeyAction.cascade)();
  TextColumn get mediaType => text()();
  TextColumn get localPath => text()();
  TextColumn get remotePath => text().nullable()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get originalName => text().nullable()();
  TextColumn get contentHash => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
