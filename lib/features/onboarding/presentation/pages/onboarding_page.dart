import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/legai_mark.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/particle_orb.dart';
import '../../domain/usecases/resolve_start_destination.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.completeOnboarding});

  final CompleteOnboarding completeOnboarding;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final next = await widget.completeOnboarding(const NoParams());
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      next == StartDestination.home ? Routes.home : Routes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LegaiWordmark(),
              const Spacer(),
              const Center(child: ParticleOrb(size: 240, dotCount: 380)),
              const Spacer(),
              FadeSlideIn(
                child: Text(
                  'Know your rights,\nin the moment.',
                  style: context.text.displayMedium,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  'Ask a legal question, talk it through, or let LegAI listen in to a conversation and flag what matters.',
                  style: context.text.bodyLarge?.copyWith(color: c.muted),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _Feature(icon: LucideIcons.messageSquare, label: 'Ask'),
                    _Feature(icon: LucideIcons.audioLines, label: 'Talk'),
                    _Feature(icon: LucideIcons.mic, label: 'Listen in'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GoldButton(
                label: 'Get started',
                loading: _busy,
                onPressed: _start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.goldIcon),
          const SizedBox(width: 8),
          Text(label, style: context.text.labelMedium),
        ],
      ),
    );
  }
}
