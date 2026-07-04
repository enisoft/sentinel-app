import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/messages/message_recipient_state.dart';
import '../../core/messages/message_type.dart';
import '../../data/repositories/message_repository.dart';
import '../../domain/models/inbox_message.dart';
import 'message_detail_screen.dart';

/// Intervalo de polling enquanto a aba Mensagens está visível.
const messagesTabPollInterval = Duration(seconds: 60);

/// Lista de mensagens recebidas + refresh periódico.
class MessagesTab extends StatefulWidget {
  const MessagesTab({
    super.key,
    this.messageRepository,
    this.pollingEnabled = true,
  });

  final MessageRepository? messageRepository;
  final bool pollingEnabled;

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  late final MessageRepository _repository;
  Timer? _pollTimer;
  bool _isRefreshing = false;
  String? _errorMessage;
  List<InboxMessage> _items = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.messageRepository ?? getIt<MessageRepository>();
    if (widget.pollingEnabled) {
      _pollTimer = Timer.periodic(messagesTabPollInterval, (_) => _refresh());
    }
    _refresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    try {
      await _repository.refresh();
      final items = await _repository.listAll();
      if (!mounted) return;
      setState(() => _items = items);
    } on Object catch (error) {
      if (!mounted) return;
      final cached = await _repository.listAll();
      setState(() {
        _items = cached;
        _errorMessage = cached.isEmpty ? error.toString() : null;
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _onMessageTap(InboxMessage message) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MessageDetailScreen(
          messageId: message.id,
          messageRepository: _repository,
        ),
      ),
    );
    if (!mounted) return;
    final items = await _repository.listAll();
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              key: const Key('messages_error'),
              _errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              key: Key('messages_refresh_indicator'),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            key: const Key('messages_refresh'),
            onRefresh: _refresh,
            child: _buildList(context, _items),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<InboxMessage> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              key: Key('messages_empty'),
              'Nenhuma mensagem',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('messages_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final message = items[index];
        return _MessageListTile(
          message: message,
          onTap: () => _onMessageTap(message),
        );
      },
    );
  }
}

class _MessageListTile extends StatelessWidget {
  const _MessageListTile({
    required this.message,
    required this.onTap,
  });

  final InboxMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTarefa = MessageType.isTarefa(message.type);
    final isUnread = MessageRecipientState.isUnread(message.estado);

    return ListTile(
      key: Key('message_item_${message.id}'),
      tileColor: isTarefa ? Colors.indigo.shade50 : null,
      leading: CircleAvatar(
        key: Key('message_leading_${message.id}'),
        backgroundColor: isTarefa
            ? Colors.indigo.shade100
            : isUnread
                ? Colors.blue.shade50
                : Colors.grey.shade200,
        child: Icon(
          isTarefa ? Icons.task_alt : Icons.mail_outline,
          color: isTarefa
              ? Colors.indigo.shade700
              : isUnread
                  ? Colors.blue.shade700
                  : Colors.grey.shade700,
          size: 22,
        ),
      ),
      title: Text(
        message.displayTitle,
        style: isUnread ? const TextStyle(fontWeight: FontWeight.w600) : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.author.trim().isNotEmpty)
            Text(message.author.trim()),
          Text(_formatCreatedAt(message.createdAt)),
          const SizedBox(height: 4),
          Container(
            key: Key('message_type_badge_${message.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isTarefa ? Colors.indigo.shade100 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isTarefa
                    ? Colors.indigo.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Text(
              MessageType.listLabel(message.type),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isTarefa
                        ? Colors.indigo.shade900
                        : Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Text(
        key: Key('message_status_${message.id}'),
        MessageRecipientState.listLabel(message.estado),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _statusColor(message.estado, isTarefa),
              fontWeight: FontWeight.w600,
            ),
      ),
      onTap: onTap,
    );
  }

  String _formatCreatedAt(DateTime createdAt) {
    final local = createdAt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Color _statusColor(String estado, bool isTarefa) {
    return switch (estado) {
      MessageRecipientState.enviada => Colors.blue.shade700,
      MessageRecipientState.lida => Colors.grey.shade700,
      MessageRecipientState.aceita => Colors.indigo.shade700,
      MessageRecipientState.concluida => Colors.green.shade700,
      MessageRecipientState.recusada => Colors.redAccent,
      _ => isTarefa ? Colors.indigo.shade700 : Colors.grey.shade700,
    };
  }
}
