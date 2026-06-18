import '../../domain/gateways/sync_gateway.dart';

/// Fake configurável para testes — sem rede.
class FakeSyncGateway implements SyncGateway {
  FakeSyncGateway({
    List<String> confirmedIds = const [],
    Object? syncException,
  })  : _confirmedIds = List<String>.from(confirmedIds),
        _syncException = syncException;

  List<String> _confirmedIds;
  Object? _syncException;

  int syncCallCount = 0;
  List<String> lastSyncIds = const [];

  set confirmedIds(List<String> value) => _confirmedIds = List<String>.from(value);

  set syncException(Object? value) => _syncException = value;

  @override
  Future<void> uploadOccurrenceMedia({required String occurrenceId}) async {}

  @override
  Future<List<String>> syncOccurrences({required List<String> occurrenceIds}) async {
    syncCallCount++;
    lastSyncIds = List<String>.from(occurrenceIds);
    if (_syncException != null) throw _syncException!;
    return _confirmedIds.where(occurrenceIds.contains).toList();
  }

  @override
  Future<List<String>> syncCheckIns({required List<String> checkInIds}) async => [];
}
