import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import '../domain/speech_services.dart';

/// [SpeechSynthesizer] backed by the phone's own voice (flutter_tts).
class FlutterTtsSynthesizer implements SpeechSynthesizer {
  FlutterTtsSynthesizer(this._tts) {
    _tts.setProgressHandler(
      (text, start, end, word) => _progress.add(SpeechProgress(end)),
    );
  }

  final FlutterTts _tts;
  final _progress = StreamController<SpeechProgress>.broadcast();
  bool _configured = false;

  @override
  Stream<SpeechProgress> get progress => _progress.stream;

  @override
  Future<void> configure({required String locale}) async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(Platform.isIOS ? 0.5 : 0.48);
      await _tts.setPitch(1.0);
      if (await _tts.isLanguageAvailable(locale) == true) {
        await _tts.setLanguage(locale);
      }
      _configured = true;
    } catch (_) {
      // Fall back to the system defaults.
    }
  }

  @override
  Future<void> prepareForRecording() async {
    if (!Platform.isIOS) return;
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playAndRecord, [
      IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
    ], IosTextToSpeechAudioMode.defaultMode);
  }

  @override
  Future<void> speak(String text) async {
    if (!_configured) await configure(locale: 'en-US');
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async => _tts.stop();
}
