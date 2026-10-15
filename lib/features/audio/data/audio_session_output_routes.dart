// AudioDeviceType is marked experimental in audio_session but has been stable for years.
// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';

import '../domain/speech_services.dart';

class AudioSessionOutputRoutes implements AudioOutputRoutes {
  static const _private = {
    AudioDeviceType.wiredHeadset,
    AudioDeviceType.wiredHeadphones,
    AudioDeviceType.bluetoothA2dp,
    AudioDeviceType.bluetoothSco,
    AudioDeviceType.bluetoothLe,
    AudioDeviceType.hearingAid,
    AudioDeviceType.usbAudio,
  };

  @override
  Future<bool> hasPrivateOutput() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(includeInputs: false);
      return devices.any((d) => d.isOutput && _private.contains(d.type));
    } catch (_) {
      return false;
    }
  }
}
