import '../../domain/models/inbox_message.dart';

class MessagesListResponse {
  const MessagesListResponse({required this.items});

  final List<InboxMessage> items;

  factory MessagesListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawItems = data is List<dynamic>
        ? data
        : (data as Map<String, dynamic>?)?['items'] as List<dynamic>? ?? const [];

    return MessagesListResponse(
      items: rawItems
          .map((item) => InboxMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
