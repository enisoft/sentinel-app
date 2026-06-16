import 'package:drift/drift.dart';

import '../converters/sync_enums.dart';

class CheckIns extends Table {
  TextColumn get id => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get syncState =>
      text().map(const SyncStateConverter()).withDefault(const Constant('local_saved'))();
  TextColumn get failedPhase => text().map(const SyncPhaseConverter()).nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdLocalAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get failedReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
