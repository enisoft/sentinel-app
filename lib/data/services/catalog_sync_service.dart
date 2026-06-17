import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../remote/api_client.dart';
import '../remote/catalog_delta_response.dart';

class CatalogSyncResult {
  const CatalogSyncResult({required this.success, this.error});

  final bool success;
  final String? error;
}

class CatalogSyncService {
  CatalogSyncService(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  static const entities = ['observables', 'categories', 'municipalities'];

  Future<CatalogSyncResult> syncAll() async {
    try {
      await syncObservables();
      await syncCategories();
      await syncMunicipalities();
      return const CatalogSyncResult(success: true);
    } on Exception catch (e) {
      return CatalogSyncResult(success: false, error: e.toString());
    }
  }

  Future<void> syncObservables() => _syncEntity(
        entity: 'observables',
        fetch: _api.getCatalogObservables,
        applyItems: _applyObservables,
      );

  Future<void> syncCategories() => _syncEntity(
        entity: 'categories',
        fetch: _api.getCatalogCategories,
        applyItems: _applyCategories,
      );

  Future<void> syncMunicipalities() => _syncEntity(
        entity: 'municipalities',
        fetch: _api.getCatalogMunicipalities,
        applyItems: _applyMunicipalities,
      );

  Future<void> _syncEntity({
    required String entity,
    required Future<CatalogDeltaResponse> Function({String? updatedSince}) fetch,
    required Future<void> Function(List<Map<String, dynamic>> items) applyItems,
  }) async {
    final cursor = await (_db.select(_db.catalogSyncCursors)
          ..where((t) => t.entity.equals(entity)))
        .getSingleOrNull();

    final updatedSince = cursor?.lastServerTime;
    final response = await fetch(updatedSince: updatedSince);

    await _db.transaction(() async {
      await applyItems(response.items);

      for (final id in response.deletedIds) {
        await _deleteEntity(entity, id);
      }

      await _db.into(_db.catalogSyncCursors).insertOnConflictUpdate(
            CatalogSyncCursorsCompanion.insert(
              entity: entity,
              lastServerTime: Value(response.serverTime),
            ),
          );
    });
  }

  Future<void> _applyObservables(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      await _db.into(_db.observables).insertOnConflictUpdate(
            ObservablesCompanion.insert(
              id: item['id'] as String,
              type: item['type'] as String,
              name: item['name'] as String,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    }
  }

  Future<void> _applyCategories(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      await _db.into(_db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: item['id'] as String,
              name: item['name'] as String,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    }
  }

  Future<void> _applyMunicipalities(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      await _db.into(_db.municipalities).insertOnConflictUpdate(
            MunicipalitiesCompanion.insert(
              id: item['id'] as String,
              name: item['name'] as String,
              latitude: Value((item['latitude'] as num?)?.toDouble()),
              longitude: Value((item['longitude'] as num?)?.toDouble()),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    }
  }

  Future<void> _deleteEntity(String entity, String id) async {
    switch (entity) {
      case 'observables':
        await (_db.delete(_db.observables)..where((t) => t.id.equals(id))).go();
      case 'categories':
        await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
      case 'municipalities':
        await (_db.delete(_db.municipalities)..where((t) => t.id.equals(id)))
            .go();
    }
  }
}
