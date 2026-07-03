import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/capture/capture_mime.dart';
import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';
import 'camera_permission_denied_exception.dart';

/// Câmera in-app com plugin oficial — preview via [controller].
class DeviceCameraSource implements CameraSource {
  DeviceCameraSource({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// ~720p — reduz bitrate/tamanho e pressão de memória do encoder em gravações longas.
  static const ResolutionPreset captureResolution = ResolutionPreset.medium;

  final Uuid _uuid;
  CameraController? _controller;
  bool _initializing = false;
  bool _recordingVideo = false;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get isRecordingVideo => _recordingVideo;

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
        captureResolution,
        enableAudio: true,
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

    if (_recordingVideo) {
      throw StateError('Não é possível capturar foto durante gravação de vídeo.');
    }

    final capturedAt = DateTime.now().toUtc();
    final tempFile = await controller.takePicture();
    final destPath = await _stablePhotoCapturePath();

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

  @override
  Future<void> startVideoRecording() async {
    if (!isInitialized) {
      await initialize();
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraPermissionDeniedException();
    }

    if (_recordingVideo) {
      return;
    }

    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      throw CameraPermissionDeniedException(
        'Permissão de microfone necessária para gravar vídeo.',
      );
    }

    await controller.startVideoRecording();
    _recordingVideo = true;
  }

  @override
  Future<CaptureResult> stopVideoRecording({required int durationSeconds}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraPermissionDeniedException();
    }

    if (!_recordingVideo) {
      throw StateError('Nenhuma gravação de vídeo em andamento.');
    }

    final capturedAt = DateTime.now().toUtc();
    final tempFile = await controller.stopVideoRecording();
    _recordingVideo = false;

    final destPath = await _stableVideoCapturePath();
    final temp = File(tempFile.path);
    try {
      await temp.rename(destPath);
    } on FileSystemException {
      await temp.copy(destPath);
      await temp.delete();
    }
    final sizeBytes = await File(destPath).length();

    return CaptureResult(
      localPath: destPath,
      mediaType: 'video',
      mimeType: mimeTypeFromCapturePath(destPath),
      capturedAt: capturedAt,
      sizeBytes: sizeBytes,
      durationSeconds: durationSeconds,
    );
  }

  Future<String> _stablePhotoCapturePath() async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, 'capture_${_uuid.v4()}.jpg');
  }

  Future<String> _stableVideoCapturePath() async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, 'capture_${_uuid.v4()}.mp4');
  }
}
