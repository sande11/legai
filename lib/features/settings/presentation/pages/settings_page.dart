import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/app_settings.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/jurisdiction_picker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.user, required this.canSignOut});

  final AppUser? user;
  final bool canSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(Routes.login, (_) => false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    label: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Settings', style: context.text.headlineLarge),
              const SizedBox(height: 24),

              const _SectionLabel('Appearance'),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: ShapeDecoration(
                  color: c.surface2,
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  children: [
                    for (final (pref, label, icon) in [
                      (ThemePreference.system, 'System', LucideIcons.sunMoon),
                      (ThemePreference.light, 'Light', LucideIcons.sun),
                      (ThemePreference.dark, 'Dark', LucideIcons.moon),
                    ])
                      Expanded(
                        child: _Segment(
                          label: label,
                          icon: icon,
                          selected: settings.theme == pref,
                          onTap: () => cubit.setTheme(pref),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const _SectionLabel('Law'),
              _Row(
                icon: LucideIcons.mapPin,
                title: 'Jurisdiction',
                subtitle: settings.jurisdiction.name,
                onTap: () => showJurisdictionPicker(context),
              ),
              _Row(
                icon: LucideIcons.sparkles,
                title: 'AI answers',
                subtitle:
                    'Demo answers on this phone. Connect a backend for full answers.',
              ),
              const SizedBox(height: 28),

              const _SectionLabel('Listen In'),
              _SwitchRow(
                icon: LucideIcons.volume2,
                title: 'Announce the recording',
                subtitle:
                    'Say "This conversation is being recorded" when it starts',
                value: settings.announceRecording,
                onChanged: cubit.setAnnounceRecording,
              ),
              _SwitchRow(
                icon: LucideIcons.headphones,
                title: 'Whisper advice to earbuds',
                subtitle: 'Only when earbuds or headphones are connected',
                value: settings.whisperAdvice,
                onChanged: cubit.setWhisperAdvice,
              ),
              _Row(
                icon: LucideIcons.lock,
                title: 'Recordings',
                subtitle: 'Saved only on this phone. You choose what to share.',
              ),
              const SizedBox(height: 28),

              const _SectionLabel('Account'),
              _Row(
                icon: LucideIcons.user,
                title: user?.isGuest ?? true
                    ? 'Guest'
                    : (user?.name ?? 'Signed in'),
                subtitle: user?.isGuest ?? true
                    ? 'No account connected on this build'
                    : (user?.email ?? ''),
              ),
              if (canSignOut)
                _Row(
                  icon: LucideIcons.logOut,
                  title: 'Log out',
                  destructive: true,
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: 'Log out?',
                      message: 'Your recordings stay on this phone.',
                      confirmLabel: 'Log out',
                    );
                    if (ok && context.mounted) {
                      context.read<AuthBloc>().add(const SignOutRequested());
                    }
                  },
                ),
              const SizedBox(height: 28),
              Text(
                'LegAI gives general legal information, not legal representation. For advice on your own case, speak to a lawyer.',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: context.text.labelSmall?.copyWith(
        color: context.colors.goldText,
        letterSpacing: 1,
      ),
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: ShapeDecoration(
          color: selected ? c.surface : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: selected ? c.text : c.muted),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(
                      color: selected ? c.text : c.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = destructive ? c.red : c.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(color: color),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!, style: context.text.bodySmall),
                ],
              ),
            ),
            if (onTap != null && !destructive)
              Icon(LucideIcons.chevronRight, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: c.text),
              ),
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
