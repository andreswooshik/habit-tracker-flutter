import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/api_keys.dart';
import '../models/chat_message.dart';
import '../models/chat_state.dart';
import '../services/gemini_chat_service.dart';
import '../services/habit_coach_chat_service.dart';
import '../services/interfaces/i_chat_service.dart';
import '../services/services.dart';
import 'providers.dart';

/// Provider for the chat service implementation
///
/// Uses the Gemini LLM when an API key is provided (see
/// lib/config/api_keys.dart), and falls back to the offline rule-based
/// coach otherwise (Dependency Inversion — the notifier and UI never
/// know which one they're talking to).
final chatServiceProvider = Provider<IChatService>((ref) {
  if (ApiKeys.gemini.isNotEmpty) {
    return GeminiChatService(apiKey: ApiKeys.gemini);
  }
  return HabitCoachChatService();
});

/// Builds a [ChatCoachContext] snapshot from current habit state
///
/// Derived state only — recomputes automatically when habits,
/// completions, or streaks change.
final chatCoachContextProvider = Provider<ChatCoachContext>((ref) {
  final habitState = ref.watch(habitsProvider);
  final activeHabitNames =
      habitState.habits.where((h) => !h.isArchived).map((h) => h.name).toList();

  final todaysHabitsCount = ref.watch(todaysHabitsCountProvider);
  final completedTodayCount = ref.watch(completedTodayCountProvider);

  final streaks = ref.watch(allStreaksProvider);
  var bestCurrentStreak = 0;
  String? bestStreakHabitName;
  streaks.forEach((habitId, streakData) {
    if (streakData.current > bestCurrentStreak) {
      bestCurrentStreak = streakData.current;
      bestStreakHabitName = habitState.habitsById[habitId]?.name;
    }
  });

  return ChatCoachContext(
    activeHabitNames: activeHabitNames,
    todaysHabitsCount: todaysHabitsCount,
    completedTodayCount: completedTodayCount,
    bestCurrentStreak: bestCurrentStreak,
    bestStreakHabitName: bestStreakHabitName,
  );
});

/// StateNotifier managing the AI coach conversation
///
/// Single Responsibility: only owns conversation state. The reply
/// generation is delegated to an [IChatService], and habit data is
/// injected as a [ChatCoachContext] snapshot at send time.
class ChatNotifier extends StateNotifier<ChatState> {
  final IChatService _chatService;
  final ChatCoachContext Function() _readContext;
  static const _uuid = Uuid();

  ChatNotifier(this._chatService, this._readContext)
      : super(ChatState.initial());

  /// Sends a user message and appends the assistant's reply
  ///
  /// Ignores empty input and re-entrant sends while a reply is pending.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isAssistantTyping) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sender: ChatSender.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    state = state
        .addMessage(userMessage)
        .copyWith(isAssistantTyping: true, clearError: true);

    try {
      final replyText = await _chatService.generateReply(
        userMessage: trimmed,
        history: state.messages,
        context: _readContext(),
      );

      if (!mounted) return;

      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        sender: ChatSender.assistant,
        text: replyText,
        timestamp: DateTime.now(),
      );
      state =
          state.addMessage(assistantMessage).copyWith(isAssistantTyping: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isAssistantTyping: false,
        errorMessage: 'Failed to get a reply: ${e.toString()}',
      );
    }
  }

  /// Clears any error message from the state
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Starts a fresh conversation
  void clearConversation() {
    state = ChatState.initial();
  }
}

/// Global provider for the AI coach conversation state
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.watch(chatServiceProvider);
  return ChatNotifier(service, () => ref.read(chatCoachContextProvider));
});
