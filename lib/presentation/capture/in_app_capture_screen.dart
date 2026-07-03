import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../data/device/device_camera_source.dart';
import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';
import 'in_app_camera_preview.dart';
import 'in_app_capture_controls.dart';

/// Tela de captura com preview ao vivo — mesma experiência da home capture-first.
class InAppCaptureScreen extends StatefulWidget {
  const InAppCaptureScreen({
    super.key,
    this.cameraSource,
  });

  final CameraSource? cameraSource;

  @override
  State<InAppCaptureScreen> createState() => _InAppCaptureScreenState();
}

class _InAppCaptureScreenState extends State<InAppCaptureScreen> {
  bool _cameraPermissionDenied = false;
  bool _cameraReady = false;

  CameraSource get _cameraSource =>
      widget.cameraSource ?? getIt<CameraSource>();

  DeviceCameraSource? get _deviceCameraSource {
    final source = _cameraSource;
    return source is DeviceCameraSource ? source : null;
  }

  bool get _canInteract {
    if (_deviceCameraSource != null) {
      return _cameraReady && !_cameraPermissionDenied;
    }
    return true;
  }

  Future<void> _onCaptureComplete(CaptureResult result) async {
    Navigator.of(context).pop<CaptureResult>(result);
  }

  void _onError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('in_app_capture_screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'Capturar mídia',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraLayer(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: InAppCaptureControls(
                cameraSource: _cameraSource,
                canInteract: _canInteract,
                onCaptureComplete: _onCaptureComplete,
                onError: _onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    final deviceSource = _deviceCameraSource;
    if (deviceSource != null) {
      return InAppCameraPreview(
        cameraSource: deviceSource,
        onPermissionDenied: (denied) {
          if (mounted) setState(() => _cameraPermissionDenied = denied);
        },
        onReadyChanged: (ready) {
          if (mounted) setState(() => _cameraReady = ready);
        },
      );
    }

    return const Center(
      child: Icon(Icons.photo_camera_outlined, size: 96, color: Colors.white24),
    );
  }
}
