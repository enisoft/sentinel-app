import 'package:drift/drift.dart';

class CachedOperatorProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get municipalityId => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get zonesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get defaultZoneId => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
