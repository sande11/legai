import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/route_observer.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../domain/entities/recent_activity.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_widgets.dart';

enum _Filter { all, listenIn, chats }

/// Sessions: every chat, voice conversation and Listen In recording.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with RouteAware {
  _Filter _filter = _Filter.all;

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

  @override
  void didPopNext() => context.read<HomeCubit>().load();

  bool _matches(RecentActivity a) => switch (_filter) {
    _Filter.all => true,
    _Filter.listenIn => a.kind == ActivityKind.listenIn,
    _Filter.chats => a.kind != ActivityKind.listenIn,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final items = state.recent.where(_matches).toList();
          return Stack(
            children: [
              SafeArea(
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
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
                    Text('Sessions', style: context.text.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Everything stays on this phone.',
                      style: context.text.bodySmall?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoicePill(
                          label: 'All',
                          selected: _filter == _Filter.all,
                          onTap: () => setState(() => _filter = _Filter.all),
                        ),
                        ChoicePill(
                          label: 'Listen in',
                          selected: _filter == _Filter.listenIn,
                          onTap: () =>
                              setState(() => _filter = _Filter.listenIn),
                        ),
                        ChoicePill(
                          label: 'Ask & Talk',
                          selected: _filter == _Filter.chats,
                          onTap: () => setState(() => _filter = _Filter.chats),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(LucideIcons.folder, size: 32, color: c.muted),
                            const SizedBox(height: 12),
                            Text(
                              'Nothing here yet',
                              style: context.text.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start a chat or Listen In session from Home.',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        RecentTile(
                          item: items[i],
                          showDivider: i < items.length - 1,
                        ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                child: const Center(
                  child: FloatingNav(current: Routes.history),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
