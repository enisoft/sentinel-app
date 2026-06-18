import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/fakes/fake_device_camera_source.dart';
import 'package:sentinel_app/data/fakes/minimal_jpeg_bytes.dart';

void main() {
  test('writeFakeCaptureJpegTo creates file with valid JPEG bytes', () async {
    final dir = await Directory.systemTemp.createTemp('sentinel_fake_capture_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final path = await writeFakeCaptureJpegTo(dir, sequence: 1);
    final file = File(path);

    expect(file.existsSync(), isTrue);
    expect(await file.length(), kMinimalJpegBytes.length);

    final bytes = await file.readAsBytes();
    expect(bytes, kMinimalJpegBytes);
    expect(bytes.first, 0xFF);
    expect(bytes[1], 0xD8);
    expect(bytes.last, 0xD9);
  });
}
