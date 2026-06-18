import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'sentinel-device.db';
  final db = sqlite3.open(path);

  void q(String title, String sql) {
    print('\n--- $title ---');
    final result = db.select(sql);
    if (result.isEmpty) {
      print('(vazio)');
      return;
    }
    print(result.columnNames.join(' | '));
    for (final row in result) {
      print(row.values.join(' | '));
    }
  }

  q('pending não synced (todos)', '''
    SELECT sync_state, COUNT(*) AS n FROM occurrences
    WHERE status='pending' AND sync_state != 'synced'
    GROUP BY sync_state
  ''');

  q('sync_state x status', '''
    SELECT sync_state, status, COUNT(*) AS n FROM occurrences
    GROUP BY sync_state, status ORDER BY n DESC
  ''');

  q('FILA UI (occ elegíveis)', '''
    SELECT id, status, sync_state, failed_phase, failed_reason
    FROM occurrences
    WHERE status='pending' AND sync_state != 'synced'
      AND NOT (sync_state='failed' AND failed_reason LIKE 'validation:%')
  ''');

  q('check_ins pendentes', '''
    SELECT id, sync_state, failed_phase, failed_reason FROM check_ins
    WHERE sync_state != 'synced'
  ''');

  q('drafts', '''
    SELECT id, sync_state, failed_reason FROM occurrences WHERE status='draft'
  ''');

  q('validation mortos', '''
    SELECT id, status, sync_state, failed_reason FROM occurrences
    WHERE failed_reason LIKE 'validation:%'
  ''');

  q('últimas 5 ocorrências', '''
    SELECT id, status, sync_state, synced_at FROM occurrences
    ORDER BY created_local_at DESC LIMIT 5
  ''');

  q('detalhe última captura', '''
    SELECT o.id, o.title, o.description, o.category_id, o.observable_id,
           o.sync_state, o.failed_phase, o.failed_reason
    FROM occurrences o
    ORDER BY o.created_local_at DESC LIMIT 1
  ''');

  final latest = db.select('''
    SELECT id FROM occurrences ORDER BY created_local_at DESC LIMIT 1
  ''');
  if (latest.isNotEmpty) {
    final id = latest.first['id'];
    q('mídia última occ', '''
      SELECT id, remote_path, local_path FROM occurrence_media
      WHERE occurrence_id = '$id'
    ''');
  }

  db.dispose();
}
