import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/particle_orb.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../bloc/voice_bloc.dart';

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  bool _captions = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final place = context.select((SettingsCubit s) => s.state.jurisdiction);
    final size = MediaQuery.sizeOf(context);
    final orbSize =
        (size.width * 0.78 < size.height * 0.38
                ? size.width * 0.78
                : size.height * 0.38)
            .clamp(160.0, 340.0);

    return BlocBuilder<VoiceBloc, VoiceState>(
      builder: (context, state) {
        final (amp, radius, speed, energy) = switch (state.status) {
          VoiceStatus.listening => (0.065, 1.0, 1.0, state.level),
          VoiceStatus.thinking => (0.025, 0.9, 0.5, 0.0),
          VoiceStatus.speaking => (0.09, 1.0, 1.2, 0.35),
          _ => (0.04, 0.95, 0.7, 0.0),
        };
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: LucideIcons.chevronLeft,
                        label: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Talk', style: context.text.titleMedium),
                            Text(
                              '${place.name} law · English',
                              style: context.text.labelSmall?.copyWith(
                                color: c.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        toggled: _captions,
                        label: 'Captions',
                        child: ExcludeSemantics(
                          child: Material(
                            color: _captions ? c.surface : Colors.transparent,
                            shape: CircleBorder(
                              side: BorderSide(color: c.line),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _captions = !_captions),
                              child: SizedBox.square(
                                dimension: 44,
                                child: Center(
                                  child: Text(
                                    'CC',
                                    style: context.text.labelSmall?.copyWith(
                                      color: _captions ? c.text : c.muted,
                                      decoration: _captions
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                ParticleOrb(
                  size: orbSize,
                  dotCount: 520,
                  amplitude: amp,
                  radiusFactor: radius,
                  speed: speed,
                  energy: energy,
                ),
                const SizedBox(height: 12),
                _StatusPill(status: state.status),
                const SizedBox(height: 20),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedOpacity(
                      opacity: _captions ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: SingleChildScrollView(
                        reverse: true,
                        child: _Caption(state: state, placeName: place.name),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _hint(state),
                    key: ValueKey(_hint(state)),
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleIconButton(
                        icon: LucideIcons.keyboard,
                        label: 'Switch to typing',
                        size: 56,
                        iconSize: 22,
                        onPressed: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(Routes.chat),
                      ),
                      const SizedBox(width: 22),
                      PulseRings(
                        active: state.status == VoiceStatus.listening,
                        child: _MicButton(status: state.status),
                      ),
                      const SizedBox(width: 22),
                      CircleIconButton(
                        icon: LucideIcons.x,
                        label: 'End conversation',
                        size: 56,
                        iconSize: 22,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _hint(VoiceState s) =>
      s.message ??
      switch (s.status) {
        VoiceStatus.initializing => 'Getting ready…',
        VoiceStatus.listening => 'Tap the mic when you have finished',
        VoiceStatus.thinking => 'One moment',
        VoiceStatus.speaking => 'Tap to interrupt',
        VoiceStatus.idle => 'Tap the mic to ask another question',
        VoiceStatus.unavailable => 'Tap the mic to try again',
      };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final VoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = switch (status) {
      VoiceStatus.initializing => 'Starting',
      VoiceStatus.listening => 'Listening',
      VoiceStatus.thinking => 'Thinking',
      VoiceStatus.speaking => 'Speaking',
      VoiceStatus.idle => 'Ready',
      VoiceStatus.unavailable => 'Microphone off',
    };
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: ShapeDecoration(
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulsingDot(
              color: c.gold,
              size: 8,
              active:
                  status == VoiceStatus.listening ||
                  status == VoiceStatus.speaking,
            ),
            const SizedBox(width: 8),
            Text(label, style: context.text.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.state, required this.placeName});
  final VoiceState state;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text.headlineSmall!;
    final faint = style.copyWith(color: c.faint);

    TextSpan span;
    switch (state.status) {
      case VoiceStatus.thinking:
        span = TextSpan(
          text: 'Checking $placeName law…',
          style: style.copyWith(color: c.muted),
        );
      case VoiceStatus.speaking || VoiceStatus.idle when state.answer != null:
        final text = state.answer!.spokenText;
        final end = state.status == VoiceStatus.idle
            ? text.length
            : state.spokenEnd.clamp(0, text.length);
        span = TextSpan(
          children: [
            TextSpan(text: text.substring(0, end), style: style),
            TextSpan(text: text.substring(end), style: faint),
          ],
        );
      case VoiceStatus.listening when state.heard.isNotEmpty:
        final words = state.heard.trim().split(' ');
        final tail = words.length > 3
            ? words.sublist(words.length - 3).join(' ')
            : '';
        final head = words.length > 3
            ? words.sublist(0, words.length - 3).join(' ')
            : state.heard;
        span = TextSpan(
          children: [
            TextSpan(text: head, style: style),
            if (tail.isNotEmpty) TextSpan(text: ' $tail…', style: faint),
          ],
        );
      case VoiceStatus.listening:
        span = TextSpan(text: 'Go ahead, I\'m listening.', style: faint);
      default:
        span = TextSpan(text: 'Ask your question out loud.', style: faint);
    }
    return Text.rich(span, textAlign: TextAlign.center);
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.status});
  final VoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, label) = switch (status) {
      VoiceStatus.listening => (LucideIcons.square, 'Finish speaking'),
      VoiceStatus.speaking => (LucideIcons.pause, 'Interrupt'),
      VoiceStatus.thinking => (LucideIcons.ellipsis, 'Thinking'),
      _ => (LucideIcons.mic, 'Start speaking'),
    };
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.gold,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.read<VoiceBloc>().add(const VoiceMicPressed()),
          child: SizedBox.square(
            dimension: 80,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(icon, key: ValueKey(icon), size: 30, color: c.onGold),
            ),
          ),
        ),
      ),
    );
  }
}
