import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../domain/speech_services.dart';

/// [SpeechRecognizer] backed by the phone's own recognizer (speech_to_text).
class SpeechToTextRecognizer implements SpeechRecognizer {
  SpeechToTextRecognizer(this._speech);

  final SpeechToText _speech;
  final _levels = StreamController<double>.broadcast();
  StreamController<RecognitionUpdate>? _session;

  @override
  Stream<double> get soundLevels => _levels.stream;

  @override
  Future<bool> initialize() async {
    try {
      return await _speech.initialize(
        onStatus: _onStatus,
        onError: (e) => _session?.addError(e.errorMsg),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<RecognitionUpdate> listen({required String localeId}) {
    _session?.close();
    final controller = StreamController<RecognitionUpdate>();
    _session = controller;
    _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        if (!controller.isClosed) {
          controller.add(
            RecognitionUpdate(r.recognizedWords, isFinal: r.finalResult),
          );
          if (r.finalResult) controller.close();
        }
      },
      onSoundLevelChange: (level) =>
          _levels.add(((level + 2) / 12).clamp(0.0, 1.0)),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        autoPunctuation: true,
      ),
    );
    return controller.stream;
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      // Give a final result a moment to arrive before closing.
      Future<void>.delayed(
        const Duration(milliseconds: 400),
        () => _session?.close(),
      );
    }
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    await _speech.cancel();
    await _session?.close();
  }
}
