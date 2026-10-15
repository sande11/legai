import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/route_observer.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/legai_mark.dart';
import '../../../../core/widgets/motion.dart';
import '../../../listen_in/presentation/bloc/live_listen_bloc.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/widgets/jurisdiction_picker.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Back on Home: refresh the recent list.
  @override
  void didPopNext() => context.read<HomeCubit>().load();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final place = context.select((SettingsCubit s) => s.state.jurisdiction);

    return Scaffold(
      body: BlocListener<LiveListenBloc, LiveListenState>(
        listenWhen: (a, b) =>
            a.status != b.status && b.status == LiveStatus.saved,
        listener: (context, _) => context.read<HomeCubit>().load(),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final name = state.user?.firstName;
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    onRefresh: context.read<HomeCubit>().load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      children: [
                        Row(
                          children: [
                            const LegaiWordmark(),
                            const Spacer(),
                            JurisdictionChip(
                              name: place.name,
                              onTap: () => showJurisdictionPicker(context),
                            ),
                            const SizedBox(width: 8),
                            AvatarButton(
                              initials: state.user?.initials ?? 'L',
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(Routes.settings),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          child: Text(
                            name == null
                                ? greetingFor(DateTime.now())
                                : '${greetingFor(DateTime.now())}, $name',
                            style: context.text.displaySmall,
                          ),
                        ),
                        const ActiveListenBanner(),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: ListenInCard(
                            onStart: () => Navigator.of(context).pushNamed(
                              context.read<LiveListenBloc>().state.isActive
                                  ? Routes.listenLive
                                  : Routes.listenSetup,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: Row(
                            children: [
                              Expanded(
                                child: ModeCard(
                                  icon: LucideIcons.messageSquare,
                                  title: 'Ask',
                                  subtitle: 'Type a legal question',
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(Routes.chat),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ModeCard(
                                  icon: LucideIcons.audioLines,
                                  title: 'Talk',
                                  subtitle: 'Speak it out loud',
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(Routes.voice),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Recent',
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (state.recent.isNotEmpty)
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(Routes.history),
                                child: const Text('See all'),
                              ),
                          ],
                        ),
                        if (!state.loading && state.recent.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Your chats and Listen In recordings will appear here.',
                              style: context.text.bodySmall?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        for (var i = 0; i < state.recent.length; i++)
                          RecentTile(
                            item: state.recent[i],
                            showDivider: i < state.recent.length - 1,
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: const Center(child: FloatingNav(current: Routes.home)),
                ),
                // Keeps text readable where the list scrolls under the status bar.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.paddingOf(context).top,
                  child: ColoredBox(color: c.bg),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
