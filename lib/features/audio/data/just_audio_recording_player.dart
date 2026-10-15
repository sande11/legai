import 'package:just_audio/just_audio.dart';

import '../domain/speech_services.dart';

class JustAudioRecordingPlayer implements RecordingPlayer {
  JustAudioRecordingPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<Duration?> load(String path) => _player.setFilePath(path);

  @override
  Future<void> play() async {
    // just_audio's play() completes when playback finishes; don't wait.
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<bool> get playing => _player.playerStateStream
      .map((s) => s.playing && s.processingState != ProcessingState.completed)
      .distinct();

  @override
  Future<void> dispose() => _player.dispose();
}
