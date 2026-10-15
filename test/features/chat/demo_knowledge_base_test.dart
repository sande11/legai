import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/chat/data/datasources/demo_legal_knowledge_base.dart';
import 'package:legai/features/chat/data/repositories/demo_legal_assistant_repository.dart';
import 'package:legai/features/chat/domain/usecases/chat_usecases.dart';

void main() {
  const kb = DemoLegalKnowledgeBase();

  test('police questions get the s.42 answer in Malawi', () {
    final a = kb.answer(
      'The police called and asked me to come to the station to answer a few questions. Do I have to say anything?',
      jurisdictionCode: 'MW',
    );
    expect(a.summary, contains('don\'t have to answer'));
    expect(a.sources.single.title, contains('s. 42'));
    expect(a.isDemo, isTrue);
  });

  test('other countries get the general answer without a Malawi citation', () {
    final a = kb.answer(
      'Do I have to answer police questions?',
      jurisdictionCode: 'GB',
    );
    expect(a.sources, isEmpty);
  });

  test('follow-up chips lead to their own topics', () {
    expect(
      kb.answer('Can I bring someone with me?', jurisdictionCode: 'MW').summary,
      contains('lawyer'),
    );
    expect(
      kb
          .answer('What if they don\'t charge me?', jurisdictionCode: 'MW')
          .summary,
      contains('48 hours'),
    );
  });

  test('a lower salary beats the generic contract topic', () {
    final a = kb.answer(
      'My employer wants me to sign a new contract with a lower salary',
      jurisdictionCode: 'MW',
    );
    expect(a.summary, startsWith('Usually not on their own'));
  });

  test('unknown questions get the fallback with suggestions', () {
    final a = kb.answer('Tell me a joke', jurisdictionCode: 'MW');
    expect(a.followUps, isNotEmpty);
  });

  test('repository rejects empty questions', () async {
    final repo = DemoLegalAssistantRepository(thinkingTime: Duration.zero);
    expect(
      () => repo.ask(question: '  ', jurisdictionCode: 'MW'),
      throwsA(anything),
    );
  });

  test('titles are trimmed to a readable length', () {
    expect(titleFromQuestion('Short question?'), 'Short question?');
    final long = titleFromQuestion(
      'My landlord says he will keep my whole deposit because of normal wear and tear in the flat',
    );
    expect(long.length, lessThanOrEqualTo(49));
    expect(long, endsWith('…'));
  });
}
