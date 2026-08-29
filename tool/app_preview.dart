// Records an App Store app preview by playing a real board and capturing every
// frame. Not part of the normal test suite — run it deliberately:
//
//   flutter test tool/app_preview.dart --dart-define=SCREENSHOT_MODE=true \
//     --dart-define=FRAMES_DIR=/path/to/frames --dart-define=DEVICE=iphone
//
// then stitch the frames with tool/app_preview.sh, which is what you actually
// run — it does both devices. Nothing here is faked: it drives the same
// GameScreen the app ships, taps arrows the game reports as clearable, and
// captures whatever the widget tree draws, flight and settle animations
// included.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/main.dart';
import 'package:arrows_game/screens/game_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:arrows_game/widgets/game_board.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _materialFonts =
    '/Users/mac/development/flutter/bin/cache/artifacts/material_fonts';

const _framesDir = String.fromEnvironment('FRAMES_DIR');

const _device = String.fromEnvironment('DEVICE', defaultValue: 'iphone');

/// Logical sizes are real device sizes, so each preview is laid out exactly as
/// that device would lay it out — the iPad one has to be a genuine iPad width
/// or ContentBounds would not kick in and it would record a phone layout.
///
/// The pixel ratios then land each recording on the App Store's preview size:
/// 886x1920 for a 6.5"/6.7" iPhone, and 1200x1600 for a 12.9" iPad (the iPad
/// comes out a pixel or two tall and is cropped when it is encoded).
const _sizes = <String, (Size, double)>{
  'iphone': (Size(443, 960), 2.0),
  'ipad': (Size(1024, 1366), 1200 / 1024),
};

Size get _logical => _sizes[_device]!.$1;
double get _pixelRatio => _sizes[_device]!.$2;

/// 30fps, which is what the App Store expects.
const _frameStep = Duration(milliseconds: 33);

/// Long enough to read a move, short enough that the board keeps moving.
const _framesPerMove = 12;

/// The App Store wants 15-30 seconds.
const _targetFrames = 30 * 22;

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(File(path).readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Hundreds of PNG encodes; the 30-second default is nowhere near enough.
  testWidgets('record app preview',
      timeout: const Timeout(Duration(minutes: 30)), (tester) async {
    if (_framesDir.isEmpty) {
      fail('Pass --dart-define=FRAMES_DIR=<dir>');
    }
    if (!_sizes.containsKey(_device)) {
      fail('DEVICE must be one of ${_sizes.keys.join(", ")}');
    }
    final dir = Directory(_framesDir)..createSync(recursive: true);

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

    tester.view.physicalSize = Size(
      _logical.width * _pixelRatio,
      _logical.height * _pixelRatio,
    );
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // The wrapper the real app installs — without it the iPad recording
          // would show a phone-sized interface at iPad dimensions.
          builder: (context, child) => TabletScale(child: child!),
          home: GameScreen(customLevel: LevelCatalog.byId(56)),
        ),
      ),
    );

    var frame = 0;
    Future<void> capture() async {
      final boundary = captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final name = 'frame_${(frame++).toString().padLeft(4, '0')}.png';
      // PNG encoding never finishes inside the test's fake-async zone — it
      // needs real time to run in, which is what runAsync provides.
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('${dir.path}/$name').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    Future<void> hold(int frames) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(_frameStep);
        await capture();
      }
    }

    // Let the board's entry animation play out before anything is touched.
    await hold(20);

    // The GameBoard paints a single canvas and maps a tap to the nearest
    // arrow, so there is no per-arrow widget to find. Work out where a cell
    // lands the same way the board does.
    Offset centreOf(GameController c, int row, int col) {
      final box = tester.getRect(find.byType(GameBoard));
      final cell = (box.width / c.cols) < (box.height / c.rows)
          ? box.width / c.cols
          : box.height / c.rows;
      final origin = box.center - Offset(cell * c.cols / 2, cell * c.rows / 2);
      return origin + Offset((col + 0.5) * cell, (row + 0.5) * cell);
    }

    while (frame < _targetFrames) {
      final session = tester.widget<GameBoard>(find.byType(GameBoard)).session;
      final ids = session.controller.clearableArrowIds();
      if (ids.isEmpty) break;

      // Always a legal move — the controller is the one saying it is clearable.
      final arrow = session.controller.arrows[ids.first]!;
      await tester.tapAt(centreOf(session.controller, arrow.row, arrow.col));
      await hold(_framesPerMove);
    }

    // Sit on the result for a beat so the video does not cut mid-motion.
    await hold(30);

    // ignore: avoid_print
    print('wrote $frame frames to ${dir.path}');
  });
}
