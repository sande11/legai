import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/particle_orb.dart';
import '../../../listen_in/presentation/bloc/live_listen_bloc.dart';
import '../../domain/entities/recent_activity.dart';

/// The headline feature card on Home.
class ListenInCard extends StatelessWidget {
  const ListenInCard({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.line),
        boxShadow: c.cardShadow.length > 1 ? c.cardShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: c.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE ADVICE',
                          style: context.text.labelSmall?.copyWith(
                            color: c.goldText,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Listen in', style: context.text.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      'LegAI follows a live conversation, keeps the recording on this phone, and flags what matters as it happens.',
                      style: context.text.bodySmall?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ParticleOrb(
                size: 96,
                dotCount: 190,
                amplitude: 0.07,
                dotScale: 1.5,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Start listening',
            icon: LucideIcons.mic,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// "Ask" and "Talk" tiles.
class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.goldSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: c.goldIcon),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.arrowUpRight, size: 18, color: c.muted),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleMedium),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentTile extends StatelessWidget {
  const RecentTile({super.key, required this.item, this.showDivider = true});
  final RecentActivity item;
  final bool showDivider;

  void _open(BuildContext context) {
    switch (item.kind) {
      case ActivityKind.listenIn:
        Navigator.of(
          context,
        ).pushNamed(Routes.review, arguments: ReviewArgs(item.id));
      case ActivityKind.ask:
      case ActivityKind.talk:
        Navigator.of(
          context,
        ).pushNamed(Routes.chat, arguments: ChatArgs(conversationId: item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, kindLabel) = switch (item.kind) {
      ActivityKind.listenIn => (LucideIcons.mic, 'Listen in'),
      ActivityKind.ask => (LucideIcons.messageSquare, 'Ask'),
      ActivityKind.talk => (LucideIcons.audioLines, 'Talk'),
    };
    final meta = [
      kindLabel,
      if (item.length != null) formatLength(item.length!),
      formatRelativeDay(item.date),
    ].join(' · ');

    return InkWell(
      onTap: () => _open(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: c.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: c.goldIcon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  Text(meta, style: context.text.bodySmall),
                ],
              ),
            ),
            if (item.flagCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color: c.goldSoft,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '${item.flagCount} ${item.flagCount == 1 ? 'flag' : 'flags'}',
                  style: context.text.labelSmall?.copyWith(color: c.goldText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating pill navigation: Home, Sessions, Listen in, Settings.
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.current});

  /// Route of the page showing the nav.
  final String current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(IconData icon, String label, String route) {
      final selected = current == route;
      return Tooltip(
        message: label,
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: selected
                ? c.navText.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: selected
                  ? null
                  : () => route == Routes.home
                        ? Navigator.of(context).popUntil(
                            (r) => r.settings.name == Routes.home || r.isFirst,
                          )
                        : Navigator.of(context).pushNamed(route),
              child: SizedBox.square(
                dimension: 52,
                child: Icon(icon, size: 22, color: c.navText),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: c.navBg,
        shape: const StadiumBorder(),
        shadows: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(LucideIcons.house, 'Home', Routes.home),
          const SizedBox(width: 6),
          item(LucideIcons.folder, 'Sessions', Routes.history),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: 'Listen in',
            excludeSemantics: true,
            child: Material(
              color: c.gold,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(
                  context.read<LiveListenBloc>().state.isActive
                      ? Routes.listenLive
                      : Routes.listenSetup,
                ),
                child: SizedBox.square(
                  dimension: 60,
                  child: Icon(LucideIcons.mic, size: 24, color: c.onGold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          item(LucideIcons.slidersHorizontal, 'Settings', Routes.settings),
        ],
      ),
    );
  }
}

/// Shown on Home while a Listen In session keeps running in the background.
class ActiveListenBanner extends StatelessWidget {
  const ActiveListenBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<LiveListenBloc, LiveListenState>(
      buildWhen: (a, b) =>
          a.isActive != b.isActive ||
          a.elapsed != b.elapsed ||
          a.status != b.status ||
          a.flags.length != b.flags.length,
      builder: (context, state) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: !state.isActive
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Material(
                    color: c.goldSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: c.goldLine),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.listenLive),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            PulsingDot(
                              color: state.isPaused ? c.muted : c.red,
                              active: !state.isPaused,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${state.isPaused ? 'Paused' : 'Listening'} · ${formatClock(state.elapsed)}'
                                '${state.flags.isEmpty ? '' : ' · ${state.flags.length} ${state.flags.length == 1 ? 'flag' : 'flags'}'}',
                                style: context.text.titleSmall,
                              ),
                            ),
                            Text(
                              'Open',
                              style: context.text.labelMedium?.copyWith(
                                color: c.goldText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: c.goldText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Small circular account button with initials.
class AvatarButton extends StatelessWidget {
  const AvatarButton({super.key, required this.initials, required this.onTap});
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Account and settings',
      excludeSemantics: true,
      child: Material(
        color: c.surface2,
        shape: CircleBorder(side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: Text(
                initials,
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jurisdiction chip in the Home header.
class JurisdictionChip extends StatelessWidget {
  const JurisdictionChip({super.key, required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Jurisdiction: $name. Change',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.mapPin, size: 16, color: c.text),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronDown, size: 14, color: c.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
