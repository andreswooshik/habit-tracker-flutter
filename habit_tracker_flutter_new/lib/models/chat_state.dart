import 'package:equatable/equatable.dart';
import 'chat_message.dart';

/// Immutable state container for the AI coach conversation
///
/// Mirrors the structure of [HabitState]: an unmodifiable message list,
/// a busy flag, and an optional error message.
class ChatState extends Equatable {
  /// All messages in the conversation, oldest first
  final List<ChatMessage> messages;

  /// Whether the assistant is currently composing a reply
  final bool isAssistantTyping;

  /// Error message if the last send failed
  final String? errorMessage;

  const ChatState({
    required this.messages,
    this.isAssistantTyping = false,
    this.errorMessage,
  });

  /// Factory constructor for the initial empty conversation
  factory ChatState.initial() {
    return const ChatState(
      messages: [],
      isAssistantTyping: false,
      errorMessage: null,
    );
  }

  /// Whether the conversation has no messages yet
  bool get isEmpty => messages.isEmpty;

  /// Returns a new state with [message] appended
  ChatState addMessage(ChatMessage message) {
    return ChatState(
      messages: List.unmodifiable([...messages, message]),
      isAssistantTyping: isAssistantTyping,
      errorMessage: errorMessage,
    );
  }

  /// Returns a copy with the given fields replaced
  ///
  /// Pass [clearError] to explicitly reset [errorMessage] to null.
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isAssistantTyping,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isAssistantTyping: isAssistantTyping ?? this.isAssistantTyping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [messages, isAssistantTyping, errorMessage];
}
