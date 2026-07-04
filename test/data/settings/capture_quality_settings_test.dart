import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/settings/capture_quality_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to photo and video HD off', () async {
    final settings = CaptureQualitySettings();
    await settings.load();

    expect(settings.photoHd, isFalse);
    expect(settings.videoHd, isFalse);
  });

  test('persists photo and video HD flags', () async {
    final settings = CaptureQualitySettings();
    await settings.load();

    await settings.setPhotoHd(true);
    await settings.setVideoHd(true);

    expect(settings.photoHd, isTrue);
    expect(settings.videoHd, isTrue);

    final reloaded = CaptureQualitySettings();
    await reloaded.load();
    expect(reloaded.photoHd, isTrue);
    expect(reloaded.videoHd, isTrue);
  });

  test('loads existing preferences', () async {
    SharedPreferences.setMockInitialValues({
      CaptureQualitySettings.photoHdKey: true,
      CaptureQualitySettings.videoHdKey: false,
    });

    final settings = CaptureQualitySettings();
    await settings.load();

    expect(settings.photoHd, isTrue);
    expect(settings.videoHd, isFalse);
  });
}
