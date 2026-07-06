import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'gemini_client.dart';
import 'interfaces/i_chat_service.dart';

/// LLM-backed implementation of [IChatService] using the Google Gemini API
///
/// Sends the conversation history plus a habit-coach system instruction
/// (personalized with the user's [ChatCoachContext]) through the shared
/// [GeminiClient], which handles retries, model fallback, and parsing.
class GeminiChatService implements IChatService {
  final GeminiClient _gemini;

  GeminiChatService({
    required String apiKey,
    String model = 'gemini-2.5-flash',
    Duration retryDelay = const Duration(milliseconds: 800),
    http.Client? client,
  }) : _gemini = GeminiClient(
          apiKey: apiKey,
          model: model,
          retryDelay: retryDelay,
          client: client,
        );

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<ChatMessage> history,
    required ChatCoachContext context,
  }) {
    return _gemini.generateText(
      systemInstruction: _buildSystemInstruction(context),
      // History already ends with the latest user message
      contents: [
        for (final message in history)
          {
            'role': message.isUser ? 'user' : 'model',
            'parts': [
              {'text': message.text},
            ],
          },
      ],
    );
  }

  String _buildSystemInstruction(ChatCoachContext context) {
    final habits = context.activeHabitNames.isEmpty
        ? 'none yet'
        : context.activeHabitNames.join(', ');
    final streak = context.bestCurrentStreak > 0
        ? '${context.bestCurrentStreak} day(s)'
            '${context.bestStreakHabitName != null ? ' on "${context.bestStreakHabitName}"' : ''}'
        : 'no active streak';

    return 'You are a friendly, encouraging habit coach inside a habit '
        'tracker app. Keep replies short (2-4 sentences), practical, and '
        'positive. Use the user\'s real data when relevant.\n'
        'User\'s current data:\n'
        '- Active habits: $habits\n'
        '- Today: ${context.completedTodayCount} of '
        '${context.todaysHabitsCount} scheduled habits completed\n'
        '- Best current streak: $streak';
  }
}
