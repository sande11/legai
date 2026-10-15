import 'dart:math' as math;
import 'dart:typed_data';

/// Reads a PCM16 WAV file and returns [bars] peak levels between 0 and 1.
///
/// Runs on raw bytes so it can be moved to an isolate with `compute`.
List<double> wavPeaks(WavPeaksRequest request) {
  final bytes = request.bytes;
  final bars = request.bars;
  if (bytes.length < 44 || bars <= 0) return List.filled(bars, 0);
  final data = ByteData.sublistView(bytes);

  // Walk the RIFF chunks to find "fmt " and "data".
  var offset = 12;
  var channels = 1;
  var bitsPerSample = 16;
  var dataStart = -1;
  var dataLength = 0;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ' && body + 16 <= bytes.length) {
      channels = data.getUint16(body + 2, Endian.little);
      bitsPerSample = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      dataStart = body;
      dataLength = math.min(size, bytes.length - body);
      break;
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  if (dataStart < 0 || bitsPerSample != 16 || channels < 1) {
    return List.filled(bars, 0);
  }

  final frameBytes = 2 * channels;
  final frames = dataLength ~/ frameBytes;
  if (frames == 0) return List.filled(bars, 0);

  final peaks = List<double>.filled(bars, 0);
  final perBar = frames / bars;
  // Sample at most ~400 frames per bar; plenty for a visual envelope.
  for (var b = 0; b < bars; b++) {
    final from = (b * perBar).floor();
    final to = math.min(frames, ((b + 1) * perBar).ceil());
    final step = math.max(1, (to - from) ~/ 400);
    var peak = 0;
    for (var f = from; f < to; f += step) {
      final v = data.getInt16(dataStart + f * frameBytes, Endian.little).abs();
      if (v > peak) peak = v;
    }
    peaks[b] = peak / 32768;
  }

  // Normalise so quiet recordings still read clearly.
  final maxPeak = peaks.reduce(math.max);
  if (maxPeak <= 0) return peaks;
  return [for (final p in peaks) math.sqrt(p / maxPeak)];
}

class WavPeaksRequest {
  const WavPeaksRequest(this.bytes, this.bars);
  final Uint8List bytes;
  final int bars;
}
