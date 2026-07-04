import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/chat_message.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/ai_chat_screen.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_chat_service.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

/// Fake chat service with a controllable reply, so tests can observe
/// the typing indicator before the reply arrives
class FakeChatService implements IChatService {
  final String reply;
  Completer<String>? pendingReply;
  String? lastUserMessage;

  FakeChatService({this.reply = 'Fake coach reply'});

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<ChatMessage> history,
    required ChatCoachContext context,
  }) {
    lastUserMessage = userMessage;
    final completer = Completer<String>();
    pendingReply = completer;
    return completer.future;
  }

  void completeReply() => pendingReply!.complete(reply);
}

void main() {
  late FakeChatService fakeService;

  Widget buildTestApp() {
    fakeService = FakeChatService();
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
        completionsRepositoryProvider.overrideWithValue(
          MockCompletionsRepository(),
        ),
        chatServiceProvider.overrideWithValue(fakeService),
      ],
      child: const MaterialApp(home: AiChatScreen()),
    );
  }

  group('AiChatScreen', () {
    testWidgets('shows empty state with suggestion chips', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Your AI Habit Coach'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(4));
      expect(find.text('How am I doing today?'), findsOneWidget);
    });

    testWidgets('sending a message shows user bubble, typing indicator, '
        'then assistant reply', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(find.byType(TextField), 'hello coach');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();

      // User bubble is visible and the empty state is gone
      expect(find.text('hello coach'), findsOneWidget);
      expect(find.text('Your AI Habit Coach'), findsNothing);
      expect(fakeService.lastUserMessage, 'hello coach');

      // Send button is disabled while the reply is pending
      final sendButton = tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton),
      ));
      expect(sendButton.onPressed, isNull);

      // Reply arrives
      fakeService.completeReply();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fake coach reply'), findsOneWidget);
    });

    testWidgets('tapping a suggestion chip sends it as a message',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Motivate me'));
      await tester.pump();

      expect(fakeService.lastUserMessage, 'Motivate me');
      // Chip text now appears as a user bubble instead of the empty state
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Motivate me'), findsOneWidget);

      fakeService.completeReply();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Fake coach reply'), findsOneWidget);
    });

    testWidgets('clear button starts a new conversation', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      fakeService.completeReply();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('New chat'));
      await tester.pump();

      expect(find.text('hello'), findsNothing);
      expect(find.text('Fake coach reply'), findsNothing);
      expect(find.text('Your AI Habit Coach'), findsOneWidget);
    });

    testWidgets('ignores empty input', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();

      // Still on the empty state, nothing was sent
      expect(fakeService.lastUserMessage, isNull);
      expect(find.text('Your AI Habit Coach'), findsOneWidget);
    });
  });
}
