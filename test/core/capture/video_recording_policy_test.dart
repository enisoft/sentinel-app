import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/capture/video_recording_policy.dart';

void main() {
  group('shouldAutoStopRecording', () {
    test('returns false before limit', () {
      expect(shouldAutoStopRecording(0), isFalse);
      expect(shouldAutoStopRecording(299), isFalse);
    });

    test('returns true at and after limit', () {
      expect(shouldAutoStopRecording(300), isTrue);
      expect(shouldAutoStopRecording(301), isTrue);
    });
  });

  group('formatRecordingElapsed', () {
    test('formats seconds as mm:ss', () {
      expect(formatRecordingElapsed(0), '00:00');
      expect(formatRecordingElapsed(9), '00:09');
      expect(formatRecordingElapsed(59), '00:59');
      expect(formatRecordingElapsed(60), '01:00');
      expect(formatRecordingElapsed(299), '04:59');
      expect(formatRecordingElapsed(300), '05:00');
    });
  });
}
