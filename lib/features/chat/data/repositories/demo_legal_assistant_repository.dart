import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/chat_repositories.dart';
import '../datasources/demo_legal_knowledge_base.dart';

/// Answers from the built-in demo knowledge base, with a short pause so the
/// thinking state is visible.
class DemoLegalAssistantRepository implements LegalAssistantRepository {
  DemoLegalAssistantRepository({
    DemoLegalKnowledgeBase knowledgeBase = const DemoLegalKnowledgeBase(),
    this.thinkingTime = const Duration(milliseconds: 900),
  }) : _kb = knowledgeBase;

  final DemoLegalKnowledgeBase _kb;
  final Duration thinkingTime;

  @override
  Future<LegalAnswer> ask({
    required String question,
    required String jurisdictionCode,
    List<ChatMessage> history = const [],
  }) async {
    if (question.trim().isEmpty) {
      throw const AssistantFailure('Please type a question first.');
    }
    await Future<void>.delayed(thinkingTime);
    return _kb.answer(question, jurisdictionCode: jurisdictionCode);
  }
}
