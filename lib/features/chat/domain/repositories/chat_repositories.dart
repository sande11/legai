import '../entities/chat_entities.dart';

/// Answers legal questions. Today this is the demo knowledge base; a
/// backend implementation can replace it without touching the UI.
abstract interface class LegalAssistantRepository {
  /// Throws [AssistantFailure] if no answer can be produced.
  Future<LegalAnswer> ask({
    required String question,
    required String jurisdictionCode,
    List<ChatMessage> history = const [],
  });
}

/// Saved conversations, kept on the phone.
abstract interface class ConversationRepository {
  Future<List<Conversation>> getAll();
  Future<Conversation?> get(String id);
  Future<void> save(Conversation conversation);
  Future<void> delete(String id);
}
