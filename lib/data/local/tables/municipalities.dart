import 'package:drift/drift.dart';

class Municipalities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
