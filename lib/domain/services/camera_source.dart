import '../models/capture_result.dart';

/// Contrato da câmera in-app — implementação real na fase device.
abstract class CameraSource {
  Future<CaptureResult> capture();
}
