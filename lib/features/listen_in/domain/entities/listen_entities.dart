import 'package:equatable/equatable.dart';

/// The three kinds of advice LegAI gives, each with its own colour and icon.
enum AdviceKind {
  /// What the law gives you in this moment.
  rights('Your rights'),

  /// A risk in what's being said or asked of you.
  caution('Caution'),

  /// Something to do, ask for, or write down.
  nextStep('Next step');

  const AdviceKind(this.label);
  final String label;
}

/// A flagged moment in a conversation, with advice.
class AdviceFlag extends Equatable {
  const AdviceFlag({
    required this.id,
    required this.key,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.quote,
    this.citation,
    this.segmentId,
    this.whispered = false,
  });

  final String id;

  /// Identifies the rule or reason behind the flag, so the same advice is
  /// not repeated within one conversation.
  final String key;
  final AdviceKind kind;

  /// Short headline, e.g. "You don't have to sign today."
  final String title;
  final String body;

  /// Offset into the recording.
  final Duration at;

  /// The words that triggered the flag.
  final String? quote;

  /// e.g. "Employment Act, s. 57"
  final String? citation;
  final String? segmentId;

  /// True once it has been spoken into the user's earbuds.
  final bool whispered;

  /// What is read aloud for this flag.
  String get spokenText => '$title $body';

  AdviceFlag copyWith({bool? whispered}) => AdviceFlag(
    id: id,
    key: key,
    kind: kind,
    title: title,
    body: body,
    at: at,
    quote: quote,
    citation: citation,
    segmentId: segmentId,
    whispered: whispered ?? this.whispered,
  );

  @override
  List<Object?> get props => [
    id,
    key,
    kind,
    title,
    body,
    at,
    quote,
    citation,
    segmentId,
    whispered,
  ];
}

/// One stretch of speech in the live transcript.
class TranscriptSegment extends Equatable {
  const TranscriptSegment({
    required this.id,
    required this.text,
    required this.start,
    this.isFinal = false,
    this.speaker,
  });

  final String id;
  final String text;

  /// Offset into the recording when this stretch began.
  final Duration start;

  /// False while the recognizer may still change the words.
  final bool isFinal;

  /// Speaker label, when the transcription source provides one.
  final String? speaker;

  TranscriptSegment copyWith({String? text, bool? isFinal}) =>
      TranscriptSegment(
        id: id,
        text: text ?? this.text,
        start: start,
        isFinal: isFinal ?? this.isFinal,
        speaker: speaker,
      );

  @override
  List<Object?> get props => [id, text, start, isFinal, speaker];
}

/// What the conversation is about. Helps LegAI pick relevant advice.
enum ConversationTopic {
  work('Work'),
  police('Police'),
  housing('Housing'),
  businessDeal('Business deal'),
  clientIntake('Client intake'),
  family('Family');

  const ConversationTopic(this.label);
  final String label;
}

/// Choices made on the "Before you start" sheet.
class ListenSetup extends Equatable {
  const ListenSetup({
    required this.topic,
    required this.announce,
    required this.whisper,
    required this.jurisdictionCode,
  });

  final ConversationTopic topic;
  final bool announce;
  final bool whisper;
  final String jurisdictionCode;

  @override
  List<Object?> get props => [topic, announce, whisper, jurisdictionCode];
}

/// A finished Listen In conversation, stored on the phone.
class ListenSession extends Equatable {
  const ListenSession({
    required this.id,
    required this.title,
    required this.topic,
    required this.startedAt,
    required this.duration,
    required this.jurisdictionCode,
    this.audioPath,
    this.segments = const [],
    this.flags = const [],
    this.marks = const [],
    this.summary,
  });

  final String id;
  final String title;
  final ConversationTopic topic;
  final DateTime startedAt;
  final Duration duration;
  final String jurisdictionCode;

  /// WAV file on this phone, if the recording was kept.
  final String? audioPath;
  final List<TranscriptSegment> segments;
  final List<AdviceFlag> flags;

  /// Moments the user marked with the flag button.
  final List<Duration> marks;
  final String? summary;

  ListenSession copyWith({String? title, String? audioPath, String? summary}) =>
      ListenSession(
        id: id,
        title: title ?? this.title,
        topic: topic,
        startedAt: startedAt,
        duration: duration,
        jurisdictionCode: jurisdictionCode,
        audioPath: audioPath ?? this.audioPath,
        segments: segments,
        flags: flags,
        marks: marks,
        summary: summary ?? this.summary,
      );

  @override
  List<Object?> get props => [
    id,
    title,
    topic,
    startedAt,
    duration,
    jurisdictionCode,
    audioPath,
    segments,
    flags,
    marks,
    summary,
  ];
}
