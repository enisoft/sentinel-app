import '../../core/capture/occurrence_confirm_text.dart';
import '../../core/capture/occurrence_lifecycle_status.dart';
import '../../domain/services/camera_source.dart';
import '../../domain/services/hash_service.dart';
import '../../domain/services/location_source.dart';
import '../local/app_database.dart';
import '../repositories/occurrence_repository.dart';

/// Orquestra o fluxo capture-first: captura → rascunho local → form → fila.
class CaptureOccurrenceService {
  CaptureOccurrenceService({
    required OccurrenceRepository occurrenceRepository,
    required CameraSource cameraSource,
    required LocationSource locationSource,
    required HashService hashService,
  })  : _occurrenceRepository = occurrenceRepository,
        _cameraSource = cameraSource,
        _locationSource = locationSource,
        _hashService = hashService;

  final OccurrenceRepository _occurrenceRepository;
  final CameraSource _cameraSource;
  final LocationSource _locationSource;
  final HashService _hashService;

  /// Disparo: captura mídia + GPS + hash e persiste rascunho em `local_saved`.
  Future<CaptureDraftResult> captureDraft() async {
    final capture = await _cameraSource.capture();
    final position = await _locationSource.getCurrentPosition();
    final contentHash = await _hashService.hashFile(capture.localPath);

    final occurrence = await _occurrenceRepository.createOccurrence(
      title: '',
      description: '',
      status: OccurrenceLifecycleStatus.draft,
      priority: 'medium',
      occurredAt: capture.capturedAt,
      latitude: position.latitude,
      longitude: position.longitude,
      createdAt: capture.capturedAt,
    );

    final media = await _occurrenceRepository.attachMedia(
      occurrenceId: occurrence.id,
      mediaType: capture.mediaType,
      localPath: capture.localPath,
      mimeType: capture.mimeType,
      sizeBytes: capture.sizeBytes,
      durationSeconds: capture.durationSeconds,
      contentHash: contentHash,
    );

    return CaptureDraftResult(
      occurrence: occurrence,
      media: media,
      contentHash: contentHash,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  /// Atualiza campos do form mínimo sem bloquear a captura já feita.
  Future<Occurrence> updateDraftForm({
    required String occurrenceId,
    String? categoryId,
    String? observableId,
    String? note,
  }) {
    return _occurrenceRepository.updateDraft(
      id: occurrenceId,
      categoryId: categoryId,
      observableId: observableId,
      description: note,
    );
  }

  /// Confirma o rascunho — `status = pending`, entra na fila de sync.
  Future<Occurrence> confirmDraft({
    required String occurrenceId,
    String? categoryId,
    String? observableId,
    String? note,
  }) async {
    final primaryMedia =
        await _occurrenceRepository.getPrimaryMedia(occurrenceId);
    final text = resolveOccurrenceConfirmText(
      note: note,
      mediaType: primaryMedia?.mediaType,
    );

    return _occurrenceRepository.updateDraft(
      id: occurrenceId,
      categoryId: categoryId,
      observableId: observableId,
      description: text.description,
      title: text.title,
      status: OccurrenceLifecycleStatus.pending,
    );
  }
}

class CaptureDraftResult {
  const CaptureDraftResult({
    required this.occurrence,
    required this.media,
    required this.contentHash,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final Occurrence occurrence;
  final OccurrenceMediaData media;
  final String contentHash;
  final double latitude;
  final double longitude;
  final double accuracy;
}
