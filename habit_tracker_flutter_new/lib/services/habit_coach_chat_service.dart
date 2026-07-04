import 'dart:math';

import '../models/chat_message.dart';
import 'interfaces/i_chat_service.dart';

/// Local, rule-based implementation of [IChatService]
///
/// Answers questions about the user's habits using the provided
/// [ChatCoachContext] snapshot. Runs fully offline with a small
/// simulated "thinking" delay so the UI's typing indicator is visible.
/// Can be replaced by an LLM-backed service without changing callers.
class HabitCoachChatService implements IChatService {
  final Random _random;

  HabitCoachChatService({Random? random}) : _random = random ?? Random();

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<ChatMessage> history,
    required ChatCoachContext context,
  }) async {
    // Simulate thinking time so the typing indicator is visible
    await Future.delayed(
      Duration(milliseconds: 500 + _random.nextInt(700)),
    );

    final message = userMessage.toLowerCase();

    if (_matchesAny(message, ['hello', 'hi', 'hey', 'good morning', 'good evening'])) {
      return _greetingReply(context);
    }
    if (_matchesAny(message, ['progress', 'today', 'how am i doing', 'status'])) {
      return _progressReply(context);
    }
    if (_matchesAny(message, ['streak'])) {
      return _streakReply(context);
    }
    if (_matchesAny(message, ['motivat', 'inspire', 'give up', 'hard', 'struggl'])) {
      return _motivationReply(context);
    }
    if (_matchesAny(message, ['add', 'new habit', 'create'])) {
      return 'To add a new habit, go to the Habits tab and tap the + button. '
          'Start small: a habit you can finish in two minutes is far easier '
          'to keep than an ambitious one you dread.';
    }
    if (_matchesAny(message, ['tip', 'advice', 'suggest', 'help'])) {
      return _tipReply();
    }
    if (_matchesAny(message, ['thank', 'thanks'])) {
      return 'Anytime! Consistency beats intensity — see you tomorrow. 💪';
    }

    return _fallbackReply(context);
  }

  bool _matchesAny(String message, List<String> keywords) {
    return keywords.any(message.contains);
  }

  String _greetingReply(ChatCoachContext context) {
    if (context.activeHabitNames.isEmpty) {
      return 'Hi there! 👋 I\'m your habit coach. You don\'t have any habits '
          'yet — head to the Habits tab and create your first one, then ask '
          'me about your progress anytime.';
    }
    final remaining =
        context.todaysHabitsCount - context.completedTodayCount;
    if (remaining <= 0 && context.todaysHabitsCount > 0) {
      return 'Hey! 👋 You\'ve already completed all ${context.todaysHabitsCount} '
          'habits for today — fantastic work!';
    }
    return 'Hey! 👋 You have $remaining habit${remaining == 1 ? '' : 's'} left '
        'today. Want a quick progress summary? Just ask "how am I doing?"';
  }

  String _progressReply(ChatCoachContext context) {
    if (context.todaysHabitsCount == 0) {
      return 'Nothing is scheduled for today. A rest day is fine — or add a '
          'small habit from the Habits tab to keep momentum going.';
    }
    final done = context.completedTodayCount;
    final total = context.todaysHabitsCount;
    final percent = ((done / total) * 100).round();
    if (done == total) {
      return 'You\'re at 100% today — all $total habits done. Outstanding! 🎉';
    }
    if (done == 0) {
      return 'You haven\'t checked anything off yet today (0 of $total). '
          'Pick the easiest one and knock it out — starting is the hardest part.';
    }
    return 'You\'ve completed $done of $total habits today ($percent%). '
        'Keep going — finishing strong today protects your streaks.';
  }

  String _streakReply(ChatCoachContext context) {
    if (context.bestCurrentStreak <= 0) {
      return 'No active streaks right now. Complete a habit today to start '
          'one — day 1 is where every great streak begins!';
    }
    final name = context.bestStreakHabitName;
    return 'Your best current streak is ${context.bestCurrentStreak} '
        'day${context.bestCurrentStreak == 1 ? '' : 's'}'
        '${name != null ? ' on "$name"' : ''}. 🔥 '
        'Don\'t break the chain — check it off again today!';
  }

  String _motivationReply(ChatCoachContext context) {
    const quotes = [
      'You don\'t have to be perfect, just consistent. One small win today '
          'is all it takes.',
      'Motivation gets you started; habit keeps you going. Show up for two '
          'minutes and momentum will do the rest.',
      'Missing one day is an accident. Missing two is the start of a new '
          'habit — get back on track today!',
      'Every habit you complete is a vote for the person you want to become.',
    ];
    return quotes[_random.nextInt(quotes.length)];
  }

  String _tipReply() {
    const tips = [
      'Habit stacking works wonders: attach a new habit to an existing '
          'routine, like "after I brush my teeth, I meditate for 1 minute".',
      'Make it obvious: put your running shoes by the door, your book on '
          'your pillow. Environment beats willpower.',
      'Track streaks, but forgive slips. Aim to never miss twice in a row.',
      'Shrink the habit until it\'s impossible to say no: one push-up, one '
          'page, one minute. Consistency first, intensity later.',
    ];
    return tips[_random.nextInt(tips.length)];
  }

  String _fallbackReply(ChatCoachContext context) {
    final habitCount = context.activeHabitNames.length;
    return 'I\'m your habit coach — I can help with your '
        '$habitCount active habit${habitCount == 1 ? '' : 's'}. Try asking:\n'
        '• "How am I doing today?"\n'
        '• "What\'s my best streak?"\n'
        '• "Give me a tip"\n'
        '• "Motivate me"';
  }
}
