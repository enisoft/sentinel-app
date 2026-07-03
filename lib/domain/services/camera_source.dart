import '../models/capture_result.dart';

/// Contrato da câmera in-app — implementação real na fase device.
abstract class CameraSource {
  Future<CaptureResult> capture();

  Future<void> startVideoRecording();

  Future<CaptureResult> stopVideoRecording({required int durationSeconds});

  bool get isRecordingVideo => false;
}
