import 'package:flutter/material.dart';

/// Mid-Century Speed Club design tokens for Reversi Rush.
/// Stitch design system "Mid-Century Speed Club" v1 — visual source of truth.
/// Light comes from top-left at 45°. Brass / ivory / teak material trio.
class Club {
  // --- Palette ---
  static const cream = Color(0xFFF7F3E9); // backgrounds, card faces, dial digits
  static const cardstock = Color(0xFFEFE9D9); // secondary surfaces
  static const hairline = Color(0xFFE2D9C3); // recessed grid lines, dividers
  static const ivory = Color(0xFFFAFAF7); // white disc face
  static const brass = Color(0xFFC89B3C); // hardware, rims, bezels, borders
  static const brassHi = Color(0xFFDFB75A); // top-edge reflection lines
  static const brassDeep = Color(0xFF9A7326); // recessed brass
  static const teak = Color(0xFF543018); // primary buttons, deep wood
  static const teakLight = Color(0xFF6E4426); // teak highlight
  static const darkTeak = Color(0xFF3B2110); // button bevels, warm shadows, text
  static const ebonite = Color(0xFF161616); // black disc enamel, dial backgrounds
  static const crimson = Color(0xFFB93829); // urgency: timers, countdown hand
  static const walnut = Color(0xFF2A1D12); // table surround / underlay

  // --- Typography ---
  static const display = 'Newsreader'; // stamped club serif
  static const condensed = 'Barlow Condensed'; // buttons, stat numerals, labels
  static const body = 'Work Sans'; // body copy

  static TextStyle hDisplay(double size, {Color color = darkTeak}) => TextStyle(
        fontFamily: display,
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color,
        letterSpacing: 0.5,
      );

  static TextStyle label(double size,
          {Color color = darkTeak, double spacing = 2.2}) =>
      TextStyle(
        fontFamily: condensed,
        fontWeight: FontWeight.w600,
        fontSize: size,
        color: color,
        letterSpacing: spacing,
      );

  static TextStyle numeral(double size, {Color color = darkTeak}) => TextStyle(
        fontFamily: condensed,
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color,
        letterSpacing: 1.0,
      );

  static TextStyle bodyText(double size, {Color color = darkTeak}) => TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w400,
        fontSize: size,
        color: color,
        height: 1.45,
      );

  // --- Material helpers ---
  /// Weighted contact shadow for discs / buttons (light from top-left).
  static List<BoxShadow> contactShadow({double blur = 10, double dy = 5}) => [
        BoxShadow(
          color: const Color(0x66000000),
          blurRadius: blur,
          offset: Offset(2, dy),
        ),
      ];

  /// Milled-brass trim ring.
  static BoxDecoration brassRing({double width = 2, double radius = 14}) =>
      BoxDecoration(
        border: Border.all(color: brass, width: width),
        borderRadius: BorderRadius.circular(radius),
      );

  /// Debossed inset panel (board field).
  static List<BoxShadow> deboss() => const [
        BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 3)),
        BoxShadow(
            color: Color(0x33FFFFFF), blurRadius: 4, offset: Offset(0, -2)),
      ];
}
