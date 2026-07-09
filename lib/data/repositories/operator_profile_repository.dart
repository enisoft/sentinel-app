import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/gateways/auth_gateway.dart';
import '../local/app_database.dart';
import '../remote/api_client.dart';
import '../../domain/models/operator_profile.dart' as domain;
import '../../domain/models/operator_zone.dart';

class OperatorProfileRepository {
  OperatorProfileRepository(this._db, this._api, this._auth);

  final AppDatabase _db;
  final ApiClient _api;
  final AuthGateway _auth;

  Stream<domain.OperatorProfile?> watchCached() {
    return _db.select(_db.cachedOperatorProfiles)
        .watch()
        .map(_pickCachedRowForCurrentUser)
        .map((row) => row == null ? null : _mapRow(row));
  }

  Future<domain.OperatorProfile?> getCached() async {
    final row = await _db
        .select(_db.cachedOperatorProfiles)
        .get()
        .then(_pickCachedRowForCurrentUser);
    if (row == null) return null;
    return _mapRow(row);
  }

  Future<domain.OperatorProfile> fetchAndCache() async {
    final profile = await _api.getMe();
    await _persist(profile);
    return profile;
  }

  /// Cold start: uma tentativa só (sem retry) para falhar rápido se API down.
  Future<domain.OperatorProfile> fetchAndCacheForBootstrap() async {
    final profile = await _api.getMe(useInitialContactRetry: false);
    await _persist(profile);
    return profile;
  }

  Future<void> _persist(domain.OperatorProfile profile) async {
    await _db.into(_db.cachedOperatorProfiles).insertOnConflictUpdate(
          CachedOperatorProfilesCompanion.insert(
            id: profile.id,
            name: profile.name,
            role: profile.role,
            municipalityId: Value(profile.municipalityId),
            photoPath: Value(profile.photoPath),
            zonesJson: Value(jsonEncode(profile.zones.map((z) => z.toJson()).toList())),
            defaultZoneId: Value(profile.defaultZoneId),
            cachedAt: DateTime.now().toUtc(),
          ),
        );
  }

  CachedOperatorProfile? _pickCachedRowForCurrentUser(
    List<CachedOperatorProfile> rows,
  ) {
    final currentUserId = _auth.currentUserId;
    if (currentUserId == null) return null;
    for (final row in rows) {
      if (row.id == currentUserId) return row;
    }
    return null;
  }

  domain.OperatorProfile _mapRow(CachedOperatorProfile row) {
    final zones = (jsonDecode(row.zonesJson) as List<dynamic>)
        .map((item) => OperatorZone.fromJson(item as Map<String, dynamic>))
        .toList();

    return domain.OperatorProfile(
      id: row.id,
      name: row.name,
      role: row.role,
      municipalityId: row.municipalityId,
      photoPath: row.photoPath,
      zones: zones,
      defaultZoneId: row.defaultZoneId,
    );
  }
}
