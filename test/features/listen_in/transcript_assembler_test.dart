import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';
import 'package:legai/features/listen_in/domain/services/transcript_assembler.dart';

void main() {
  late TranscriptAssembler assembler;

  setUp(() => assembler = TranscriptAssembler());

  test('partial updates grow one open segment', () {
    final a = assembler.ingest(
      const CaptureUpdate('We have', isFinal: false),
      const Duration(seconds: 1),
    );
    final b = assembler.ingest(
      const CaptureUpdate('We have reviewed it', isFinal: false),
      const Duration(seconds: 2),
    );
    expect(a!.id, b!.id);
    expect(b.text, 'We have reviewed it');
    expect(b.isFinal, isFalse);
    expect(
      b.start,
      const Duration(seconds: 1),
      reason: 'start time comes from the first partial',
    );
  });

  test('each commit becomes its own segment with only the new words', () {
    final first = assembler.ingest(
      const CaptureUpdate('We have reviewed it.', isFinal: true),
      Duration.zero,
    );
    final second = assembler.ingest(
      const CaptureUpdate(
        'We have reviewed it. Please sign this letter.',
        isFinal: true,
      ),
      const Duration(seconds: 5),
    );
    expect(first!.isFinal, isTrue);
    expect(second!.id, isNot(first.id));
    expect(second.text, 'Please sign this letter.');
    expect(second.start, const Duration(seconds: 5));
  });

  test('ignores updates with nothing new', () {
    assembler.ingest(
      const CaptureUpdate('Hello there', isFinal: true),
      Duration.zero,
    );
    expect(
      assembler.ingest(
        const CaptureUpdate('Hello there', isFinal: true),
        Duration.zero,
      ),
      isNull,
    );
  });

  test('copes with the recognizer revising earlier words', () {
    assembler.ingest(
      const CaptureUpdate('I want to resign', isFinal: true),
      Duration.zero,
    );
    final s = assembler.ingest(
      const CaptureUpdate('I want to re-sign the lease today', isFinal: false),
      Duration.zero,
    );
    expect(s, isNotNull);
    expect(s!.text, contains('today'));
  });

  test('splits a very long uncommitted monologue at a sentence end', () {
    final small = TranscriptAssembler(maxSegmentLength: 40);
    final s = small.ingest(
      const CaptureUpdate(
        'This is the first sentence of many. And this keeps going on and on',
        isFinal: false,
      ),
      Duration.zero,
    );
    expect(s!.isFinal, isTrue);
    expect(s.text, 'This is the first sentence of many.');
    final next = small.ingest(
      const CaptureUpdate(
        'This is the first sentence of many. And this keeps going on and on',
        isFinal: false,
      ),
      const Duration(seconds: 3),
    );
    expect(next!.text, 'And this keeps going on and on');
    expect(next.isFinal, isFalse);
  });
}
