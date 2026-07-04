import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/capture/capture_mime.dart';
import '../../core/capture/capture_resolution.dart';
import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';
import '../settings/capture_quality_settings.dart';
import 'camera_permission_denied_exception.dart';

/// Câmera in-app com plugin oficial — preview via [controller].
///
/// Notifica listeners quando o [CameraController] é recriado (troca de preset HD).
class DeviceCameraSource extends ChangeNotifier implements CameraSource {
  DeviceCameraSource({
    required CaptureQualitySettings settings,
    Uuid? uuid,
  })  : _settings = settings,
        _uuid = uuid ?? const Uuid();

  final CaptureQualitySettings _settings;
  final Uuid _uuid;
  CameraController? _controller;
  ResolutionPreset? _activePreset;
  bool _initializing = false;
  bool _recordingVideo = false;
  double? _lastZoom;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get isRecordingVideo => _recordingVideo;

  /// Aplica o preset de foto (flag [CaptureQualitySettings.photoHd]).
  Future<void> prepareForPhoto() async {
    await _ensureResolution(resolutionPresetForHd(_settings.photoHd));
  }

  /// Aplica o preset de vídeo (flag [CaptureQualitySettings.videoHd]).
  Future<void> prepareForVideo() async {
    await _ensureResolution(resolutionPresetForHd(_settings.videoHd));
  }

  /// Zoom mínimo do sensor ativo (ex.: 0.5 com ultrawide).
  Future<double> getMinZoomLevel() async {
    final controller = _requireInitializedController();
    return controller.getMinZoomLevel();
  }

  /// Zoom máximo do sensor ativo (digital; G86 sem tele dedicada).
  Future<double> getMaxZoomLevel() async {
    final controller = _requireInitializedController();
    return controller.getMaxZoomLevel();
  }

  /// Aplica zoom instantâneo (níveis discretos — ENI-58).
  Future<void> setZoomLevel(double zoom) async {
    final controller = _requireInitializedController();
    final minZoom = await controller.getMinZoomLevel();
    final maxZoom = await controller.getMaxZoomLevel();
    final clamped = zoom.clamp(minZoom, maxZoom);
    await controller.setZoomLevel(clamped);
    _lastZoom = clamped;
  }

  CameraController _requireInitializedController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraPermissionDeniedException();
    }
    return controller;
  }

  /// Abre a câmera no preset de foto (modo inicial da UI).
  Future<void> initialize() async {
    await prepareForPhoto();
  }

  Future<void> _ensureResolution(ResolutionPreset preset) async {
    if (_controller?.value.isInitialized == true && _activePreset == preset) {
      return;
    }

    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (_controller?.value.isInitialized == true && _activePreset == preset) {
        return;
      }
    }

    if (_recordingVideo) {
      throw StateError(
        'Não é possível alterar a resolução durante gravação de vídeo.',
      );
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

      final previousZoom = _lastZoom;
      final oldController = _controller;
      _controller = null;
      _activePreset = null;
      if (oldController != null) {
        await oldController.dispose();
      }

      final controller = CameraController(
        back,
        preset,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _controller = controller;
      _activePreset = preset;

      if (previousZoom != null) {
        try {
          final minZoom = await controller.getMinZoomLevel();
          final maxZoom = await controller.getMaxZoomLevel();
          final clamped = previousZoom.clamp(minZoom, maxZoom);
          await controller.setZoomLevel(clamped);
          _lastZoom = clamped;
        } catch (_) {
          // Best-effort — zoom volta ao padrão do sensor.
        }
      }

      notifyListeners();
    } finally {
      _initializing = false;
    }
  }

  @override
  Future<CaptureResult> capture() async {
    await prepareForPhoto();

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
    await prepareForVideo();

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
