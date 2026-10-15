import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'features/listen_in/presentation/bloc/live_listen_bloc.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backendConfigured = await _initBackend();
  await configureDependencies(backendConfigured: backendConfigured);

  final settings = sl<SettingsCubit>();
  await settings.load();

  runApp(LegaiApp(settings: settings, liveListen: sl<LiveListenBloc>()));
}

/// Connects Supabase when `.env` has its keys. Without them the app runs in
/// guest mode: no sign-in, everything stored on the phone.
Future<bool> _initBackend() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('LegAI: no .env file loaded ($e). Running in guest mode.');
    return false;
  }
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    debugPrint(
      'LegAI: SUPABASE_URL or SUPABASE_ANON_KEY missing. Running in guest mode.',
    );
    return false;
  }
  await Supabase.initialize(url: url, publishableKey: key);
  return true;
}
