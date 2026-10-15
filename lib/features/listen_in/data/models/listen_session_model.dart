import '../../domain/entities/listen_entities.dart';

/// JSON mapping for sessions stored on the device.
abstract final class ListenSessionModel {
  static Map<String, Object?> toJson(ListenSession s) => {
    'id': s.id,
    'title': s.title,
    'topic': s.topic.name,
    'startedAt': s.startedAt.toIso8601String(),
    'durationMs': s.duration.inMilliseconds,
    'jurisdiction': s.jurisdictionCode,
    'audioPath': s.audioPath,
    'summary': s.summary,
    'marksMs': s.marks.map((m) => m.inMilliseconds).toList(),
    'segments': [
      for (final g in s.segments)
        {
          'id': g.id,
          'text': g.text,
          'startMs': g.start.inMilliseconds,
          'final': g.isFinal,
          if (g.speaker != null) 'speaker': g.speaker,
        },
    ],
    'flags': [
      for (final f in s.flags)
        {
          'id': f.id,
          'key': f.key,
          'kind': f.kind.name,
          'title': f.title,
          'body': f.body,
          'atMs': f.at.inMilliseconds,
          'quote': f.quote,
          'citation': f.citation,
          'segmentId': f.segmentId,
          'whispered': f.whispered,
        },
    ],
  };

  static ListenSession fromJson(Map<String, Object?> j) => ListenSession(
    id: j['id'] as String,
    title: (j['title'] as String?) ?? 'Conversation',
    topic: ConversationTopic.values.firstWhere(
      (t) => t.name == j['topic'],
      orElse: () => ConversationTopic.work,
    ),
    startedAt: DateTime.parse(j['startedAt'] as String),
    duration: Duration(milliseconds: (j['durationMs'] as num?)?.toInt() ?? 0),
    jurisdictionCode: (j['jurisdiction'] as String?) ?? 'MW',
    audioPath: j['audioPath'] as String?,
    summary: j['summary'] as String?,
    marks: ((j['marksMs'] as List?) ?? const [])
        .map((m) => Duration(milliseconds: (m as num).toInt()))
        .toList(),
    segments: ((j['segments'] as List?) ?? const []).cast<Map>().map((g) {
      return TranscriptSegment(
        id: g['id'] as String,
        text: (g['text'] as String?) ?? '',
        start: Duration(milliseconds: (g['startMs'] as num?)?.toInt() ?? 0),
        isFinal: (g['final'] as bool?) ?? true,
        speaker: g['speaker'] as String?,
      );
    }).toList(),
    flags: ((j['flags'] as List?) ?? const []).cast<Map>().map((f) {
      return AdviceFlag(
        id: f['id'] as String,
        key: (f['key'] as String?) ?? f['id'] as String,
        kind: AdviceKind.values.firstWhere(
          (k) => k.name == f['kind'],
          orElse: () => AdviceKind.caution,
        ),
        title: (f['title'] as String?) ?? '',
        body: (f['body'] as String?) ?? '',
        at: Duration(milliseconds: (f['atMs'] as num?)?.toInt() ?? 0),
        quote: f['quote'] as String?,
        citation: f['citation'] as String?,
        segmentId: f['segmentId'] as String?,
        whispered: (f['whispered'] as bool?) ?? false,
      );
    }).toList(),
  );
}
