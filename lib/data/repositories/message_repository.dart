import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../core/messages/message_recipient_state.dart';
import '../../domain/models/inbox_message.dart';
import '../local/app_database.dart';
import '../remote/api_client.dart';

class MessageRepository {
  MessageRepository(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  Stream<List<InboxMessage>> watchAll() {
    return (_db.select(_db.cachedMessages)
          ..orderBy([
            (row) => OrderingTerm.desc(row.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  Future<List<InboxMessage>> listAll() async {
    final rows = await (_db.select(_db.cachedMessages)
          ..orderBy([
            (row) => OrderingTerm.desc(row.createdAt),
          ]))
        .get();
    return rows.map(_mapRow).toList();
  }

  Future<InboxMessage?> getById(String id) async {
    final row = await (_db.select(_db.cachedMessages)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  Future<void> refresh() async {
    final items = await _api.getMessages();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.delete(_db.cachedMessages).go();
      for (final message in items) {
        await _db.into(_db.cachedMessages).insert(_toCompanion(message, now));
      }
    });
    await _updateUnreadCount();
  }

  Future<InboxMessage> markRead(String messageId) async {
    final updated = await _api.postMessageRead(messageId);
    await _upsert(updated);
    return updated;
  }

  Future<InboxMessage> accept(String messageId) async {
    final updated = await _api.postMessageAccept(messageId);
    await _upsert(updated);
    return updated;
  }

  Future<InboxMessage> complete(String messageId) async {
    final updated = await _api.postMessageComplete(messageId);
    await _upsert(updated);
    return updated;
  }

  Future<InboxMessage> reject(String messageId) async {
    final updated = await _api.postMessageReject(messageId);
    await _upsert(updated);
    return updated;
  }

  Future<void> _upsert(InboxMessage message) async {
    await _db.into(_db.cachedMessages).insertOnConflictUpdate(
          _toCompanion(message, DateTime.now().toUtc()),
        );
    await _updateUnreadCount();
  }

  Future<void> _updateUnreadCount() async {
    final count = await (_db.select(_db.cachedMessages)
          ..where((row) => row.estado.equals(MessageRecipientState.enviada)))
        .get()
        .then((rows) => rows.length);
    unreadCount.value = count;
  }

  CachedMessagesCompanion _toCompanion(InboxMessage message, DateTime cachedAt) {
    return CachedMessagesCompanion.insert(
      id: message.id,
      author: Value(message.author),
      title: Value(message.title),
      body: Value(message.body),
      type: message.type,
      estado: message.estado,
      createdAt: message.createdAt,
      readAt: Value(message.readAt),
      actedAt: Value(message.actedAt),
      cachedAt: cachedAt,
    );
  }

  InboxMessage _mapRow(CachedMessage row) {
    return InboxMessage(
      id: row.id,
      author: row.author,
      title: row.title,
      body: row.body,
      type: row.type,
      estado: row.estado,
      createdAt: row.createdAt,
      readAt: row.readAt,
      actedAt: row.actedAt,
    );
  }
}
