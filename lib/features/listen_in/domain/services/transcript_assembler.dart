import '../entities/listen_entities.dart';
import '../repositories/listen_repositories.dart';

/// Turns the recognizer's ever-growing transcript into separate segments.
///
/// The capture plugin always reports the *whole* transcript so far. Each time
/// it commits words ([CaptureUpdate.isFinal]) the new words since the last
/// commit become one finished segment; partial updates in between grow the
/// open segment.
class TranscriptAssembler {
  TranscriptAssembler({this.maxSegmentLength = 280});

  /// Long uncommitted stretches are split at a sentence end past this length.
  final int maxSegmentLength;

  String _committed = '';
  int _counter = 0;
  Duration? _openStart;

  /// Applies an update. Returns the open or just-finished segment, or null if
  /// nothing new was said.
  TranscriptSegment? ingest(CaptureUpdate update, Duration at) {
    final full = _normalise(update.fullText);
    var tail = _tailAfterCommitted(full);

    // Split very long monologues so each part can be analysed promptly.
    var isFinal = update.isFinal;
    if (!isFinal && tail.length > maxSegmentLength) {
      final cut = _sentenceBreak(tail);
      if (cut != null) {
        final head = tail.substring(0, cut).trim();
        _committed = _normalise('$_committed $head');
        tail = head;
        isFinal = true;
      }
    }

    if (tail.isEmpty) {
      if (update.isFinal) _committed = full;
      return null;
    }

    _openStart ??= at;
    final segment = TranscriptSegment(
      id: 'seg-$_counter',
      text: tail,
      start: _openStart!,
      isFinal: isFinal,
      speaker: update.speaker,
    );

    if (isFinal) {
      if (update.isFinal) _committed = full;
      _counter++;
      _openStart = null;
    }
    return segment;
  }

  void reset() {
    _committed = '';
    _counter = 0;
    _openStart = null;
  }

  String _tailAfterCommitted(String full) {
    if (_committed.isEmpty) return full;
    if (full.startsWith(_committed)) {
      return full.substring(_committed.length).trim();
    }
    // The recognizer revised earlier words; keep what follows the longest
    // shared prefix, cut back to a word boundary.
    var i = 0;
    final max = full.length < _committed.length
        ? full.length
        : _committed.length;
    while (i < max && full.codeUnitAt(i) == _committed.codeUnitAt(i)) {
      i++;
    }
    final boundary = full.lastIndexOf(' ', i);
    final from = boundary < 0 ? i : boundary;
    return full.substring(from).trim();
  }

  static int? _sentenceBreak(String text) {
    final match = RegExp(r'[.!?]\s').allMatches(text).lastOrNull;
    return match == null ? null : match.start + 1;
  }

  static String _normalise(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');
}
