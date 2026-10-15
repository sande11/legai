import 'dart:async';
import 'dart:math' as math;

import '../features/audio/domain/speech_services.dart';

/// A person asking questions out loud, word by word.
///
/// Each time Talk starts listening, the next question in [questions] is
/// "heard". Tapping the mic early finishes the sentence at once.
class FakeSpeechRecognizer implements SpeechRecognizer {
  FakeSpeechRecognizer({
    this.questions = defaultQuestions,
    this.wordInterval = const Duration(milliseconds: 280),
    this.leadIn = const Duration(milliseconds: 700),
  });

  static const defaultQuestions = [
    'My employer wants me to sign a new contract with a lower salary. Can they do that?',
    'The police called and asked me to come to the station to answer a few questions. Do I have to say anything?',
    'Can I bring someone with me?',
    'My landlord is keeping my deposit for wear and tear. Can he do that?',
  ];

  final List<String> questions;
  final Duration wordInterval;
  final Duration leadIn;

  final _levels = StreamController<double>.broadcast();
  final _random = math.Random(3);
  StreamController<RecognitionUpdate>? _session;
  Timer? _timer;
  List<String> _words = const [];
  int _shown = 0;
  int _next = 0;

  @override
  Stream<double> get soundLevels => _levels.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  Stream<RecognitionUpdate> listen({required String localeId}) {
    _finish(emitFinal: false);
    final session = StreamController<RecognitionUpdate>();
    _session = session;
    _words = questions[_next++ % questions.length].split(' ');
    _shown = 0;
    _timer = Timer(leadIn, () {
      _timer = Timer.periodic(wordInterval, (_) {
        if (_shown >= _words.length) {
          _finish(emitFinal: true);
          return;
        }
        _shown++;
        _levels.add(0.35 + _random.nextDouble() * 0.6);
        session.add(
          RecognitionUpdate(_words.take(_shown).join(' '), isFinal: false),
        );
      });
    });
    return session.stream;
  }

  void _finish({required bool emitFinal}) {
    _timer?.cancel();
    _timer = null;
    final session = _session;
    _session = null;
    if (session == null || session.isClosed) return;
    if (emitFinal && _words.isNotEmpty) {
      session.add(RecognitionUpdate(_words.join(' '), isFinal: true));
    }
    _levels.add(0);
    session.close();
  }

  @override
  Future<void> stop() async => _finish(emitFinal: true);

  @override
  Future<void> cancel() async => _finish(emitFinal: false);
}

/// Speaks with word-by-word progress, so captions highlight as they would
/// with a real voice. If a real [voice] is given it is played as well (and
/// any failure, e.g. no TTS engine on a simulator, is ignored).
class FakeSpeechSynthesizer implements SpeechSynthesizer {
  FakeSpeechSynthesizer({
    this.voice,
    this.wordDuration = const Duration(milliseconds: 360),
  });

  final SpeechSynthesizer? voice;
  final Duration wordDuration;

  final _progress = StreamController<SpeechProgress>.broadcast();
  Timer? _timer;
  Completer<void>? _done;

  /// Everything spoken, for checks in tests.
  final spoken = <String>[];

  @override
  Stream<SpeechProgress> get progress => _progress.stream;

  @override
  Future<void> configure({required String locale}) async {
    try {
      await voice?.configure(locale: locale);
    } catch (_) {}
  }

  @override
  Future<void> prepareForRecording() async {
    try {
      await voice?.prepareForRecording();
    } catch (_) {}
  }

  @override
  Future<void> speak(String text) {
    _end();
    spoken.add(text);
    final done = Completer<void>();
    _done = done;
    final words = RegExp(r'\S+').allMatches(text).toList();
    var i = 0;
    _timer = Timer.periodic(wordDuration, (_) {
      if (i >= words.length) {
        _end();
        return;
      }
      _progress.add(SpeechProgress(words[i].end));
      i++;
    });
    final v = voice;
    if (v != null) unawaited(v.speak(text).catchError((Object _) {}));
    return done.future;
  }

  void _end() {
    _timer?.cancel();
    _timer = null;
    final done = _done;
    _done = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  @override
  Future<void> stop() async {
    _end();
    try {
      await voice?.stop();
    } catch (_) {}
  }
}

/// Always reports earbuds as connected, so whispered advice is shown.
class FakeOutputRoutes implements AudioOutputRoutes {
  @override
  Future<bool> hasPrivateOutput() async => true;
}
