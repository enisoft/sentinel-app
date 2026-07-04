import 'package:drift/drift.dart';

class CachedMessages extends Table {
  TextColumn get id => text()();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get type => text()();
  TextColumn get estado => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get actedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
