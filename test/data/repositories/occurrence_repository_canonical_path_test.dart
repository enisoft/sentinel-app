import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/repositories/occurrence_repository.dart';

void main() {
  group('extensionFromMimeType', () {
    test('maps video/mp4 to mp4', () {
      expect(
        OccurrenceRepository.extensionFromMimeType('video/mp4'),
        'mp4',
      );
    });
  });

  group('canonicalStoragePath', () {
    test('builds mp4 path for video media', () {
      expect(
        OccurrenceRepository.canonicalStoragePath(
          occurrenceId: 'occ-1',
          mediaId: 'media-1',
          mimeType: 'video/mp4',
        ),
        'occurrences/occ-1/media-1.mp4',
      );
    });
  });
}
