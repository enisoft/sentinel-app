import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/capture_result.dart';
import '../../domain/services/camera_source.dart';
import 'minimal_jpeg_bytes.dart';

/// Câmera fake para device sem câmera real — grava JPEG válido em disco para TUS.
class FakeDeviceCameraSource implements CameraSource {
  int captureCallCount = 0;
  bool _recordingVideo = false;

  @override
  bool get isRecordingVideo => _recordingVideo;

  @override
  Future<CaptureResult> capture() async {
    captureCallCount++;
    final path = await writeFakeCaptureJpeg(sequence: captureCallCount);
    final sizeBytes = await File(path).length();
    return CaptureResult(
      localPath: path,
      mediaType: 'image',
      mimeType: 'image/jpeg',
      capturedAt: DateTime.now().toUtc(),
      sizeBytes: sizeBytes,
    );
  }

  @override
  Future<void> startVideoRecording() async {
    _recordingVideo = true;
  }

  @override
  Future<CaptureResult> stopVideoRecording({required int durationSeconds}) async {
    _recordingVideo = false;
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, 'fake_capture_video.mp4'),
    );
    await file.writeAsBytes(kMinimalJpegBytes, flush: true);
    final sizeBytes = await file.length();
    return CaptureResult(
      localPath: file.path,
      mediaType: 'video',
      mimeType: 'video/mp4',
      capturedAt: DateTime.now().toUtc(),
      sizeBytes: sizeBytes,
      durationSeconds: durationSeconds,
    );
  }
}

/// Grava JPEG mínimo em [getTemporaryDirectory] e retorna o path absoluto.
Future<String> writeFakeCaptureJpeg({required int sequence}) async {
  final dir = await getTemporaryDirectory();
  return writeFakeCaptureJpegTo(dir, sequence: sequence);
}

/// Grava JPEG mínimo em [directory] — exposto para teste sem path_provider.
Future<String> writeFakeCaptureJpegTo(
  Directory directory, {
  required int sequence,
}) async {
  final file = File(
    p.join(directory.path, 'fake_capture_$sequence.jpg'),
  );
  await file.writeAsBytes(kMinimalJpegBytes, flush: true);
  return file.path;
}
