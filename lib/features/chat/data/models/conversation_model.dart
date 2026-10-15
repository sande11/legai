import '../../domain/entities/chat_entities.dart';

/// JSON mapping for conversations stored on the device.
abstract final class ConversationModel {
  static Map<String, Object?> toJson(Conversation c) => {
    'id': c.id,
    'title': c.title,
    'updatedAt': c.updatedAt.toIso8601String(),
    'jurisdiction': c.jurisdictionCode,
    'channel': c.channel.name,
    'messages': c.messages.map(_messageToJson).toList(),
  };

  static Conversation fromJson(Map<String, Object?> j) => Conversation(
    id: j['id'] as String,
    title: (j['title'] as String?) ?? 'Conversation',
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    jurisdictionCode: (j['jurisdiction'] as String?) ?? 'MW',
    channel: ConversationChannel.values.firstWhere(
      (ch) => ch.name == j['channel'],
      orElse: () => ConversationChannel.text,
    ),
    messages: ((j['messages'] as List?) ?? const [])
        .cast<Map<String, Object?>>()
        .map(_messageFromJson)
        .toList(),
  );

  static Map<String, Object?> _messageToJson(ChatMessage m) => {
    'id': m.id,
    'role': m.role.name,
    'text': m.text,
    'createdAt': m.createdAt.toIso8601String(),
    if (m.answer != null) 'answer': _answerToJson(m.answer!),
  };

  static ChatMessage _messageFromJson(Map<String, Object?> j) => ChatMessage(
    id: j['id'] as String,
    role: j['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
    text: (j['text'] as String?) ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
    answer: j['answer'] == null
        ? null
        : _answerFromJson((j['answer'] as Map).cast<String, Object?>()),
  );

  static Map<String, Object?> _answerToJson(LegalAnswer a) => {
    'summary': a.summary,
    'points': a.points,
    'sources': a.sources
        .map((s) => {'title': s.title, 'detail': s.detail})
        .toList(),
    'followUps': a.followUps,
    'isDemo': a.isDemo,
  };

  static LegalAnswer _answerFromJson(Map<String, Object?> j) => LegalAnswer(
    summary: (j['summary'] as String?) ?? '',
    points: ((j['points'] as List?) ?? const []).cast<String>(),
    sources: ((j['sources'] as List?) ?? const [])
        .cast<Map>()
        .map(
          (s) => LegalSource(
            title: s['title'] as String,
            detail: (s['detail'] as String?) ?? '',
          ),
        )
        .toList(),
    followUps: ((j['followUps'] as List?) ?? const []).cast<String>(),
    isDemo: (j['isDemo'] as bool?) ?? false,
  );
}
