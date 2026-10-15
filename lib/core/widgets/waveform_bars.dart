import 'package:flutter/material.dart';

import '../theme/legai_colors.dart';

enum WaveBarTone { idle, played, flagged }

/// One bar of a waveform: [level] is 0–1.
class WaveBar {
  const WaveBar(
    this.level, {
    this.tone = WaveBarTone.idle,
    this.marker = false,
  });

  final double level;
  final WaveBarTone tone;

  /// Draws a gold dot above the bar (start of a flagged moment).
  final bool marker;
}

/// Rounded vertical bars, used for the live meter and the review player.
class WaveformBars extends StatelessWidget {
  const WaveformBars({
    super.key,
    required this.bars,
    required this.height,
    this.barWidth = 3,
    this.minBarHeight = 4,
    this.playhead,
    this.markers = const [],
    this.onSeek,
  });

  final List<WaveBar> bars;
  final double height;
  final double barWidth;
  final double minBarHeight;

  /// 0–1 position of a thin playhead line, if any.
  final double? playhead;

  /// 0–1 positions of flag markers drawn above the bars (review player).
  final List<WaveMarker> markers;

  /// Called with a 0–1 position when the user taps or drags.
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final painter = _WaveformPainter(
      bars: bars,
      barWidth: barWidth,
      minBarHeight: minBarHeight,
      idle: c.wave,
      played: c.waveOn,
      flagged: c.gold,
      playheadColor: c.text,
      markerRing: c.bg,
      playhead: playhead,
      markers: markers,
    );
    final paint = CustomPaint(
      size: Size(double.infinity, height),
      painter: painter,
    );
    if (onSeek == null) return ExcludeSemantics(child: paint);
    return LayoutBuilder(
      builder: (context, constraints) {
        void seek(double dx) =>
            onSeek!((dx / constraints.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => seek(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => seek(d.localPosition.dx),
          child: ExcludeSemantics(child: paint),
        );
      },
    );
  }
}

class WaveMarker {
  const WaveMarker(this.position, {this.emphasised = false});
  final double position;
  final bool emphasised;
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.barWidth,
    required this.minBarHeight,
    required this.idle,
    required this.played,
    required this.flagged,
    required this.playheadColor,
    required this.markerRing,
    required this.playhead,
    required this.markers,
  });

  final List<WaveBar> bars;
  final double barWidth;
  final double minBarHeight;
  final Color idle;
  final Color played;
  final Color flagged;
  final Color playheadColor;
  final Color markerRing;
  final double? playhead;
  final List<WaveMarker> markers;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final n = bars.length;
    final gap = n > 1 ? (size.width - n * barWidth) / (n - 1) : 0.0;
    final paint = Paint()..isAntiAlias = true;
    final centerY = size.height / 2;
    final maxH = size.height - 14; // room for markers

    for (var i = 0; i < n; i++) {
      final bar = bars[i];
      final h =
          (minBarHeight + (maxH - minBarHeight) * bar.level.clamp(0.0, 1.0));
      final x = i * (barWidth + gap);
      paint.color = switch (bar.tone) {
        WaveBarTone.flagged => flagged,
        WaveBarTone.played => played,
        WaveBarTone.idle => idle,
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - h / 2, barWidth, h),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
      if (bar.marker) {
        canvas.drawCircle(
          Offset(x + barWidth / 2, centerY - h / 2 - 8),
          3.5,
          Paint()..color = flagged,
        );
      }
    }

    for (final m in markers) {
      final x = m.position.clamp(0.0, 1.0) * size.width;
      final r = m.emphasised ? 5.0 : 3.5;
      canvas.drawCircle(Offset(x, 4), r + 3, Paint()..color = markerRing);
      canvas.drawCircle(Offset(x, 4), r, Paint()..color = flagged);
    }

    final ph = playhead;
    if (ph != null) {
      final x = ph.clamp(0.0, 1.0) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 1, 0, 2, size.height),
          const Radius.circular(1),
        ),
        Paint()..color = playheadColor,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}
