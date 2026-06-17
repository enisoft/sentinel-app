import 'package:drift/drift.dart';

class CatalogSyncCursors extends Table {
  TextColumn get entity => text()();
  TextColumn get lastServerTime => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {entity};
}
