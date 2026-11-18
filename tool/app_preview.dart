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
//
// DEVICE=shorts records a 1080x1920 clip for YouTube Shorts / Instagram Reels
// instead: the phone screen sits in a frame under a caption, and the board is
// played to the very end. tool/shorts.sh drives it.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/main.dart';
import 'package:arrows_game/screens/game_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:arrows_game/widgets/game_board.dart';
import 'package:arrows_game/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
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
  'shorts': (Size(540, 960), 2.0),
};

bool get _isShort => _device == 'shorts';

/// The board to play. 56 is the one the App Store previews use.
const _level = int.fromEnvironment('LEVEL', defaultValue: 56);

/// Frames to sit on the untouched board before the first tap, after its entry
/// animation — the "which arrow goes first?" pause in a Shorts clip.
const _holdStart = int.fromEnvironment('HOLD_START', defaultValue: 0);

/// Shorts captions arrive base64-encoded UTF-8, so commas and Devanagari
/// survive the trip through --dart-define.
String _decoded(String b64) =>
    b64.isEmpty ? '' : utf8.decode(base64.decode(b64));
final _hook = _decoded(const String.fromEnvironment('HOOK_B64'));
final _endText = _decoded(const String.fromEnvironment('END_B64'));

/// Devanagari for Hindi captions; DM Sans has no Indic glyphs.
const _devanagariFont = '/System/Library/Fonts/Kohinoor.ttc';

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

    // audioplayers has no implementation under `flutter test`, and the game
    // reaches SoundService the moment an arrow is tapped. Its AudioPlayer is
    // built in a field initialiser, so switching sound off is not enough —
    // the channels are hit as soon as the singleton exists, and the
    // MissingPluginException lands on the test rather than on the game.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in const [
      MethodChannel('xyz.luan/audioplayers'),
      MethodChannel('xyz.luan/audioplayers.global'),
    ]) {
      messenger.setMockMethodCallHandler(channel, (call) async => null);
    }
    messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
    // Each AudioPlayer also opens an event channel named after its own
    // randomly generated id, which cannot be mocked ahead of time. Nothing
    // here listens to those events, and the player is already standing in for
    // a plugin that is not present, so drop the one exception it raises
    // rather than let it fail a recording that has otherwise finished.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is MissingPluginException) return;
      reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    await _loadFont('DMSans', 'assets/fonts/DMSans.ttf');
    if (_isShort) await _loadFont('Devanagari', _devanagariFont);
    await _loadFont(
        'MaterialIcons', '$_materialFonts/MaterialIcons-Regular.otf');

    tester.view.physicalSize = Size(
      _logical.width * _pixelRatio,
      _logical.height * _pixelRatio,
    );
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    final captureKey = GlobalKey();
    final caption = ValueNotifier(_hook);
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
          builder: (context, child) => _isShort
              ? _ShortsFrame(caption: caption, child: child!)
              : TabletScale(child: child!),
          home: GameScreen(customLevel: LevelCatalog.byId(_level)),
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

    Future<void> hold(int frames, {Duration step = _frameStep}) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(step);
        await capture();
      }
    }

    // Let the board's entry animation play out before anything is touched.
    await hold(20);
    await hold(_holdStart);

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

    // GameScreen ignores taps while an arrow is still flying (320ms), so
    // every move gets 400ms of game time whatever the pace. A Short plays the
    // whole board, so on a big board it captures fewer frames across those
    // 400ms — the moves play back faster (up to 2x), about 26 seconds of them
    // whatever the arrow count, while the pauses and captions around them
    // keep real time. Previews keep their 12 frames a move at real time.
    final arrowCount = tester
        .widget<GameBoard>(find.byType(GameBoard))
        .session
        .controller
        .arrows
        .length;
    final perMove =
        _isShort ? (780 ~/ arrowCount).clamp(6, 12) : _framesPerMove;
    final moveStep = _isShort
        ? Duration(microseconds: 400000 ~/ perMove)
        : _frameStep;
    final maxFrames = _isShort ? 30 * 55 : _targetFrames;

    while (frame < maxFrames) {
      final session = tester.widget<GameBoard>(find.byType(GameBoard)).session;
      final ids = session.controller.clearableArrowIds();
      if (ids.isEmpty) break;

      // Always a legal move — the controller is the one saying it is clearable.
      final arrow = session.controller.arrows[ids.first]!;
      await tester.tapAt(centreOf(session.controller, arrow.row, arrow.col));
      await hold(perMove, step: moveStep);
    }

    // Sit on the result for a beat so the video does not cut mid-motion.
    if (_endText.isNotEmpty) caption.value = _endText;
    await hold(_isShort ? 75 : 30);

    // ignore: avoid_print
    print('wrote $frame frames to ${dir.path}');
  });
}

/// A Shorts canvas: the caption on top, the phone screen framed below it.
/// The phone keeps its real logical size (443x960) and is scaled down as a
/// whole, so the game lays out exactly as it does on an iPhone. Everything
/// sits clear of the bottom fifth and the right edge, where YouTube and
/// Instagram draw their own buttons and titles.
class _ShortsFrame extends StatelessWidget {
  const _ShortsFrame({required this.caption, required this.child});

  final ValueListenable<String> caption;
  final Widget child;

  static const _phone = Size(443, 960);
  static const _phoneHeight = 720.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Material(
      color: AppColors.bgTop,
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 14),
              child: Center(
                child: ValueListenableBuilder<String>(
                  valueListenable: caption,
                  builder: (context, text, _) => Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontFamilyFallback: const ['Devanagari'],
                      fontVariations: const [FontVariation('wght', 800)],
                      fontWeight: FontWeight.w800,
                      fontSize: 29,
                      height: 1.25,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: _phoneHeight,
            width: _phone.width * _phoneHeight / _phone.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FittedBox(
                child: SizedBox.fromSize(
                  size: _phone,
                  child: MediaQuery(
                    data: media.copyWith(
                      size: _phone,
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
