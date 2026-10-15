import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../features/listen_in/domain/entities/listen_entities.dart';

/// One line of a scripted conversation, timed against its audio.
class FakeLine {
  const FakeLine({
    required this.speaker,
    required this.text,
    required this.start,
    required this.end,
  });

  final String speaker;
  final String text;
  final Duration start;
  final Duration end;
}

/// A scripted conversation for one Listen In topic, with recorded audio.
///
/// `assets/fakes/scripts.json` and the WAV files in `assets/fakes/audio/`
/// were generated together, so line timings match the audio.
class FakeScript {
  const FakeScript({
    required this.title,
    required this.audioAsset,
    required this.length,
    required this.lines,
  });

  final String title;
  final String audioAsset;
  final Duration length;
  final List<FakeLine> lines;

  static Map<String, FakeScript>? _cache;

  static Future<FakeScript> forTopic(
    AssetBundle bundle,
    ConversationTopic topic,
  ) async {
    final all = _cache ??= _parse(
      await bundle.loadString('assets/fakes/scripts.json'),
    );
    return all[topic.name] ?? all[ConversationTopic.work.name]!;
  }

  static Map<String, FakeScript> _parse(String raw) {
    final json = (jsonDecode(raw) as Map).cast<String, Object?>();
    return json.map((key, value) {
      final s = (value! as Map).cast<String, Object?>();
      return MapEntry(
        key,
        FakeScript(
          title: s['title']! as String,
          audioAsset: s['audio']! as String,
          length: Duration(milliseconds: (s['durationMs']! as num).toInt()),
          lines: [
            for (final l in (s['lines']! as List).cast<Map>())
              FakeLine(
                speaker: l['speaker'] as String,
                text: l['text'] as String,
                start: Duration(milliseconds: (l['startMs'] as num).toInt()),
                end: Duration(milliseconds: (l['endMs'] as num).toInt()),
              ),
          ],
        ),
      );
    });
  }
}

/// 16-bit mono PCM from a WAV file.
class FakePcm {
  const FakePcm(this.samples, this.sampleRate);

  final Int16List samples;
  final int sampleRate;

  static Future<FakePcm> load(AssetBundle bundle, String asset) async {
    final data = await bundle.load(asset);
    return decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  static FakePcm decode(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    var offset = 12;
    var rate = 8000;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = view.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') rate = view.getUint32(body + 4, Endian.little);
      if (id == 'data') {
        final count = (size.clamp(0, bytes.length - body)) ~/ 2;
        final samples = Int16List(count);
        for (var i = 0; i < count; i++) {
          samples[i] = view.getInt16(body + i * 2, Endian.little);
        }
        return FakePcm(samples, rate);
      }
      offset = body + size + (size.isOdd ? 1 : 0);
    }
    return FakePcm(Int16List(0), rate);
  }

  /// A WAV file holding the first [length] of audio, padded with silence.
  Uint8List toWav({Duration? length}) {
    final count = length == null
        ? samples.length
        : (length.inMilliseconds * sampleRate) ~/ 1000;
    final out = ByteData(44 + count * 2);
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        out.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    out.setUint32(4, 36 + count * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    out
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    out.setUint32(40, count * 2, Endian.little);
    for (var i = 0; i < count; i++) {
      out.setInt16(
        44 + i * 2,
        i < samples.length ? samples[i] : 0,
        Endian.little,
      );
    }
    return out.buffer.asUint8List();
  }
}
