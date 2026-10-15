import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/chat/data/repositories/demo_legal_assistant_repository.dart';
import 'package:legai/features/chat/domain/usecases/chat_usecases.dart';
import 'package:legai/features/chat/presentation/bloc/chat_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryConversations conversations;
  late FakeSynthesizer tts;

  ChatBloc build() => ChatBloc(
    askLegalQuestion: AskLegalQuestion(
      DemoLegalAssistantRepository(thinkingTime: Duration.zero),
    ),
    getConversation: GetConversation(conversations),
    saveConversation: SaveConversation(conversations),
    deleteConversation: DeleteConversation(conversations),
    synthesizer: tts,
    jurisdictionCode: () => 'MW',
  );

  setUp(() {
    conversations = InMemoryConversations();
    tts = FakeSynthesizer();
  });

  blocTest<ChatBloc, ChatState>(
    'asking a question shows thinking, then the answer, and saves the chat',
    build: build,
    act: (b) => b
      ..add(const ChatOpened())
      ..add(const ChatMessageSent('Do I have to answer police questions?')),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.status, ChatStatus.ready);
      expect(b.state.messages, hasLength(2));
      expect(b.state.messages.last.answer!.sources, isNotEmpty);
      expect(conversations.items, hasLength(1));
      expect(
        conversations.items.values.single.title,
        'Do I have to answer police questions?',
      );
    },
  );

  blocTest<ChatBloc, ChatState>(
    'an initial question is sent straight away',
    build: build,
    act: (b) => b.add(
      const ChatOpened(initialQuestion: 'Can my landlord keep my deposit?'),
    ),
    wait: const Duration(milliseconds: 50),
    verify: (b) =>
        expect(b.state.messages.first.text, 'Can my landlord keep my deposit?'),
  );

  blocTest<ChatBloc, ChatState>(
    'read aloud speaks the whole answer',
    build: build,
    act: (b) async {
      b
        ..add(const ChatOpened())
        ..add(const ChatMessageSent('Can my employer cut my salary?'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      b.add(ChatReadAloudToggled(b.state.messages.last.id));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) =>
        expect(tts.spoken.single, startsWith('Usually not on their own')),
  );
}
