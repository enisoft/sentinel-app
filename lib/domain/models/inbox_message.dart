import '../../core/messages/message_recipient_state.dart';
import '../../core/messages/message_type.dart';

class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.author,
    required this.title,
    required this.body,
    required this.type,
    required this.estado,
    required this.createdAt,
    this.readAt,
    this.actedAt,
  });

  final String id;
  final String author;
  final String title;
  final String body;
  final String type;
  final String estado;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? actedAt;

  bool get isTarefa => MessageType.isTarefa(type);
  bool get isUnread => MessageRecipientState.isUnread(estado);

  /// Título para lista/detalhe: titulo → 1ª linha do corpo → rótulo do tipo.
  String get displayTitle {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;

    final trimmedBody = body.trim();
    if (trimmedBody.isNotEmpty) {
      final firstLine = trimmedBody.split(RegExp(r'\r?\n')).first.trim();
      if (firstLine.length > 72) {
        return '${firstLine.substring(0, 69)}...';
      }
      return firstLine;
    }

    return MessageType.listLabel(type);
  }

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    final flat = _flattenMessageJson(json);

    final id = _readString(flat['message_id']) ??
        _readString(flat['messageId']) ??
        _messageIdFromNested(json) ??
        _readString(flat['id']) ??
        '';

    final createdAtRaw = flat['created_at'] ?? flat['createdAt'];
    if (createdAtRaw == null) {
      throw FormatException('created_at ausente em mensagem $id');
    }

    return InboxMessage(
      id: id,
      author: _readAuthor(flat),
      title: _readString(flat['titulo']) ?? _readString(flat['title']) ?? '',
      body: _readString(flat['corpo']) ?? _readString(flat['body']) ?? '',
      type: MessageType.normalize(
        _readString(flat['tipo']) ?? _readString(flat['type']),
      ),
      estado: MessageRecipientState.normalize(
        _readString(flat['estado']) ??
            _readString(flat['state']) ??
            _readString(flat['status']),
      ),
      createdAt: DateTime.parse(createdAtRaw as String).toUtc(),
      readAt: _parseOptionalDate(flat['read_at'] ?? flat['readAt']),
      actedAt: _parseOptionalDate(flat['acted_at'] ?? flat['actedAt']),
    );
  }

  static Map<String, dynamic> _flattenMessageJson(Map<String, dynamic> json) {
    final nested = json['message'];
    if (nested is Map<String, dynamic>) {
      return {...nested, ...json};
    }
    return json;
  }

  static String? _messageIdFromNested(Map<String, dynamic> json) {
    final nested = json['message'];
    if (nested is Map<String, dynamic>) {
      return _readString(nested['id']);
    }
    return null;
  }

  static String _readAuthor(Map<String, dynamic> json) {
    final autor = json['autor'] ?? json['author'];
    if (autor is String) return autor.trim();
    if (autor is Map<String, dynamic>) {
      return (_readString(autor['name']) ??
              _readString(autor['nome']) ??
              _readString(autor['label']) ??
              '')
          .trim();
    }
    return '';
  }

  static String? _readString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  InboxMessage copyWith({
    String? estado,
    DateTime? readAt,
    DateTime? actedAt,
  }) {
    return InboxMessage(
      id: id,
      author: author,
      title: title,
      body: body,
      type: type,
      estado: estado ?? this.estado,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      actedAt: actedAt ?? this.actedAt,
    );
  }
}
