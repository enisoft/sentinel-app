import '../../domain/gateways/media_uploader.dart';
import '../../domain/gateways/sync_gateway.dart';

/// Fake configurável para testes — sem rede.
class FakeSyncGateway implements SyncGateway {
  FakeSyncGateway({
    List<String> confirmedIds = const [],
    List<String> confirmedCheckInIds = const [],
    Object? syncException,
    Object? checkInSyncException,
    MediaUploader? mediaUploader,
  })  : _confirmedIds = List<String>.from(confirmedIds),
        _confirmedCheckInIds = List<String>.from(confirmedCheckInIds),
        _syncException = syncException,
        _checkInSyncException = checkInSyncException,
        _mediaUploader = mediaUploader;

  List<String> _confirmedIds;
  List<String> _confirmedCheckInIds;
  Object? _syncException;
  Object? _checkInSyncException;
  final MediaUploader? _mediaUploader;
  Future<void> Function()? onBeforeSync;

  int syncCallCount = 0;
  int checkInSyncCallCount = 0;
  int uploadCallCount = 0;
  List<String> lastSyncIds = const [];
  List<String> lastCheckInSyncIds = const [];

  set confirmedIds(List<String> value) => _confirmedIds = List<String>.from(value);

  set confirmedCheckInIds(List<String> value) =>
      _confirmedCheckInIds = List<String>.from(value);

  set syncException(Object? value) => _syncException = value;

  set checkInSyncException(Object? value) => _checkInSyncException = value;

  @override
  Future<void> uploadOccurrenceMedia({required String occurrenceId}) async {
    uploadCallCount++;
    if (_mediaUploader != null) {
      await _mediaUploader!.uploadOccurrenceMedia(occurrenceId: occurrenceId);
    }
  }

  @override
  Future<List<String>> syncOccurrences({required List<String> occurrenceIds}) async {
    syncCallCount++;
    lastSyncIds = List<String>.from(occurrenceIds);
    if (onBeforeSync != null) {
      await onBeforeSync!();
    }
    if (_syncException != null) throw _syncException!;
    return _confirmedIds.where(occurrenceIds.contains).toList();
  }

  @override
  Future<List<String>> syncCheckIns({required List<String> checkInIds}) async {
    checkInSyncCallCount++;
    lastCheckInSyncIds = List<String>.from(checkInIds);
    if (_checkInSyncException != null) throw _checkInSyncException!;
    return _confirmedCheckInIds.where(checkInIds.contains).toList();
  }
}
