import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/remote/messages_list_response.dart';

void main() {
  group('MessagesListResponse.fromJson', () {
    test('parses data as list', () {
      final response = MessagesListResponse.fromJson({
        'data': [
          {
            'id': 'msg-1',
            'created_at': '2026-07-04T12:00:00Z',
          },
        ],
      });

      expect(response.items, hasLength(1));
      expect(response.items.single.id, 'msg-1');
    });

    test('parses data.items nested envelope', () {
      final response = MessagesListResponse.fromJson({
        'data': {
          'items': [
            {
              'id': 'msg-nested',
              'created_at': '2026-07-03T10:00:00Z',
            },
          ],
        },
      });

      expect(response.items, hasLength(1));
      expect(response.items.single.id, 'msg-nested');
    });

    test('returns empty list when data is missing', () {
      final response = MessagesListResponse.fromJson({});
      expect(response.items, isEmpty);
    });
  });
}
