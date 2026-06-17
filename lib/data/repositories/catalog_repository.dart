import 'package:drift/drift.dart';

import '../local/app_database.dart';

class CatalogItem {
  const CatalogItem({required this.id, required this.name, this.type});

  final String id;
  final String name;
  final String? type;
}

class CatalogRepository {
  CatalogRepository(this._db);

  final AppDatabase _db;

  Stream<List<CatalogItem>> watchCategories() {
    return (_db.select(_db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map((r) => CatalogItem(id: r.id, name: r.name)).toList());
  }

  Future<List<CatalogItem>> getCategories() async {
    final rows = await (_db.select(_db.categories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map((r) => CatalogItem(id: r.id, name: r.name)).toList();
  }

  Stream<List<CatalogItem>> watchObservables() {
    return (_db.select(_db.observables)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map(
          (rows) => rows
              .map((r) => CatalogItem(id: r.id, name: r.name, type: r.type))
              .toList(),
        );
  }

  Future<List<CatalogItem>> getObservables() async {
    final rows = await (_db.select(_db.observables)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows
        .map((r) => CatalogItem(id: r.id, name: r.name, type: r.type))
        .toList();
  }

  Future<void> seedForTesting({
    List<CatalogItem>? categories,
    List<CatalogItem>? observables,
  }) async {
    if (categories != null) {
      for (final item in categories) {
        await _db.into(_db.categories).insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: item.id,
                name: item.name,
                updatedAt: DateTime.now().toUtc(),
              ),
            );
      }
    }
    if (observables != null) {
      for (final item in observables) {
        await _db.into(_db.observables).insertOnConflictUpdate(
              ObservablesCompanion.insert(
                id: item.id,
                type: item.type ?? 'unknown',
                name: item.name,
                updatedAt: DateTime.now().toUtc(),
              ),
            );
      }
    }
  }
}
