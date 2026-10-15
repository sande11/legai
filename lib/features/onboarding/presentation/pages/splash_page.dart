import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/legai_mark.dart';
import '../../domain/usecases/resolve_start_destination.dart';

/// Brand moment while the app decides where to open.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.resolveDestination});

  final ResolveStartDestination resolveDestination;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final results = await Future.wait([
      widget.resolveDestination(const NoParams()),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    final route = switch (results.first as StartDestination) {
      StartDestination.onboarding => Routes.onboarding,
      StartDestination.login => Routes.login,
      StartDestination.home => Routes.home,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(fade),
            child: const LegaiWordmark(markSize: 44, fontSize: 40),
          ),
        ),
      ),
    );
  }
}
