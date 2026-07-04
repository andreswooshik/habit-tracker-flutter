import '../../models/chat_message.dart';

/// Snapshot of the user's habit data handed to the chat service
///
/// Keeps the service decoupled from providers/repositories (DIP):
/// the caller assembles this from existing state, and the service
/// only ever sees a plain value object.
class ChatCoachContext {
  /// Names of all active (non-archived) habits
  final List<String> activeHabitNames;

  /// Number of habits scheduled for today
  final int todaysHabitsCount;

  /// Number of today's habits already completed
  final int completedTodayCount;

  /// The best current streak across all habits (in days)
  final int bestCurrentStreak;

  /// Name of the habit holding the best current streak, if any
  final String? bestStreakHabitName;

  const ChatCoachContext({
    required this.activeHabitNames,
    required this.todaysHabitsCount,
    required this.completedTodayCount,
    required this.bestCurrentStreak,
    this.bestStreakHabitName,
  });
}

/// Interface for a conversational assistant that replies to user messages
///
/// Abstraction allows swapping the local rule-based coach for a real
/// LLM-backed implementation later without touching UI or state code.
abstract class IChatService {
  /// Generates the assistant's reply to [userMessage]
  ///
  /// [history] contains the conversation so far (oldest first), and
  /// [context] carries a snapshot of the user's habit data.
  Future<String> generateReply({
    required String userMessage,
    required List<ChatMessage> history,
    required ChatCoachContext context,
  });
}
