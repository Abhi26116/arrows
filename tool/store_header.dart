// Renders the App Store "Header and Search Results" creative asset:
//
//   flutter test tool/store_header.dart --update-goldens
//
// Output lands in store/header/.
//
// App Store Connect states the supported sizes on the version page itself:
// a header asset takes 5244x2950 or 3840x1646, and a search results asset
// takes 5244x2950, 3840x2560 or 1920x1280. 5244x2950 is therefore the one
// size that serves both, which is what Apple calls a universal asset.
//
// Apple's own guidance for this slot is to focus on a single clear idea, to
// keep the focal artwork centred so nothing important is clipped when the
// store crops it, and to let a short phrase enhance the picture rather than
// describe it. The safe area here is the 3840x1646 header crop centred in
// the 5244x2950 frame — the narrowest shape this image can be asked to
// become — which is 73% of the width and 56% of the height.
import 'dart:io';
import 'dart:math';

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/theme/game_themes.dart';
import 'package:arrows_game/theme/theme_controller.dart';
import 'package:arrows_game/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _materialFonts =
    '/Users/mac/development/flutter/bin/cache/artifacts/material_fonts';

const _size = Size(5244, 2950);
const _dpr = 2.0;

/// Sixteen by nine, so the board fills a sixteen-by-nine frame exactly — no
/// letterboxing, and the art is the game's own rather than a decoration of
/// it. Short arrows and a high fill: at this scale a long arrow is a bare
/// line with its head somewhere off in the distance, and what makes the
/// picture read as *arrows* is the heads.
final _board = LevelGenerator(Random(5)).generate(
  id: 1000,
  rows: 9,
  cols: 16,
  fill: 0.62,
  maxLength: 6,
  bendChance: 0.50,
  maxBends: 2,
  captiveCount: 0,
  difficulty: 'Medium',
  label: 'Header',
);

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(File(path).readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'theme_id': 'midnight'});
    await AppStore.instance.init();
    await ThemeController.instance.load();
    await _loadFont('DMSans', 'assets/fonts/DMSans.ttf');
    await _loadFont(
        'MaterialIcons', '$_materialFonts/MaterialIcons-Regular.otf');
  });

  testWidgets('header', (tester) async {
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);

    final logical = _size / _dpr;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: logical),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _Header(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_Header),
      matchesGoldenFile('../store/header/header_universal.png'),
    );
  });
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    const line = Color(0xFFF98A9C);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return DecoratedBox(
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The board, filling the frame edge to edge.
              GameBoard(
                session: PlaySession(_board),
                onTap: (_) {},
              ),
              // A pool of shadow in the middle, so the wordmark sits on
              // something rather than fighting the arrows behind it.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.50,
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.black.withOpacity(0.62),
                      Colors.black.withOpacity(0.0),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
              // The game's own colour, breathing back in at the corners.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      line.withOpacity(0.16),
                      Colors.transparent,
                      GameThemes.midnight.accent.withOpacity(0.16),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  // Apple crops this image to shapes as narrow as 3840x1646.
                  // Everything that matters stays inside that rectangle.
                  width: w * 0.73,
                  height: h * 0.56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ARROWS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontVariations: const [FontVariation('wght', 800)],
                          fontWeight: FontWeight.w800,
                          fontSize: h * 0.175,
                          height: 1.0,
                          letterSpacing: h * 0.014,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black.withOpacity(0.85),
                                blurRadius: h * 0.05),
                            Shadow(
                                color: line.withOpacity(0.55),
                                blurRadius: h * 0.10),
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.035),
                      Text(
                        'Clear the board. Order is everything.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontVariations: const [FontVariation('wght', 500)],
                          fontSize: h * 0.048,
                          height: 1.25,
                          letterSpacing: h * 0.0012,
                          color: Colors.white.withOpacity(0.86),
                          shadows: [
                            Shadow(
                                color: Colors.black.withOpacity(0.85),
                                blurRadius: h * 0.035),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
