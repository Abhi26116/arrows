// Generates store-ready screenshots at the exact pixel sizes Apple and Google
// ask for. Not part of the normal test suite — run it deliberately:
//
//   flutter test tool/store_screenshots.dart --update-goldens
//
// Output lands in store/screenshots/{ios,android}/.
import 'dart:io';

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/screens/game_screen.dart';
import 'package:arrows_game/screens/home_screen.dart';
import 'package:arrows_game/screens/level_select_screen.dart';
import 'package:arrows_game/screens/themes_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _materialFonts =
    '/Users/mac/development/flutter/bin/cache/artifacts/material_fonts';

/// iPhone 6.7" (1290x2796) and a common Android phone (1080x2400).
const _devices = <String, (Size, double)>{
  'ios': (Size(1290, 2796), 3),
  'android': (Size(1080, 2400), 3),
};

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(File(path).readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // A believable amount of progress, so the shots aren't of an empty game.
    // This file is a test in everything but location, so the analyser's
    // "only in tests" rule does not apply.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'seen_how_to': true,
      'entitlement_remove_ads': true,
      'settings_sound': false,
      'settings_haptics': false,
      'max_unlocked_level': 34,
      'settings_show_grid': false,
      for (var i = 1; i <= 33; i++) 'level_stars_$i': i % 3 == 0 ? 2 : 3,
    });
    await AppStore.instance.init();
    await _loadFont('DMSans', 'assets/fonts/DMSans.ttf');
    await _loadFont(
        'MaterialIcons', '$_materialFonts/MaterialIcons-Regular.otf');
  });

  for (final entry in _devices.entries) {
    final platform = entry.key;
    final (size, dpr) = entry.value;

    Future<void> shot(WidgetTester tester, Widget page, String name) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: page,
      ));
      // Let the entry animations settle.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../store/screenshots/$platform/$name.png'),
      );
    }

    group(platform, () {
      testWidgets('01 hard board', (t) async {
        await shot(t, GameScreen(customLevel: LevelCatalog.byId(56)),
            '01_hard_board');
      });
      testWidgets('02 home', (t) => shot(t, const HomeScreen(), '02_home'));
      testWidgets('03 expert board', (t) async {
        await shot(t, GameScreen(customLevel: LevelCatalog.byId(78)),
            '03_expert_board');
      });
      testWidgets('04 levels', (t) async {
        await shot(t, const LevelSelectScreen(), '04_levels');
      });
      testWidgets('05 themes', (t) async {
        await shot(t, const ThemesScreen(), '05_themes');
      });
    });
  }
}
