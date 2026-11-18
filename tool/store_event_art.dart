// Renders the App Store In-App Event images:
//
//   flutter test tool/store_event_art.dart --update-goldens
//
// Output lands in store/events/:
//
//   event_card_1920x1080.png     event card, 16:9
//   event_details_1080x1920.png  event details page, 9:16
//
// Apple sets the event name, badge and short description over these images
// itself, mostly across the lower part, so there is no text in them and the
// bottom fades darker to keep Apple's type readable. The art is a real board
// drawn by the shipping GameBoard, like the store header in
// tool/store_header.dart, shaped to fill each frame edge to edge.
//
// The goldens come out RGBA. They are flattened to RGB after rendering
// (the frame is opaque anyway) so App Store Connect has no alpha to object to:
//
//   python3 -c "from PIL import Image; [Image.open(p).convert('RGB').save(p)
//     for p in ['store/events/event_card_1920x1080.png',
//               'store/events/event_details_1080x1920.png']]"
import 'dart:io';
import 'dart:math';

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/models/level.dart';
import 'package:arrows_game/theme/game_themes.dart';
import 'package:arrows_game/theme/theme_controller.dart';
import 'package:arrows_game/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _materialFonts =
    '/Users/mac/development/flutter/bin/cache/artifacts/material_fonts';

const _dpr = 2.0;

/// Short arrows and a high fill, as in the header: at this size what makes the
/// picture read as arrows is the heads.
LevelData _board(int seed, int rows, int cols) =>
    LevelGenerator(Random(seed)).generate(
      id: 2000 + seed,
      rows: rows,
      cols: cols,
      fill: 0.62,
      maxLength: 6,
      bendChance: 0.50,
      maxBends: 2,
      captiveCount: 0,
      difficulty: 'Medium',
      label: 'Event',
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
    await _loadFont(
        'MaterialIcons', '$_materialFonts/MaterialIcons-Regular.otf');
  });

  Future<void> render(
    WidgetTester tester,
    Size size,
    LevelData board,
    String golden,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size / _dpr),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _EventArt(board: board),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(find.byType(_EventArt), matchesGoldenFile(golden));
  }

  testWidgets('event card', (tester) async {
    await render(
      tester,
      const Size(1920, 1080),
      _board(11, 9, 16),
      '../store/events/event_card_1920x1080.png',
    );
  });

  testWidgets('event details', (tester) async {
    await render(
      tester,
      const Size(1080, 1920),
      _board(12, 16, 9),
      '../store/events/event_details_1080x1920.png',
    );
  });
}

class _EventArt extends StatelessWidget {
  const _EventArt({required this.board});

  final LevelData board;

  @override
  Widget build(BuildContext context) {
    const line = Color(0xFFF98A9C);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameBoard(session: PlaySession(board), onTap: (_) {}),
          // The game's own colours at the corners, as in the header.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  line.withValues(alpha: 0.16),
                  Colors.transparent,
                  GameThemes.midnight.accent.withValues(alpha: 0.16),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
          // Darker toward the bottom, where Apple sets its text.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.35, 0.65, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
