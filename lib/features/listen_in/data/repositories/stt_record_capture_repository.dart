import 'dart:async';

import 'package:flutter/services.dart';
import 'package:stt_record/stt_record.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/listen_repositories.dart';

/// [LiveCaptureRepository] using the `stt_record` plugin, which records a
/// WAV file and runs the phone's speech recognizer from the same microphone
/// stream (so the two don't fight over the mic).
class SttRecordCaptureRepository implements LiveCaptureRepository {
  SttRecordCaptureRepository(this._plugin);

  final SttRecord _plugin;

  @override
  Stream<CaptureUpdate> get updates =>
      _plugin.transcripts.map((t) => CaptureUpdate(t.text, isFinal: t.isFinal));

  @override
  Stream<bool> get interruptions =>
      _plugin.sessionStates.map((s) => s == SttRecordSessionState.paused);

  @override
  Future<void> ensurePermission() async {
    final granted =
        await _plugin.hasPermission() || await _plugin.requestPermission();
    if (!granted) {
      throw const PermissionFailure(
        'LegAI needs the microphone (and speech recognition on iPhone) to listen in. You can allow it in Settings.',
      );
    }
  }

  @override
  Future<void> start({required String localeId}) async {
    try {
      await _plugin.start(
        localeId: localeId,
        partialResults: true,
        enableSystemNotification: true,
        systemNotificationTitle: 'LegAI is listening',
        systemNotificationBody: 'Recording on this phone',
        enableSystemNotificationActionPause: true,
      );
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') {
        throw const PermissionFailure(
          'Microphone access is off. Allow it in Settings to use Listen In.',
        );
      }
      if (e.code == 'stt_unavailable') {
        throw const SpeechUnavailableFailure(
          'This phone has no speech recognition service available.',
        );
      }
      throw SpeechUnavailableFailure(e.message ?? 'Couldn\'t start listening.');
    }
  }

  @override
  Future<double> level() async {
    try {
      return (await _plugin.getAmplitude()).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> pause() => _plugin.pause();

  @override
  Future<void> resume() => _plugin.resume();

  @override
  Future<String?> stop() async {
    try {
      return (await _plugin.stop()).audioPath;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancel() => _plugin.cancel();
}
