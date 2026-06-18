import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';

/// Câmera em memória para testes unitários — sem I/O; path configurável.
class FakeCameraSource implements CameraSource {
  FakeCameraSource({
    this.nextPath = '/fake/captures/photo.jpg',
    this.nextMediaType = 'image',
    this.nextMimeType = 'image/jpeg',
    this.nextSizeBytes = 1024,
    DateTime? nextCapturedAt,
  }) : _nextCapturedAt = nextCapturedAt ?? DateTime.utc(2026, 6, 15, 12, 0);

  String nextPath;
  String nextMediaType;
  String nextMimeType;
  int? nextSizeBytes;
  final DateTime _nextCapturedAt;

  int captureCallCount = 0;

  @override
  Future<CaptureResult> capture() async {
    captureCallCount++;
    return CaptureResult(
      localPath: nextPath,
      mediaType: nextMediaType,
      mimeType: nextMimeType,
      capturedAt: _nextCapturedAt,
      sizeBytes: nextSizeBytes,
    );
  }
}
