import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';

/// Câmera em memória para testes unitários — sem I/O; path configurável.
class FakeCameraSource implements CameraSource {
  FakeCameraSource({
    this.nextPath = '/fake/captures/photo.jpg',
    this.nextMediaType = 'image',
    this.nextMimeType = 'image/jpeg',
    this.nextSizeBytes = 1024,
    this.nextDurationSeconds,
    DateTime? nextCapturedAt,
  }) : _nextCapturedAt = nextCapturedAt ?? DateTime.utc(2026, 6, 15, 12, 0);

  String nextPath;
  String nextMediaType;
  String nextMimeType;
  int? nextSizeBytes;
  int? nextDurationSeconds;
  final DateTime _nextCapturedAt;

  int captureCallCount = 0;
  int startVideoRecordingCallCount = 0;
  int stopVideoRecordingCallCount = 0;

  bool _recordingVideo = false;

  @override
  bool get isRecordingVideo => _recordingVideo;

  @override
  Future<CaptureResult> capture() async {
    captureCallCount++;
    final path =
        captureCallCount == 1 ? nextPath : '$nextPath-$captureCallCount';
    return CaptureResult(
      localPath: path,
      mediaType: nextMediaType,
      mimeType: nextMimeType,
      capturedAt: _nextCapturedAt,
      sizeBytes: nextSizeBytes,
      durationSeconds: nextDurationSeconds,
    );
  }

  @override
  Future<void> startVideoRecording() async {
    startVideoRecordingCallCount++;
    _recordingVideo = true;
  }

  @override
  Future<CaptureResult> stopVideoRecording({required int durationSeconds}) async {
    stopVideoRecordingCallCount++;
    _recordingVideo = false;
    final base = nextPath.endsWith('.mp4') ? nextPath : '$nextPath.mp4';
    final path = stopVideoRecordingCallCount == 1
        ? base
        : base.replaceFirst(RegExp(r'\.mp4$'), '-$stopVideoRecordingCallCount.mp4');
    return CaptureResult(
      localPath: path,
      mediaType: 'video',
      mimeType: 'video/mp4',
      capturedAt: _nextCapturedAt,
      sizeBytes: nextSizeBytes ?? 1024 * 1024,
      durationSeconds: durationSeconds,
    );
  }
}
