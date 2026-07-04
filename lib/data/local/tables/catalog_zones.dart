import 'package:drift/drift.dart';

class CatalogZones extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get tipo => text()();
  TextColumn get municipioPaiId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
