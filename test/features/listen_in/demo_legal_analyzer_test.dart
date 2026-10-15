import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/listen_in/data/repositories/demo_legal_analyzer.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';
import 'package:legai/features/listen_in/domain/usecases/listen_in_usecases.dart';

void main() {
  final analyzer = DemoLegalAnalyzer();
  const work = AnalysisContext(
    topic: ConversationTopic.work,
    jurisdictionCode: 'MW',
  );

  TranscriptSegment seg(String text) => TranscriptSegment(
    id: 's1',
    text: text,
    start: const Duration(minutes: 12, seconds: 36),
    isFinal: true,
  );

  test('flags pressure to resign as a caution, at the segment time', () async {
    final flags = await analyzer.analyze(
      seg(
        'Given all that, we think it\'s best you resign today. If you sign this letter now, we\'ll keep it quiet.',
      ),
      work,
    );
    expect(flags.first.kind, AdviceKind.caution);
    expect(flags.first.key, 'resignation');
    expect(flags.first.at, const Duration(minutes: 12, seconds: 36));
    expect(flags.first.quote, contains('resign'));
    expect(flags.length, lessThanOrEqualTo(2));
  });

  test('adds the Malawi citation only for Malawi', () async {
    const text =
        'We have already decided, so there\'s no need to go through your side.';
    final mw = await analyzer.analyze(seg(text), work);
    final ke = await analyzer.analyze(
      seg(text),
      const AnalysisContext(
        topic: ConversationTopic.work,
        jurisdictionCode: 'KE',
      ),
    );
    expect(mw.single.citation, 'Employment Act, s. 57');
    expect(ke.single.citation, isNull);
  });

  test('topic-limited rules stay quiet in other topics', () async {
    final flags = await analyzer.analyze(
      seg('We will search the car now.'),
      const AnalysisContext(
        topic: ConversationTopic.housing,
        jurisdictionCode: 'MW',
      ),
    );
    expect(flags.where((f) => f.key == 'search'), isEmpty);
  });

  test(
    'AnalyzeSegment skips advice already given and partial segments',
    () async {
      final useCase = AnalyzeSegment(analyzer);
      final again = await useCase(
        AnalyzeSegmentParams(
          seg('You should resign.'),
          const AnalysisContext(
            topic: ConversationTopic.work,
            jurisdictionCode: 'MW',
            alreadyFlagged: {'resignation'},
          ),
        ),
      );
      expect(again.where((f) => f.key == 'resignation'), isEmpty);

      final partial = await useCase(
        AnalyzeSegmentParams(
          const TranscriptSegment(
            id: 'p',
            text: 'You should resign',
            start: Duration.zero,
          ),
          work,
        ),
      );
      expect(partial, isEmpty);
    },
  );

  test('summary mentions what was flagged', () async {
    final session = ListenSession(
      id: 'x',
      title: 'Work conversation',
      topic: ConversationTopic.work,
      startedAt: DateTime(2026, 10, 14),
      duration: const Duration(minutes: 18),
      jurisdictionCode: 'MW',
      segments: [seg('hello')],
      flags: await analyzer.analyze(seg('Please resign.'), work),
    );
    final summary = await analyzer.summarize(session);
    expect(summary, contains('one moment'));
    expect(summary, contains('work conversation'));
  });
}
