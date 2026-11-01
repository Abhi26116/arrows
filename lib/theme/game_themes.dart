import 'package:flutter/material.dart';

class GameTheme {
  const GameTheme({
    required this.id,
    required this.name,
    required this.premium,
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.surface,
    required this.surfaceHigh,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.danger,
    required this.gridLine,
    required this.arrowPalette,
    this.line,
    this.lineAccent,
  });

  final String id;
  final String name;
  final bool premium;
  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;
  final Color surface;
  final Color surfaceHigh;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color danger;
  final Color gridLine;
  final List<Color> arrowPalette;

  /// Signature stroke colour for the board's neon line art.
  final Color? line;

  /// Second stroke colour, carried by roughly one arrow in seven. Pure
  /// decoration — it breaks up a dense board the way the reference art does.
  final Color? lineAccent;

  Color get arrowLine => line ?? arrowPalette.first;
  Color get arrowAccent => lineAccent ?? Colors.white;
}

/// Every palette sits on pure black so the strokes read as lit neon rather
/// than ink on paper. Each theme owns one signature line colour, with an
/// [GameTheme.accent] far enough away in hue that a pulsing hint is obvious
/// against the rest of the board.
class GameThemes {
  static const ocean = GameTheme(
    id: 'ocean',
    name: 'Ocean',
    premium: false,
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF03090B),
    bgBottom: Color(0xFF000000),
    surface: Color(0xFF0C181C),
    surfaceHigh: Color(0xFF162B31),
    ink: Color(0xFFE8F4F2),
    muted: Color(0xFF7FA5AA),
    accent: Color(0xFFFF6B4A),
    accentSoft: Color(0xFFFF8F75),
    success: Color(0xFF3DDC97),
    danger: Color(0xFFFF5C7A),
    gridLine: Color(0xFF17333A),
    arrowPalette: [
      Color(0xFF5CE1E6),
      Color(0xFFFFB347),
      Color(0xFF7CFFB2),
      Color(0xFFFF7EB6),
      Color(0xFFA78BFA),
      Color(0xFFFFE66D),
    ],
    line: Color(0xFF5CE1E6),
    lineAccent: Color(0xFFFFFFFF),
  );

  static const midnight = GameTheme(
    id: 'midnight',
    name: 'Midnight',
    premium: false,
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF060509),
    bgBottom: Color(0xFF000000),
    surface: Color(0xFF15121B),
    surfaceHigh: Color(0xFF231D2D),
    ink: Color(0xFFF3EFFF),
    muted: Color(0xFF968FAB),
    accent: Color(0xFF5B8CFF),
    accentSoft: Color(0xFF8AAEFF),
    success: Color(0xFF5EEAD4),
    danger: Color(0xFFFF4D6D),
    gridLine: Color(0xFF2A2435),
    arrowPalette: [
      Color(0xFFF98A9C),
      Color(0xFFC4B5FD),
      Color(0xFF86EFAC),
      Color(0xFFFDA4AF),
      Color(0xFFFDE68A),
      Color(0xFF67E8F9),
    ],
    line: Color(0xFFF98A9C),
    lineAccent: Color(0xFFFFFFFF),
  );

  static const ember = GameTheme(
    id: 'ember',
    name: 'Ember',
    premium: false,
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF0A0503),
    bgBottom: Color(0xFF000000),
    surface: Color(0xFF1B100C),
    surfaceHigh: Color(0xFF2C1C15),
    ink: Color(0xFFFFF1E8),
    muted: Color(0xFFB4917F),
    accent: Color(0xFFFFD166),
    accentSoft: Color(0xFFFFE19B),
    success: Color(0xFFB8E986),
    danger: Color(0xFFFF4D4D),
    gridLine: Color(0xFF3A241C),
    arrowPalette: [
      Color(0xFFFF8A4C),
      Color(0xFFFFB347),
      Color(0xFFFFD166),
      Color(0xFFFF8FAB),
      Color(0xFF90E0A8),
      Color(0xFFFFC9A3),
    ],
    line: Color(0xFFFF8A4C),
    lineAccent: Color(0xFFFFFFFF),
  );

  static const aurora = GameTheme(
    id: 'aurora',
    name: 'Aurora',
    premium: true,
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF04080A),
    bgBottom: Color(0xFF000000),
    surface: Color(0xFF101720),
    surfaceHigh: Color(0xFF1B2533),
    ink: Color(0xFFE7FFF8),
    muted: Color(0xFF86B4AC),
    accent: Color(0xFF2EE6A6),
    accentSoft: Color(0xFF7CF5C8),
    success: Color(0xFF5CE1E6),
    danger: Color(0xFFFF4D8D),
    gridLine: Color(0xFF26304A),
    arrowPalette: [
      Color(0xFF9D7BFF),
      Color(0xFF2EE6A6),
      Color(0xFFB8F2E6),
      Color(0xFFFFB4A2),
      Color(0xFFA5B4FC),
      Color(0xFFFDE68A),
    ],
    line: Color(0xFF9D7BFF),
    lineAccent: Color(0xFFFFFFFF),
  );

  static const noir = GameTheme(
    id: 'noir',
    name: 'Noir',
    premium: true,
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF050505),
    bgBottom: Color(0xFF000000),
    surface: Color(0xFF151515),
    surfaceHigh: Color(0xFF242424),
    ink: Color(0xFFF5F5F5),
    muted: Color(0xFF9A9A9A),
    accent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD9D9D9),
    success: Color(0xFFB0B0B0),
    danger: Color(0xFFFF4D4D),
    gridLine: Color(0xFF2E2E2E),
    arrowPalette: [
      Color(0xFFBDBDBD),
      Color(0xFFD4D4D4),
      Color(0xFFA3A3A3),
      Color(0xFFFF8A80),
      Color(0xFF80CBC4),
      Color(0xFFFFE082),
    ],
    line: Color(0xFFBDBDBD),
    lineAccent: Color(0xFFFFFFFF),
  );

  static const solar = GameTheme(
    id: 'solar',
    name: 'Solar',
    premium: true,
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF0A0803),
    bgBottom: Color(0xFF000000),
    surface: Color(0xFF1A1509),
    surfaceHigh: Color(0xFF2A2212),
    ink: Color(0xFFFFF8E7),
    muted: Color(0xFFB8A782),
    accent: Color(0xFFFF6E40),
    accentSoft: Color(0xFFFF9A76),
    success: Color(0xFFAED581),
    danger: Color(0xFFFF5252),
    gridLine: Color(0xFF3A3018),
    arrowPalette: [
      Color(0xFFFFC107),
      Color(0xFFFF9800),
      Color(0xFFFFECB3),
      Color(0xFFFFAB91),
      Color(0xFF80CBC4),
      Color(0xFFFFF59D),
    ],
    line: Color(0xFFFFC107),
    lineAccent: Color(0xFFFFFFFF),
  );

  static const all = [ocean, midnight, ember, aurora, noir, solar];

  static GameTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => ocean);
}
