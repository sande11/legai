import 'package:equatable/equatable.dart';

/// A law or section an answer relies on.
class LegalSource extends Equatable {
  const LegalSource({required this.title, required this.detail});

  /// e.g. "Constitution of Malawi · s. 42"
  final String title;

  /// e.g. "Arrest, detention and fair trial"
  final String detail;

  @override
  List<Object?> get props => [title, detail];
}

/// LegAI's reply to a question.
class LegalAnswer extends Equatable {
  const LegalAnswer({
    required this.summary,
    this.points = const [],
    this.sources = const [],
    this.followUps = const [],
    this.isDemo = false,
  });

  /// One or two plain-language sentences.
  final String summary;
  final List<String> points;
  final List<LegalSource> sources;

  /// Suggested next questions, shown as chips.
  final List<String> followUps;

  /// True when the answer came from the built-in demo knowledge base.
  final bool isDemo;

  /// The answer as one block of text, for reading aloud or copying.
  String get spokenText => [summary, ...points].join(' ');

  @override
  List<Object?> get props => [summary, points, sources, followUps, isDemo];
}

enum MessageRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.answer,
  });

  final String id;
  final MessageRole role;

  /// The user's question, or the answer's summary for the assistant.
  final String text;
  final DateTime createdAt;

  /// Structured answer (assistant messages only).
  final LegalAnswer? answer;

  bool get isUser => role == MessageRole.user;

  @override
  List<Object?> get props => [id, role, text, createdAt, answer];
}

/// How the conversation happened.
enum ConversationChannel { text, voice }

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
    required this.jurisdictionCode,
    this.channel = ConversationChannel.text,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final String jurisdictionCode;
  final ConversationChannel channel;

  Conversation copyWith({
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      jurisdictionCode: jurisdictionCode,
      channel: channel,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    messages,
    updatedAt,
    jurisdictionCode,
    channel,
  ];
}
