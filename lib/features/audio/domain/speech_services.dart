import 'package:equatable/equatable.dart';

/// A recognition result: the words heard so far in this listen session.
class RecognitionUpdate extends Equatable {
  const RecognitionUpdate(this.text, {required this.isFinal});
  final String text;
  final bool isFinal;

  @override
  List<Object?> get props => [text, isFinal];
}

/// Push-to-talk speech recognition (Talk screen).
abstract interface class SpeechRecognizer {
  /// Asks for microphone/speech permission. False if speech recognition is
  /// unavailable or permission was refused.
  Future<bool> initialize();

  /// Starts listening. The stream ends when recognition stops (after a
  /// pause, [stop] or [cancel]).
  Stream<RecognitionUpdate> listen({required String localeId});

  /// Microphone level, 0–1, while listening.
  Stream<double> get soundLevels;

  Future<void> stop();
  Future<void> cancel();
}

/// Where the speaker is in the text, for highlighting spoken words.
class SpeechProgress extends Equatable {
  const SpeechProgress(this.end);

  /// Character offset just past the word being spoken.
  final int end;

  @override
  List<Object?> get props => [end];
}

/// Text to speech.
abstract interface class SpeechSynthesizer {
  Future<void> configure({required String locale});

  /// Lets speech play while the microphone is recording (Listen In).
  Future<void> prepareForRecording();

  /// Completes when the text has been spoken (or [stop] is called).
  Future<void> speak(String text);

  Future<void> stop();

  Stream<SpeechProgress> get progress;
}

/// Audio output routes.
abstract interface class AudioOutputRoutes {
  /// True when wired or Bluetooth headphones are connected, so a whisper
  /// won't be heard by the other people in the room.
  Future<bool> hasPrivateOutput();
}

/// Plays a saved recording (Review screen).
abstract interface class RecordingPlayer {
  /// Returns the recording's length, if known.
  Future<Duration?> load(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Stream<Duration> get position;
  Stream<bool> get playing;
  Future<void> dispose();
}
