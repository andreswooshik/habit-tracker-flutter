import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker_flutter_new/models/chat_message.dart';
import 'package:habit_tracker_flutter_new/models/chat_state.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

/// AI coach chat screen
///
/// Renders the conversation held in [chatProvider] and lets the user
/// send messages. All state lives in Riverpod; this widget only holds
/// ephemeral controllers (text input, scrolling).
class AiChatScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const AiChatScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  static const _suggestions = [
    'How am I doing today?',
    'What\'s my best streak?',
    'Give me a tip',
    'Motivate me',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) {
    final message = text ?? _inputController.text;
    if (message.trim().isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(message);
    _inputController.clear();
    _inputFocusNode.requestFocus();
  }

  void _scrollToBottom() {
    // Wait for the new message to be laid out before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto-scroll on new messages and surface errors as snackbars
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous == null) return;
      if (next.messages.length != previous.messages.length ||
          next.isAssistantTyping != previous.isAssistantTyping) {
        _scrollToBottom();
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(chatProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('AI Coach'),
              actions: [_buildClearButton(chatState)],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: chatState.isEmpty
                ? _EmptyConversation(onSuggestionTap: _sendMessage)
                : _buildMessageList(chatState),
          ),
          _buildInputBar(chatState),
        ],
      ),
    );
  }

  Widget _buildClearButton(ChatState chatState) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'New chat',
      onPressed: chatState.isEmpty
          ? null
          : () => ref.read(chatProvider.notifier).clearConversation(),
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    final itemCount =
        chatState.messages.length + (chatState.isAssistantTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= chatState.messages.length) {
          return const _TypingIndicatorBubble();
        }
        return _MessageBubble(message: chatState.messages[index]);
      },
    );
  }

  Widget _buildInputBar(ChatState chatState) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.showAppBar && !chatState.isEmpty) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'New chat',
                onPressed: () =>
                    ref.read(chatProvider.notifier).clearConversation(),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ask your habit coach...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              tooltip: 'Send',
              onPressed: chatState.isAssistantTyping ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly empty state with tappable conversation starters
class _EmptyConversation extends StatelessWidget {
  final void Function(String) onSuggestionTap;

  const _EmptyConversation({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 36,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI Habit Coach',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask about your progress, streaks, or get tips\nto build better habits.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in _AiChatScreenState._suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestionTap(suggestion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single chat bubble, aligned by sender
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    final bubbleColor =
        isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.jm().format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Assistant "typing…" bubble with three pulsing dots
class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _buildDot(i, colorScheme),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(int index, ColorScheme colorScheme) {
    // Stagger each dot's pulse by a third of the cycle
    final progress = (_controller.value + index / 3) % 1.0;
    final opacity = 0.3 + 0.7 * (1 - (progress - 0.5).abs() * 2);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
