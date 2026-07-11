import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../core/messages/message_recipient_state.dart';
import '../../core/messages/message_type.dart';
import '../../data/repositories/message_repository.dart';
import '../../domain/models/inbox_message.dart';
import '../shared/status_chip.dart';
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
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          const Center(
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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = items[index];
        return _MessageCard(
          message: message,
          onTap: () => _onMessageTap(message),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.onTap,
  });

  final InboxMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = theme.syncStatusColors;
    final isTarefa = MessageType.isTarefa(message.type);
    final isUnread = MessageRecipientState.isUnread(message.estado);
    final author = message.author.trim();
    final (statusFg, statusBg) = _statusChipColors(message.estado, sync);

    return Material(
      key: Key('message_item_${message.id}'),
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: Key('message_leading_${message.id}'),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isTarefa
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTarefa ? Icons.task_alt : Icons.mail_outline,
                  color: isTarefa
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            message.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: sync.syncing,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      author.isNotEmpty
                          ? '$author · ${_formatCreatedAt(message.createdAt)}'
                          : _formatCreatedAt(message.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          key: Key('message_type_badge_${message.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isTarefa
                                ? theme.colorScheme.primary
                                : sync.draftContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            MessageType.listLabel(message.type),
                            style: TextStyle(
                              color: isTarefa
                                  ? theme.colorScheme.onPrimary
                                  : sync.draft,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusChip(
                          label:
                              MessageRecipientState.listLabel(message.estado),
                          textKey: Key('message_status_${message.id}'),
                          foreground: statusFg,
                          background: statusBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  /// Par (texto, fundo) do chip de estado da mensagem.
  (Color, Color) _statusChipColors(String estado, SyncStatusColors sync) {
    return switch (estado) {
      MessageRecipientState.enviada => (sync.syncing, sync.syncingContainer),
      MessageRecipientState.lida => (sync.draft, sync.draftContainer),
      MessageRecipientState.aceita => (sync.pending, sync.pendingContainer),
      MessageRecipientState.concluida => (sync.synced, sync.syncedContainer),
      MessageRecipientState.recusada => (sync.failed, sync.failedContainer),
      _ => (sync.draft, sync.draftContainer),
    };
  }
}
