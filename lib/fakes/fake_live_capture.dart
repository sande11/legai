import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../features/listen_in/domain/entities/listen_entities.dart';
import '../features/listen_in/domain/repositories/listen_repositories.dart';
import 'fake_scripts.dart';

/// Listen In without a microphone: "hears" a scripted conversation for the
/// chosen topic, word by word, in step with its recorded audio.
///
/// - Transcript updates arrive like a real recognizer's: partial words, then
///   a commit at the end of each line, with speaker labels.
/// - The level meter follows the actual audio.
/// - Stopping saves a real WAV of what was "heard", so Review can play it.
class FakeLiveCapture implements LiveCaptureRepository {
  FakeLiveCapture({
    required this._bundle,
    required this._currentTopic,
    required this._tempDir,
    this.speed = 1,
    this.tick = const Duration(milliseconds: 80),
  });

  final AssetBundle _bundle;
  final ConversationTopic? Function() _currentTopic;
  final Future<Directory> Function() _tempDir;

  /// Playback speed of the script (tests run it faster).
  final double speed;
  final Duration tick;

  final _updates = StreamController<CaptureUpdate>.broadcast();
  final _interruptions = StreamController<bool>.broadcast();
  final _clock = Stopwatch();
  final _random = math.Random(11);

  FakeScript? _script;
  FakePcm? _pcm;
  Timer? _timer;
  int _line = 0;
  int _wordsShown = 0;
  String _committed = '';

  Duration get _elapsed => _clock.elapsed * speed;

  @override
  Stream<CaptureUpdate> get updates => _updates.stream;

  @override
  Stream<bool> get interruptions => _interruptions.stream;

  @override
  Future<void> ensurePermission() async {}

  @override
  Future<void> start({required String localeId}) async {
    final script = await FakeScript.forTopic(
      _bundle,
      _currentTopic() ?? ConversationTopic.work,
    );
    _script = script;
    _pcm = await FakePcm.load(_bundle, script.audioAsset);
    _line = 0;
    _wordsShown = 0;
    _committed = '';
    _clock
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => _advance());
  }

  void _advance() {
    final script = _script;
    if (script == null) return;
    final t = _elapsed;
    while (_line < script.lines.length) {
      final line = script.lines[_line];
      if (t < line.start) return;
      if (t >= line.end) {
        _committed = _join(_committed, line.text);
        _updates.add(
          CaptureUpdate(_committed, isFinal: true, speaker: line.speaker),
        );
        _line++;
        _wordsShown = 0;
        continue;
      }
      final words = line.text.split(' ');
      final progress =
          (t - line.start).inMilliseconds /
          (line.end - line.start).inMilliseconds;
      final shown = (progress * words.length).ceil().clamp(1, words.length);
      if (shown != _wordsShown) {
        _wordsShown = shown;
        _updates.add(
          CaptureUpdate(
            _join(_committed, words.take(shown).join(' ')),
            isFinal: false,
            speaker: line.speaker,
          ),
        );
      }
      return;
    }
  }

  static String _join(String a, String b) => a.isEmpty ? b : '$a $b';

  @override
  Future<double> level() async {
    final pcm = _pcm;
    if (pcm == null || !_clock.isRunning) return 0;
    final center = (_elapsed.inMilliseconds * pcm.sampleRate) ~/ 1000;
    final from = math.max(0, center - pcm.sampleRate ~/ 10);
    final to = math.min(pcm.samples.length, center + pcm.sampleRate ~/ 10);
    if (to <= from) return 0.03 + _random.nextDouble() * 0.04;
    var sum = 0.0;
    for (var i = from; i < to; i += 4) {
      final v = pcm.samples[i] / 32768;
      sum += v * v;
    }
    final rms = math.sqrt(sum / ((to - from) / 4));
    return (rms * 6).clamp(0.03, 1.0);
  }

  @override
  Future<void> pause() async => _clock.stop();

  @override
  Future<void> resume() async => _clock.start();

  @override
  Future<String?> stop() async {
    _timer?.cancel();
    _clock.stop();
    final pcm = _pcm;
    if (pcm == null) return null;
    final dir = await _tempDir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}legai-demo-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(pcm.toWav(length: _elapsed), flush: true);
    return file.path;
  }

  @override
  Future<void> cancel() async {
    _timer?.cancel();
    _clock
      ..stop()
      ..reset();
  }
}
