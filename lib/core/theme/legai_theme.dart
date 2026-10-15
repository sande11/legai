import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'legai_colors.dart';

/// Font families bundled in `assets/fonts`.
abstract final class LegaiFonts {
  static const sans = 'Manrope';
  static const serif = 'Newsreader';
}

/// Builds the Material themes from [LegaiColors].
abstract final class LegaiTheme {
  static ThemeData get dark => _build(LegaiColors.dark, Brightness.dark);
  static ThemeData get light => _build(LegaiColors.light, Brightness.light);

  static ThemeData _build(LegaiColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.gold,
      onPrimary: c.onGold,
      secondary: c.goldText,
      onSecondary: c.onGold,
      error: c.red,
      onError: Colors.white,
      surface: c.bg,
      onSurface: c.text,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface2,
      onSurfaceVariant: c.muted,
      outline: c.line,
      outlineVariant: c.line,
    );

    final text = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: LegaiFonts.sans,
      textTheme: text,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.text, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleMedium,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.gold,
        selectionColor: c.goldSoft,
        selectionHandleColor: c.gold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: text.bodyMedium?.copyWith(color: c.muted),
        labelStyle: text.bodyMedium?.copyWith(color: c.muted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: c.goldText),
        prefixIconColor: c.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.gold,
          foregroundColor: c.onGold,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: c.line),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.goldText,
          minimumSize: const Size(44, 44),
          textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.gold : c.trackOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.navBg,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.navText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheet,
        modalBackgroundColor: c.sheet,
        showDragHandle: true,
        dragHandleColor: c.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.muted),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.gold),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(LegaiColors c) {
    TextStyle serif(
      double size, {
      FontWeight w = FontWeight.w500,
      double h = 1.1,
      double ls = -0.3,
    }) => TextStyle(
      fontFamily: LegaiFonts.serif,
      fontSize: size,
      fontWeight: w,
      height: h,
      letterSpacing: ls,
      color: c.text,
    );
    TextStyle sans(
      double size, {
      FontWeight w = FontWeight.w400,
      double h = 1.45,
      Color? color,
    }) => TextStyle(
      fontFamily: LegaiFonts.sans,
      fontSize: size,
      fontWeight: w,
      height: h,
      color: color ?? c.text,
    );

    return TextTheme(
      // Serif: screen titles, advice headlines, live captions.
      displayLarge: serif(40, ls: -0.8, h: 1.05),
      displayMedium: serif(34, ls: -0.5),
      displaySmall: serif(32, ls: -0.5),
      headlineLarge: serif(30, ls: -0.45),
      headlineMedium: serif(28, ls: -0.3),
      headlineSmall: serif(26, w: FontWeight.w400, h: 1.28, ls: -0.25),
      titleLarge: serif(24, h: 1.15, ls: -0.2),
      // Sans: everything you read.
      titleMedium: sans(16, w: FontWeight.w700, h: 1.3),
      titleSmall: sans(15, w: FontWeight.w600, h: 1.35),
      bodyLarge: sans(16, h: 1.5),
      bodyMedium: sans(15, h: 1.5),
      bodySmall: sans(13, h: 1.45, color: c.muted),
      labelLarge: sans(16, w: FontWeight.w700, h: 1.2),
      labelMedium: sans(13, w: FontWeight.w600, h: 1.3),
      labelSmall: sans(12, w: FontWeight.w700, h: 1.3),
    );
  }
}

extension LegaiTextX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}
