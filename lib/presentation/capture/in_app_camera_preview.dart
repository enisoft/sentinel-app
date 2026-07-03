import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/device/camera_permission_denied_exception.dart';
import '../../data/device/device_camera_source.dart';

/// Preview da câmera in-app — inicializa permissão e [DeviceCameraSource].
class InAppCameraPreview extends StatefulWidget {
  const InAppCameraPreview({
    super.key,
    required this.cameraSource,
    this.onPermissionDenied,
    this.onReadyChanged,
  });

  final DeviceCameraSource cameraSource;
  final ValueChanged<bool>? onPermissionDenied;
  final ValueChanged<bool>? onReadyChanged;

  @override
  State<InAppCameraPreview> createState() => _InAppCameraPreviewState();
}

class _InAppCameraPreviewState extends State<InAppCameraPreview> {
  bool _permissionDenied = false;
  bool _initializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _initializing = false;
        });
        widget.onPermissionDenied?.call(true);
        widget.onReadyChanged?.call(false);
      }
      return;
    }

    try {
      await widget.cameraSource.initialize();
      if (mounted) {
        setState(() {
          _permissionDenied = false;
          _initializing = false;
        });
        widget.onPermissionDenied?.call(false);
        widget.onReadyChanged?.call(true);
      }
    } on CameraPermissionDeniedException catch (e) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _initializing = false;
          _errorMessage = e.message;
        });
        widget.onPermissionDenied?.call(true);
        widget.onReadyChanged?.call(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _initializing = false;
          _errorMessage = 'Não foi possível iniciar a câmera.';
        });
        widget.onPermissionDenied?.call(true);
        widget.onReadyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                _errorMessage ??
                    'Permissão de câmera necessária para capturar ocorrências.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final controller = widget.cameraSource.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Icon(Icons.photo_camera_outlined, size: 96, color: Colors.white24),
      );
    }

    return CameraPreview(controller);
  }
}
