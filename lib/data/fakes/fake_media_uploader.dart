import '../../domain/gateways/media_uploader.dart';
import '../repositories/occurrence_repository.dart';

/// Fake configurável — simula upload sem rede; espelha retomada via skip de `remote_path`.
class FakeMediaUploader implements MediaUploader {
  FakeMediaUploader({OccurrenceRepository? occurrenceRepository})
      : _occurrenceRepository = occurrenceRepository;

  OccurrenceRepository? _occurrenceRepository;

  set occurrenceRepository(OccurrenceRepository value) =>
      _occurrenceRepository = value;

  int uploadCallCount = 0;
  String? lastOccurrenceId;
  Object? uploadException;
  bool simulateOffsetPreserved = true;

  Future<void> Function(String occurrenceId)? onUpload;

  @override
  Future<void> uploadOccurrenceMedia({required String occurrenceId}) async {
    uploadCallCount++;
    lastOccurrenceId = occurrenceId;

    if (uploadException != null) {
      throw uploadException!;
    }

    if (onUpload != null) {
      await onUpload!(occurrenceId);
      return;
    }

    final repo = _occurrenceRepository;
    if (repo == null) return;

    final media = await repo.getMedia(occurrenceId);
    for (final item in media) {
      if (simulateOffsetPreserved && item.remotePath != null) continue;
      final path = OccurrenceRepository.canonicalStoragePath(
        occurrenceId: occurrenceId,
        mediaId: item.id,
        mimeType: item.mimeType,
      );
      await repo.setRemotePath(item.id, path);
    }
  }
}
