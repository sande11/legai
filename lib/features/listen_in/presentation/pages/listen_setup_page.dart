import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/particle_orb.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/listen_entities.dart';
import '../bloc/live_listen_bloc.dart';
import '../cubit/listen_setup_cubit.dart';

/// "Before you start": consent reminder, topic, announce and whisper.
class ListenSetupPage extends StatefulWidget {
  const ListenSetupPage({super.key});

  @override
  State<ListenSetupPage> createState() => _ListenSetupPageState();
}

class _ListenSetupPageState extends State<ListenSetupPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheet = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void initState() {
    super.initState();
    context.read<ListenSetupCubit>().refreshOutput();
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final live = context.read<LiveListenBloc>();
    if (live.state.isActive) {
      Navigator.of(context).pushReplacementNamed(Routes.listenLive);
      return;
    }
    final setup = await context.read<ListenSetupCubit>().confirm();
    if (setup == null || !mounted) return;
    live.add(LiveStarted(setup));
    Navigator.of(context).pushReplacementNamed(Routes.listenLive);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final place = context.select((SettingsCubit s) => s.state.jurisdiction);
    final curve = CurvedAnimation(parent: _sheet, curve: Curves.easeOutCubic);

    return BlocListener<ListenSetupCubit, ListenSetupState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, s) =>
          showErrorDialog(context, s.error!, title: 'Microphone needed'),
      child: Scaffold(
        body: Stack(
          children: [
            // Backdrop: the idle Listen In screen.
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('Listen in', style: context.text.titleMedium),
                    const SizedBox(height: 20),
                    const ParticleOrb(
                      size: 220,
                      dotCount: 320,
                      amplitude: 0.04,
                      speed: 0.6,
                    ),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: curve,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(color: c.scrim),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curve),
                child: _Sheet(
                  placeName: place.name,
                  ruleSummary: place.recordingRuleSummary,
                  onStart: _start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.placeName,
    required this.ruleSummary,
    required this.onStart,
  });
  final String placeName;
  final String? ruleSummary;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<ListenSetupCubit>().state;
    final cubit = context.read<ListenSetupCubit>();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Before you start',
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: c.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Before you start',
                        style: context.text.headlineLarge,
                      ),
                    ),
                    CircleIconButton(
                      icon: LucideIcons.x,
                      label: 'Close',
                      iconSize: 18,
                      background: c.surface2,
                      borderColor: Colors.transparent,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Recording rules differ from place to place. Make sure everyone in the conversation knows LegAI is listening.',
                  style: context.text.bodySmall?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconDisc(icon: LucideIcons.shield, gold: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Recording rule · $placeName',
                                    style: context.text.labelMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(Routes.settings),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(44, 32),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                            Text(
                              ruleSummary ??
                                  'Check the rule where you are, and tell everyone before you record. LegAI can announce it for you.',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'What\'s this conversation about?',
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final t in ConversationTopic.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoicePill(
                            label: t.label,
                            selected: state.topic == t,
                            onTap: () => cubit.selectTopic(t),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ToggleRow(
                  icon: LucideIcons.volume2,
                  title: 'Announce the recording',
                  subtitle: state.privateOutput
                      ? 'Earbuds are connected, so you\'ll be asked to say it yourself.'
                      : 'LegAI says "This conversation is being recorded."',
                  value: state.announce,
                  onChanged: cubit.setAnnounce,
                ),
                _ToggleRow(
                  icon: LucideIcons.headphones,
                  title: 'Whisper advice to my earbuds',
                  subtitle: state.privateOutput
                      ? 'Only you hear it · Earbuds connected'
                      : 'Only you hear it · Connect earbuds to use this',
                  value: state.whisper,
                  onChanged: cubit.setWhisper,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const _IconDisc(icon: LucideIcons.lock),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved on this phone',
                              style: context.text.titleSmall,
                            ),
                            Text(
                              'The recording stays on your device. You choose what to share.',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'Start listening',
                  icon: LucideIcons.mic,
                  height: 56,
                  loading: state.checking,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.icon, this.gold = false});
  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: gold ? c.goldSoft : c.surface2,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: gold ? c.goldIcon : c.text),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _IconDisc(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
