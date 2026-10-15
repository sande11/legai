import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled fonts so widget tests measure text like a real phone.
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await family('Manrope', [
    'Manrope-Regular.ttf',
    'Manrope-Medium.ttf',
    'Manrope-SemiBold.ttf',
    'Manrope-Bold.ttf',
  ]);
  await family('Newsreader', [
    'Newsreader-Regular.ttf',
    'Newsreader-Medium.ttf',
    'Newsreader-SemiBold.ttf',
    'Newsreader-Italic.ttf',
  ]);

  // Icon font from the lucide package.
  final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await icons.load();
}
