import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat_entities.dart';
import '../repositories/chat_repositories.dart';

class AskParams extends Equatable {
  const AskParams({
    required this.question,
    required this.jurisdictionCode,
    this.history = const [],
  });
  final String question;
  final String jurisdictionCode;
  final List<ChatMessage> history;

  @override
  List<Object?> get props => [question, jurisdictionCode, history];
}

class AskLegalQuestion implements UseCase<LegalAnswer, AskParams> {
  const AskLegalQuestion(this._assistant);
  final LegalAssistantRepository _assistant;

  @override
  Future<LegalAnswer> call(AskParams p) => _assistant.ask(
    question: p.question.trim(),
    jurisdictionCode: p.jurisdictionCode,
    history: p.history,
  );
}

class GetConversation implements UseCase<Conversation?, String> {
  const GetConversation(this._repository);
  final ConversationRepository _repository;

  @override
  Future<Conversation?> call(String id) => _repository.get(id);
}

class GetConversations implements UseCase<List<Conversation>, NoParams> {
  const GetConversations(this._repository);
  final ConversationRepository _repository;

  @override
  Future<List<Conversation>> call(NoParams params) => _repository.getAll();
}

class SaveConversation implements UseCase<void, Conversation> {
  const SaveConversation(this._repository);
  final ConversationRepository _repository;

  @override
  Future<void> call(Conversation c) => _repository.save(c);
}

class DeleteConversation implements UseCase<void, String> {
  const DeleteConversation(this._repository);
  final ConversationRepository _repository;

  @override
  Future<void> call(String id) => _repository.delete(id);
}

/// A short title from the first question, e.g. "Do I have to answer police questions?"
String titleFromQuestion(String question) {
  final q = question.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (q.length <= 48) return q;
  final cut = q.substring(0, 48);
  final lastSpace = cut.lastIndexOf(' ');
  return '${cut.substring(0, lastSpace > 24 ? lastSpace : 48)}…';
}
