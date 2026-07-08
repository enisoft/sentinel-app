import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/capture/video_recording_policy.dart';
import '../../data/device/camera_permission_denied_exception.dart';
import '../../data/device/device_camera_source.dart';
import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';

enum CaptureMode { photo, video }
enum CaptureFeedbackEvent { photo, videoStart, videoStop }

/// Controles compartilhados de captura foto/vídeo com preview ao vivo.
class InAppCaptureControls extends StatefulWidget {
  const InAppCaptureControls({
    super.key,
    required this.cameraSource,
    required this.onCaptureComplete,
    required this.canInteract,
    this.onError,
    this.onCaptureFeedback,
  });

  final CameraSource cameraSource;
  /// Chamado após foto ou fim de vídeo; pode ser assíncrono (ex.: anexar ao rascunho).
  final Future<void> Function(CaptureResult capture) onCaptureComplete;
  final bool canInteract;
  final ValueChanged<String>? onError;
  final ValueChanged<CaptureFeedbackEvent>? onCaptureFeedback;

  @override
  State<InAppCaptureControls> createState() => _InAppCaptureControlsState();
}

class _InAppCaptureControlsState extends State<InAppCaptureControls> {
  CaptureMode _mode = CaptureMode.photo;
  bool _busy = false;
  bool _recording = false;
  int _elapsedSeconds = 0;
  Timer? _recordingTimer;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _releaseRecordingWakelock();
    super.dispose();
  }

  Future<void> _acquireRecordingWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Best-effort — não bloqueia gravação se indisponível.
    }
  }

  Future<void> _releaseRecordingWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Best-effort.
    }
  }

  bool get _canPress =>
      widget.canInteract && !_busy && (!_recording || _mode == CaptureMode.video);

  Future<void> _onShutterPressed() async {
    if (!_canPress) return;

    if (_mode == CaptureMode.photo) {
      widget.onCaptureFeedback?.call(CaptureFeedbackEvent.photo);
      await _capturePhoto();
    } else if (_recording) {
      widget.onCaptureFeedback?.call(CaptureFeedbackEvent.videoStop);
      await _stopVideoRecording();
    } else {
      widget.onCaptureFeedback?.call(CaptureFeedbackEvent.videoStart);
      await _startVideoRecording();
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _busy = true);
    try {
      final result = await widget.cameraSource.capture();
      if (!mounted) return;
      await widget.onCaptureComplete(result);
    } on CameraPermissionDeniedException catch (error) {
      widget.onError?.call(error.message);
    } catch (error) {
      widget.onError?.call('Falha na captura: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startVideoRecording() async {
    setState(() => _busy = true);
    try {
      await widget.cameraSource.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsedSeconds = 0;
        _busy = false;
      });
      unawaited(_acquireRecordingWakelock());
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final next = _elapsedSeconds + 1;
        if (shouldAutoStopRecording(next)) {
          _stopVideoRecording(elapsedOverride: next);
          return;
        }
        setState(() => _elapsedSeconds = next);
      });
    } on CameraPermissionDeniedException catch (error) {
      await _releaseRecordingWakelock();
      widget.onError?.call(error.message);
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      await _releaseRecordingWakelock();
      widget.onError?.call('Falha ao iniciar gravação: $error');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopVideoRecording({int? elapsedOverride}) async {
    if (!_recording && elapsedOverride == null) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;
    final elapsed = elapsedOverride ?? _elapsedSeconds;

    setState(() {
      _busy = true;
      _recording = false;
    });

    try {
      final result = await widget.cameraSource.stopVideoRecording(
        durationSeconds: elapsed,
      );
      if (!mounted) return;
      await widget.onCaptureComplete(result);
    } on CameraPermissionDeniedException catch (error) {
      widget.onError?.call(error.message);
    } catch (error) {
      widget.onError?.call('Falha ao parar gravação: $error');
    } finally {
      // Fire-and-forget: await no disable() pode não completar em testes e
      // deixaria _busy=true para sempre (shutter morto após o 1º vídeo).
      unawaited(_releaseRecordingWakelock());
      if (mounted) {
        setState(() {
          _busy = false;
          _elapsedSeconds = 0;
        });
      } else {
        _busy = false;
        _elapsedSeconds = 0;
      }
    }
  }

  Future<void> _onModeChanged(Set<CaptureMode> modes) async {
    final mode = modes.firstOrNull;
    if (mode == null || mode == _mode || _recording || _busy) return;
    setState(() => _mode = mode);

    final source = widget.cameraSource;
    if (source is! DeviceCameraSource) return;

    try {
      if (mode == CaptureMode.photo) {
        await source.prepareForPhoto();
      } else {
        await source.prepareForVideo();
      }
    } on CameraPermissionDeniedException catch (error) {
      widget.onError?.call(error.message);
    } catch (error) {
      widget.onError?.call('Falha ao ajustar qualidade da câmera: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = _mode == CaptureMode.photo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_recording)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  key: const Key('recording_timer'),
                  formatRecordingElapsed(_elapsedSeconds),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
        SegmentedButton<CaptureMode>(
          key: const Key('capture_mode_toggle'),
          segments: const [
            ButtonSegment(
              value: CaptureMode.photo,
              icon: Icon(Icons.photo_camera_outlined),
              label: Text('Foto'),
            ),
            ButtonSegment(
              value: CaptureMode.video,
              icon: Icon(Icons.videocam_outlined),
              label: Text('Vídeo'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: _recording || _busy ? null : _onModeChanged,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.black87;
              }
              return Colors.white70;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white24;
            }),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          key: const Key('capture_hint'),
          isPhoto
              ? 'Toque para capturar'
              : (_recording ? 'Toque para parar' : 'Toque para gravar'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: isPhoto ? 'Capturar mídia' : 'Gravar vídeo',
          button: true,
          child: GestureDetector(
            key: const Key('capture_button'),
            // Avalia _canPress no toque — evita onTap=null “preso” se o rebuild
            // com _busy=false for perdido após attach ao rascunho.
            onTap: _onShutterPressed,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: _recording
                    ? Colors.red
                    : (_canPress ? Colors.white : Colors.white38),
              ),
              child: _recording
                  ? const Center(
                      child: Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
