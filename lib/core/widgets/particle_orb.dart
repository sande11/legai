import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/legai_colors.dart';

/// The gold particle sphere used for voice and Listen In.
///
/// Dots sit on a Fibonacci sphere that slowly rotates. [amplitude] sets how
/// much the surface ripples and [energy] (0–1, e.g. the microphone level)
/// adds a livelier shimmer on top. Both changes are eased, so the orb never
/// jumps between states.
class ParticleOrb extends StatefulWidget {
  const ParticleOrb({
    super.key,
    required this.size,
    this.dotCount = 420,
    this.amplitude = 0.065,
    this.energy = 0,
    this.radiusFactor = 1,
    this.dotScale = 1,
    this.speed = 1,
    this.color,
    this.glowColor,
    this.animate = true,
  });

  final double size;
  final int dotCount;
  final double amplitude;
  final double energy;

  /// Shrinks or grows the sphere inside its box (0–1.1).
  final double radiusFactor;
  final double dotScale;

  /// 1 = one full rotation every 14 s.
  final double speed;
  final Color? color;
  final Color? glowColor;
  final bool animate;

  @override
  State<ParticleOrb> createState() => _ParticleOrbState();
}

class _ParticleOrbState extends State<ParticleOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(ParticleOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _controller.duration = Duration(
        milliseconds: (14000 / widget.speed.clamp(0.1, 4)).round(),
      );
    }
    _syncTicker();
  }

  void _syncTicker() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shouldRun = widget.animate && !reduceMotion;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<_OrbParams>(
          tween: _OrbParamsTween(
            end: _OrbParams(
              widget.amplitude,
              widget.energy.clamp(0, 1).toDouble(),
              widget.radiusFactor,
            ),
          ),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          builder: (context, params, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _OrbPainter(
              phase: _controller,
              dotCount: widget.dotCount,
              color: widget.color ?? c.dot,
              glow: widget.glowColor ?? c.glow,
              amplitude: params.amplitude,
              energy: params.energy,
              radiusFactor: params.radius,
              dotScale: widget.dotScale,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbParams {
  const _OrbParams(this.amplitude, this.energy, this.radius);
  final double amplitude;
  final double energy;
  final double radius;

  @override
  bool operator ==(Object other) =>
      other is _OrbParams &&
      other.amplitude == amplitude &&
      other.energy == energy &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(amplitude, energy, radius);
}

class _OrbParamsTween extends Tween<_OrbParams> {
  _OrbParamsTween({required super.end});

  @override
  _OrbParams lerp(double t) {
    final b = begin ?? end!;
    final e = end!;
    double l(double x, double y) => x + (y - x) * t;
    return _OrbParams(
      l(b.amplitude, e.amplitude),
      l(b.energy, e.energy),
      l(b.radius, e.radius),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.phase,
    required this.dotCount,
    required this.color,
    required this.glow,
    required this.amplitude,
    required this.energy,
    required this.radiusFactor,
    required this.dotScale,
  }) : super(repaint: phase);

  final Animation<double> phase;
  final int dotCount;
  final Color color;
  final Color glow;
  final double amplitude;
  final double energy;
  final double radiusFactor;
  final double dotScale;

  static final Map<int, _SphereBase> _cache = {};
  static const double _tilt = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final base = _cache.putIfAbsent(dotCount, () => _SphereBase(dotCount));
    final center = size.center(Offset.zero);
    final half = size.shortestSide / 2;
    final radius = half * 0.76 * radiusFactor;

    // Soft glow behind the sphere.
    canvas.drawCircle(
      center,
      half * 0.86,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, glow.withValues(alpha: 0)],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: half * 0.86)),
    );

    final p = phase.value * 2 * math.pi;
    final cosT = math.cos(_tilt);
    final sinT = math.sin(_tilt);
    final dotUnit = math.max(size.shortestSide / 300, 0.72);
    final paint = Paint()..isAntiAlias = true;

    for (var i = 0; i < dotCount; i++) {
      final y0 = base.y[i];
      final rr = base.r[i];
      final th = base.theta[i] + p;
      final x = math.cos(th) * rr;
      final z = math.sin(th) * rr;
      final y1 = y0 * cosT - z * sinT;
      final z1 = y0 * sinT + z * cosT;
      final wobble =
          1 +
          amplitude * math.sin(3 * th + 4 * y0 + 2 * p) +
          amplitude * 0.7 * math.cos(5 * y0 - p) +
          energy * 0.09 * math.sin(7 * th + 3 * p);
      final depth = (z1 + 1) / 2;
      final dot = (0.45 + depth * 0.95) * dotUnit * dotScale * 1.2;
      paint.color = color.withValues(alpha: 0.12 + depth * 0.88);
      canvas.drawCircle(
        Offset(
          center.dx + x * radius * wobble,
          center.dy + y1 * radius * wobble,
        ),
        dot,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.amplitude != amplitude ||
      old.energy != energy ||
      old.radiusFactor != radiusFactor ||
      old.color != color ||
      old.glow != glow ||
      old.dotCount != dotCount ||
      old.dotScale != dotScale;
}

/// Fibonacci-sphere positions, computed once per dot count.
class _SphereBase {
  _SphereBase(int n)
    : y = List.filled(n, 0),
      r = List.filled(n, 0),
      theta = List.filled(n, 0) {
    final golden = math.pi * (3 - math.sqrt(5));
    for (var i = 0; i < n; i++) {
      final y0 = 1 - (2 * (i + 0.5)) / n;
      y[i] = y0;
      r[i] = math.sqrt(1 - y0 * y0);
      theta[i] = golden * i;
    }
  }

  final List<double> y;
  final List<double> r;
  final List<double> theta;
}
