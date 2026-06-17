import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../remote/api_client.dart';
import '../../domain/models/operator_profile.dart' as domain;

class OperatorProfileRepository {
  OperatorProfileRepository(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  Stream<domain.OperatorProfile?> watchCached() {
    return _db
        .select(_db.cachedOperatorProfiles)
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapRow(row));
  }

  Future<domain.OperatorProfile?> getCached() async {
    final row =
        await _db.select(_db.cachedOperatorProfiles).getSingleOrNull();
    if (row == null) return null;
    return _mapRow(row);
  }

  Future<domain.OperatorProfile> fetchAndCache() async {
    final profile = await _api.getMe();
    await _db.into(_db.cachedOperatorProfiles).insertOnConflictUpdate(
          CachedOperatorProfilesCompanion.insert(
            id: profile.id,
            name: profile.name,
            role: profile.role,
            municipalityId: Value(profile.municipalityId),
            photoPath: Value(profile.photoPath),
            cachedAt: DateTime.now().toUtc(),
          ),
        );
    return profile;
  }

  domain.OperatorProfile _mapRow(CachedOperatorProfile row) {
    return domain.OperatorProfile(
      id: row.id,
      name: row.name,
      role: row.role,
      municipalityId: row.municipalityId,
      photoPath: row.photoPath,
    );
  }
}
