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

  /// Single stroke colour used for the board's line-art arrows.
  final Color? line;

  Color get arrowLine => line ?? arrowPalette.first;
}

class GameThemes {
  static const ocean = GameTheme(
    id: 'ocean',
    name: 'Ocean',
    premium: false,
    bgTop: Color(0xFF071A1F),
    bgMid: Color(0xFF0A242C),
    bgBottom: Color(0xFF0D2E36),
    surface: Color(0xFF123840),
    surfaceHigh: Color(0xFF1A4A54),
    ink: Color(0xFFE8F4F2),
    muted: Color(0xFF8BB0B4),
    accent: Color(0xFFFF6B4A),
    accentSoft: Color(0xFFFF8F75),
    success: Color(0xFF3DDC97),
    danger: Color(0xFFFF5C7A),
    gridLine: Color(0xFF1E4F5A),
    arrowPalette: [
      Color(0xFF5CE1E6),
      Color(0xFFFFB347),
      Color(0xFF7CFFB2),
      Color(0xFFFF7EB6),
      Color(0xFFA78BFA),
      Color(0xFFFFE66D),
    ],
    line: Color(0xFFA8E6EA),
  );

  static const midnight = GameTheme(
    id: 'midnight',
    name: 'Midnight',
    premium: false,
    bgTop: Color(0xFF0B1020),
    bgMid: Color(0xFF12182C),
    bgBottom: Color(0xFF1A2038),
    surface: Color(0xFF1E2744),
    surfaceHigh: Color(0xFF2A3558),
    ink: Color(0xFFE8ECFF),
    muted: Color(0xFF9AA3C7),
    accent: Color(0xFF5B8CFF),
    accentSoft: Color(0xFF8AAEFF),
    success: Color(0xFF5EEAD4),
    danger: Color(0xFFFF6B8A),
    gridLine: Color(0xFF2E3A5E),
    arrowPalette: [
      Color(0xFF7DD3FC),
      Color(0xFFC4B5FD),
      Color(0xFF86EFAC),
      Color(0xFFFDA4AF),
      Color(0xFFFDE68A),
      Color(0xFF67E8F9),
    ],
    line: Color(0xFFAEB6F5),
  );

  static const ember = GameTheme(
    id: 'ember',
    name: 'Ember',
    premium: false,
    bgTop: Color(0xFF1A0E0C),
    bgMid: Color(0xFF241412),
    bgBottom: Color(0xFF2E1A16),
    surface: Color(0xFF3A221C),
    surfaceHigh: Color(0xFF4A2E26),
    ink: Color(0xFFFFF1E8),
    muted: Color(0xFFC4A090),
    accent: Color(0xFFFF7A45),
    accentSoft: Color(0xFFFFA06C),
    success: Color(0xFFB8E986),
    danger: Color(0xFFFF5C5C),
    gridLine: Color(0xFF5A3A30),
    arrowPalette: [
      Color(0xFFFFB347),
      Color(0xFFFF6B4A),
      Color(0xFFFFD166),
      Color(0xFFFF8FAB),
      Color(0xFF90E0A8),
      Color(0xFFFFC9A3),
    ],
    line: Color(0xFFFFC49B),
  );

  static const aurora = GameTheme(
    id: 'aurora',
    name: 'Aurora',
    premium: true,
    bgTop: Color(0xFF061820),
    bgMid: Color(0xFF0A2830),
    bgBottom: Color(0xFF123038),
    surface: Color(0xFF163840),
    surfaceHigh: Color(0xFF1F4C56),
    ink: Color(0xFFE7FFF8),
    muted: Color(0xFF8FC9BE),
    accent: Color(0xFF2EE6A6),
    accentSoft: Color(0xFF7CF5C8),
    success: Color(0xFF5CE1E6),
    danger: Color(0xFFFF6B9D),
    gridLine: Color(0xFF25555E),
    arrowPalette: [
      Color(0xFF2EE6A6),
      Color(0xFF5CE1E6),
      Color(0xFFB8F2E6),
      Color(0xFFFFB4A2),
      Color(0xFFA5B4FC),
      Color(0xFFFDE68A),
    ],
    line: Color(0xFF9FF0D2),
  );

  static const noir = GameTheme(
    id: 'noir',
    name: 'Noir',
    premium: true,
    bgTop: Color(0xFF0A0A0A),
    bgMid: Color(0xFF141414),
    bgBottom: Color(0xFF1C1C1C),
    surface: Color(0xFF242424),
    surfaceHigh: Color(0xFF333333),
    ink: Color(0xFFF5F5F5),
    muted: Color(0xFFA3A3A3),
    accent: Color(0xFFE8E8E8),
    accentSoft: Color(0xFFCFCFCF),
    success: Color(0xFFB0B0B0),
    danger: Color(0xFFFF5C5C),
    gridLine: Color(0xFF3A3A3A),
    arrowPalette: [
      Color(0xFFFFFFFF),
      Color(0xFFD4D4D4),
      Color(0xFFA3A3A3),
      Color(0xFFFF8A80),
      Color(0xFF80CBC4),
      Color(0xFFFFE082),
    ],
    line: Color(0xFFE6E6E6),
  );

  static const solar = GameTheme(
    id: 'solar',
    name: 'Solar',
    premium: true,
    bgTop: Color(0xFF1A1408),
    bgMid: Color(0xFF241C0C),
    bgBottom: Color(0xFF2E2410),
    surface: Color(0xFF3A3018),
    surfaceHigh: Color(0xFF4A3E20),
    ink: Color(0xFFFFF8E7),
    muted: Color(0xFFC9B896),
    accent: Color(0xFFFFC107),
    accentSoft: Color(0xFFFFD54F),
    success: Color(0xFFAED581),
    danger: Color(0xFFFF7043),
    gridLine: Color(0xFF5A4A28),
    arrowPalette: [
      Color(0xFFFFC107),
      Color(0xFFFF9800),
      Color(0xFFFFECB3),
      Color(0xFFFFAB91),
      Color(0xFF80CBC4),
      Color(0xFFFFF59D),
    ],
    line: Color(0xFFFFDE9B),
  );

  static const all = [ocean, midnight, ember, aurora, noir, solar];

  static GameTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => ocean);
}
