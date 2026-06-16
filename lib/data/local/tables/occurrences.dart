import 'package:drift/drift.dart';

import '../converters/sync_enums.dart';

class Occurrences extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get status => text()();
  TextColumn get priority => text()();
  TextColumn get location => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get observableId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get syncState =>
      text().map(const SyncStateConverter()).withDefault(const Constant('local_saved'))();
  TextColumn get failedPhase => text().map(const SyncPhaseConverter()).nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdLocalAt => dateTime()();
  DateTimeColumn get mediaUploadedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get failedReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
