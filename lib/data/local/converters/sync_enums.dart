import 'package:drift/drift.dart';

import '../../../core/sync/sync_phase.dart';
import '../../../core/sync/sync_state.dart';

class SyncStateConverter extends TypeConverter<SyncState, String> {
  const SyncStateConverter();

  @override
  SyncState fromSql(String fromDb) => SyncState.fromStorage(fromDb);

  @override
  String toSql(SyncState value) => value.storageValue;
}

class SyncPhaseConverter extends TypeConverter<SyncPhase, String> {
  const SyncPhaseConverter();

  @override
  SyncPhase fromSql(String fromDb) => SyncPhase.fromStorage(fromDb);

  @override
  String toSql(SyncPhase value) => value.storageValue;
}
