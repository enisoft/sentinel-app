import '../../domain/gateways/media_uploader.dart';
import '../../domain/gateways/sync_gateway.dart';

/// Fake configurável para testes — sem rede.
class FakeSyncGateway implements SyncGateway {
  FakeSyncGateway({
    List<String> confirmedIds = const [],
    Object? syncException,
    MediaUploader? mediaUploader,
  })  : _confirmedIds = List<String>.from(confirmedIds),
        _syncException = syncException,
        _mediaUploader = mediaUploader;

  List<String> _confirmedIds;
  Object? _syncException;
  final MediaUploader? _mediaUploader;

  int syncCallCount = 0;
  int uploadCallCount = 0;
  List<String> lastSyncIds = const [];

  set confirmedIds(List<String> value) => _confirmedIds = List<String>.from(value);

  set syncException(Object? value) => _syncException = value;

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
    if (_syncException != null) throw _syncException!;
    return _confirmedIds.where(occurrenceIds.contains).toList();
  }

  @override
  Future<List<String>> syncCheckIns({required List<String> checkInIds}) async => [];
}
