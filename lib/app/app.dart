import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/legai_theme.dart';
import '../features/listen_in/presentation/bloc/live_listen_bloc.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import 'route_observer.dart';
import 'router.dart';
import 'routes.dart';

class LegaiApp extends StatelessWidget {
  const LegaiApp({super.key, required this.settings, required this.liveListen});

  final SettingsCubit settings;

  /// App-wide so Listen In keeps running while you use other screens.
  final LiveListenBloc liveListen;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: liveListen),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        buildWhen: (a, b) => a.theme != b.theme,
        builder: (context, s) => MaterialApp(
          title: 'LegAI',
          debugShowCheckedModeBanner: false,
          theme: LegaiTheme.light,
          darkTheme: LegaiTheme.dark,
          themeMode: context.read<SettingsCubit>().themeMode,
          initialRoute: Routes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          navigatorObservers: [appRouteObserver],
        ),
      ),
    );
  }
}
