import 'package:equatable/equatable.dart';

/// Who authored a chat message
enum ChatSender {
  /// The person using the app
  user,

  /// The AI habit coach
  assistant,
}

/// Immutable value object representing a single chat message
///
/// Follows the same Equatable-based immutability pattern as the
/// other domain models (e.g. [StreakData], [Habit]).
class ChatMessage extends Equatable {
  /// Unique identifier for this message
  final String id;

  /// Who sent the message
  final ChatSender sender;

  /// The message body
  final String text;

  /// When the message was created
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  /// Convenience flag for UI alignment/styling
  bool get isUser => sender == ChatSender.user;

  @override
  List<Object?> get props => [id, sender, text, timestamp];
}
