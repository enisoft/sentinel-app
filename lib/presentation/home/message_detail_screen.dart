import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/messages/message_recipient_state.dart';
import '../../core/messages/message_type.dart';
import '../../data/repositories/message_repository.dart';
import '../../domain/models/inbox_message.dart';

/// Detalhe de mensagem com ações conforme tipo e estado.
class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({
    super.key,
    required this.messageId,
    this.messageRepository,
  });

  final String messageId;
  final MessageRepository? messageRepository;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  InboxMessage? _message;
  bool _isLoading = true;
  bool _isActing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  MessageRepository get _repository =>
      widget.messageRepository ?? getIt<MessageRepository>();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var message = await _repository.getById(widget.messageId);
      if (message != null &&
          MessageRecipientState.isUnread(message.estado)) {
        message = await _repository.markRead(widget.messageId);
      }
      if (!mounted) return;
      setState(() {
        _message = message;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runAction(Future<InboxMessage> Function() action) async {
    setState(() {
      _isActing = true;
      _errorMessage = null;
    });
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _message = updated;
        _isActing = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isActing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('message_detail_screen'),
      appBar: AppBar(
        title: Text(
          _message?.displayTitle ?? 'Mensagem',
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _message == null) {
      return Center(child: Text(_errorMessage!));
    }
    final message = _message;
    if (message == null) {
      return const Center(child: Text('Mensagem não encontrada.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Chip(
              key: Key(
                MessageType.isTarefa(message.type)
                    ? 'message_detail_tarefa_chip'
                    : 'message_detail_informe_chip',
              ),
              avatar: Icon(
                MessageType.isTarefa(message.type)
                    ? Icons.task_alt
                    : Icons.mail_outline,
                color: MessageType.isTarefa(message.type)
                    ? Colors.indigo.shade700
                    : Colors.blue.shade700,
              ),
              label: Text(MessageType.listLabel(message.type)),
              backgroundColor: MessageType.isTarefa(message.type)
                  ? Colors.indigo.shade50
                  : Colors.blue.shade50,
            ),
          ),
          Text(
            MessageRecipientState.listLabel(message.estado),
            key: const Key('message_detail_status'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (message.author.trim().isNotEmpty)
            Text(
              'De: ${message.author.trim()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          Text(
            _formatCreatedAt(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            message.body.trim().isNotEmpty ? message.body : '(sem conteúdo)',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 24),
          ..._buildActions(message),
        ],
      ),
    );
  }

  List<Widget> _buildActions(InboxMessage message) {
    if (!MessageType.isTarefa(message.type)) {
      return const [];
    }

    final buttons = <Widget>[];

    if (message.estado == MessageRecipientState.lida) {
      buttons.addAll([
        FilledButton(
          key: const Key('message_accept_button'),
          onPressed: _isActing
              ? null
              : () => _runAction(() => _repository.accept(message.id)),
          child: const Text('Aceitar tarefa'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('message_reject_button'),
          onPressed: _isActing
              ? null
              : () => _runAction(() => _repository.reject(message.id)),
          child: const Text('Recusar'),
        ),
      ]);
    }

    if (message.estado == MessageRecipientState.aceita) {
      buttons.add(
        FilledButton(
          key: const Key('message_complete_button'),
          onPressed: _isActing
              ? null
              : () => _runAction(() => _repository.complete(message.id)),
          child: const Text('Marcar como concluída'),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const [];
    }

    return buttons;
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
}
