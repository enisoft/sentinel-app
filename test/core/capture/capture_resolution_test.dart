import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/capture/capture_resolution.dart';

void main() {
  test('resolutionPresetForHd maps off to medium and on to high', () {
    expect(resolutionPresetForHd(false), ResolutionPreset.medium);
    expect(resolutionPresetForHd(true), ResolutionPreset.high);
  });
}
