import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/settings/capture_quality_settings.dart';
import 'package:sentinel_app/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CaptureQualitySettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = CaptureQualitySettings();
    await settings.load();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(settings: settings),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows photo and video HD switches off by default', (tester) async {
    await pumpSettings(tester);

    expect(find.byKey(const Key('settings_screen')), findsOneWidget);
    expect(find.text('Foto em HD'), findsOneWidget);
    expect(find.text('Vídeo em HD'), findsOneWidget);
    expect(find.text('720p'), findsNWidgets(2));

    final photoSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings_photo_hd')),
    );
    final videoSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings_video_hd')),
    );
    expect(photoSwitch.value, isFalse);
    expect(videoSwitch.value, isFalse);
  });

  testWidgets('toggling switches persists flags', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings_photo_hd')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_video_hd')));
    await tester.pumpAndSettle();

    expect(settings.photoHd, isTrue);
    expect(settings.videoHd, isTrue);
    expect(find.text('1080p'), findsNWidgets(2));

    final photoSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings_photo_hd')),
    );
    final videoSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings_video_hd')),
    );
    expect(photoSwitch.value, isTrue);
    expect(videoSwitch.value, isTrue);
  });
}
