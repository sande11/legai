import 'package:flutter/material.dart';

/// Design tokens for LegAI, shared by the dark and light themes.
///
/// Read them anywhere with `context.colors` (see [LegaiColorsX]).
@immutable
class LegaiColors extends ThemeExtension<LegaiColors> {
  const LegaiColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.sheet,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.gold,
    required this.goldText,
    required this.goldIcon,
    required this.onGold,
    required this.goldSoft,
    required this.goldLine,
    required this.red,
    required this.caution,
    required this.cautionSoft,
    required this.next,
    required this.nextSoft,
    required this.bubble,
    required this.dot,
    required this.glow,
    required this.scrim,
    required this.navBg,
    required this.navText,
    required this.wave,
    required this.waveOn,
    required this.trackOff,
    required this.quoteBg,
    required this.cardShadow,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color sheet;
  final Color line;
  final Color text;
  final Color muted;
  final Color faint;
  final Color gold;
  final Color goldText;
  final Color goldIcon;
  final Color onGold;
  final Color goldSoft;
  final Color goldLine;
  final Color red;
  final Color caution;
  final Color cautionSoft;
  final Color next;
  final Color nextSoft;
  final Color bubble;
  final Color dot;
  final Color glow;
  final Color scrim;
  final Color navBg;
  final Color navText;
  final Color wave;
  final Color waveOn;
  final Color trackOff;
  final Color quoteBg;
  final List<BoxShadow> cardShadow;

  static const dark = LegaiColors(
    bg: Color(0xFF0B0B0C),
    surface: Color(0xFF161618),
    surface2: Color(0xFF232326),
    sheet: Color(0xFF161618),
    line: Color(0xFF2C2C30),
    text: Color(0xFFF3EFE6),
    muted: Color(0xFFA39E94),
    faint: Color(0xFF6F6A62),
    gold: Color(0xFFE2B05E),
    goldText: Color(0xFFE9BE76),
    goldIcon: Color(0xFFE2B05E),
    onGold: Color(0xFF1A1408),
    goldSoft: Color(0x24E2B05E),
    goldLine: Color(0x73E2B05E),
    red: Color(0xFFF2555A),
    caution: Color(0xFFF2895F),
    cautionSoft: Color(0x21F2895F),
    next: Color(0xFF8AB4F8),
    nextSoft: Color(0x1F8AB4F8),
    bubble: Color(0xFF232326),
    dot: Color(0xFFE2B05E),
    glow: Color(0x3DE2B05E),
    scrim: Color(0x9E000000),
    navBg: Color(0xFF1E1E21),
    navText: Color(0xFFF3EFE6),
    wave: Color(0xFF4A4741),
    waveOn: Color(0xFFB9B3A8),
    trackOff: Color(0xFF3A3A3F),
    quoteBg: Color(0xFF0F0F10),
    cardShadow: [
      BoxShadow(
        color: Color(0x73000000),
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  );

  static const light = LegaiColors(
    bg: Color(0xFFF5F1E8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECE6D9),
    sheet: Color(0xFFFFFFFF),
    line: Color(0xFFDDD5C5),
    text: Color(0xFF17150F),
    muted: Color(0xFF625C50),
    faint: Color(0xFF8F887A),
    gold: Color(0xFFE2B05E),
    goldText: Color(0xFF8A5F0E),
    goldIcon: Color(0xFF9A6B12),
    onGold: Color(0xFF1A1408),
    goldSoft: Color(0x2EC49234),
    goldLine: Color(0x739A6B12),
    red: Color(0xFFC42B31),
    caution: Color(0xFFB4441F),
    cautionSoft: Color(0x1AB4441F),
    next: Color(0xFF2F5FB3),
    nextSoft: Color(0x1A2F5FB3),
    bubble: Color(0xFFE9E2D3),
    dot: Color(0xFFA8771E),
    glow: Color(0x5CE2B05E),
    scrim: Color(0x6B17150F),
    navBg: Color(0xFF17150F),
    navText: Color(0xFFF5F1E8),
    wave: Color(0xFFCFC6B4),
    waveOn: Color(0xFF6A6255),
    trackOff: Color(0xFFCFC6B4),
    quoteBg: Color(0xFFF5F1E8),
    cardShadow: [
      BoxShadow(color: Color(0x0D17150F), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x0F17150F),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
  );

  @override
  LegaiColors copyWith({Color? bg, Color? surface, Color? text}) {
    return LegaiColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2,
      sheet: sheet,
      line: line,
      text: text ?? this.text,
      muted: muted,
      faint: faint,
      gold: gold,
      goldText: goldText,
      goldIcon: goldIcon,
      onGold: onGold,
      goldSoft: goldSoft,
      goldLine: goldLine,
      red: red,
      caution: caution,
      cautionSoft: cautionSoft,
      next: next,
      nextSoft: nextSoft,
      bubble: bubble,
      dot: dot,
      glow: glow,
      scrim: scrim,
      navBg: navBg,
      navText: navText,
      wave: wave,
      waveOn: waveOn,
      trackOff: trackOff,
      quoteBg: quoteBg,
      cardShadow: cardShadow,
    );
  }

  @override
  LegaiColors lerp(ThemeExtension<LegaiColors>? other, double t) {
    if (other is! LegaiColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return LegaiColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      sheet: c(sheet, other.sheet),
      line: c(line, other.line),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      gold: c(gold, other.gold),
      goldText: c(goldText, other.goldText),
      goldIcon: c(goldIcon, other.goldIcon),
      onGold: c(onGold, other.onGold),
      goldSoft: c(goldSoft, other.goldSoft),
      goldLine: c(goldLine, other.goldLine),
      red: c(red, other.red),
      caution: c(caution, other.caution),
      cautionSoft: c(cautionSoft, other.cautionSoft),
      next: c(next, other.next),
      nextSoft: c(nextSoft, other.nextSoft),
      bubble: c(bubble, other.bubble),
      dot: c(dot, other.dot),
      glow: c(glow, other.glow),
      scrim: c(scrim, other.scrim),
      navBg: c(navBg, other.navBg),
      navText: c(navText, other.navText),
      wave: c(wave, other.wave),
      waveOn: c(waveOn, other.waveOn),
      trackOff: c(trackOff, other.trackOff),
      quoteBg: c(quoteBg, other.quoteBg),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension LegaiColorsX on BuildContext {
  LegaiColors get colors =>
      Theme.of(this).extension<LegaiColors>() ?? LegaiColors.dark;
}
