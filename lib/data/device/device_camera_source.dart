import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';
import 'camera_permission_denied_exception.dart';

/// Câmera in-app com plugin oficial — preview via [controller].
class DeviceCameraSource implements CameraSource {
  DeviceCameraSource({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  CameraController? _controller;
  bool _initializing = false;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    if (_controller?.value.isInitialized == true) return;
    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _initializing = true;
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        throw CameraPermissionDeniedException();
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraPermissionDeniedException(
          'Nenhuma câmera disponível neste dispositivo.',
        );
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _controller = controller;
    } finally {
      _initializing = false;
    }
  }

  @override
  Future<CaptureResult> capture() async {
    if (!isInitialized) {
      await initialize();
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraPermissionDeniedException();
    }

    final capturedAt = DateTime.now().toUtc();
    final tempFile = await controller.takePicture();
    final destPath = await _stableCapturePath();

    await File(tempFile.path).copy(destPath);
    final sizeBytes = await File(destPath).length();

    return CaptureResult(
      localPath: destPath,
      mediaType: 'image',
      mimeType: 'image/jpeg',
      capturedAt: capturedAt,
      sizeBytes: sizeBytes,
    );
  }

  Future<String> _stableCapturePath() async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, 'capture_${_uuid.v4()}.jpg');
  }
}
