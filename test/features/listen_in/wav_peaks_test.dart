import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/listen_in/data/datasources/wav_peaks.dart';

/// Builds a 16 kHz mono PCM16 WAV: half silence, then a loud tone.
Uint8List _wav({int seconds = 2}) {
  const rate = 16000;
  final frames = rate * seconds;
  final data = ByteData(44 + frames * 2);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, rate, Endian.little)
    ..setUint32(28, rate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (var f = 0; f < frames; f++) {
    final v = f < frames / 2 ? 0 : (math.sin(f / 8) * 20000).round();
    data.setInt16(44 + f * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('quiet first half, loud second half', () {
    final peaks = wavPeaks(WavPeaksRequest(_wav(), 10));
    expect(peaks, hasLength(10));
    expect(peaks.take(4).every((p) => p < 0.05), isTrue);
    expect(peaks.skip(6).every((p) => p > 0.9), isTrue);
  });

  test('returns zeros for something that is not a WAV', () {
    expect(wavPeaks(WavPeaksRequest(Uint8List(10), 5)), everyElement(0));
  });
}
