// Turns the raw screen captures into the framed, captioned images that
// actually go on a store listing. Run it after tool/store_screenshots.dart:
//
//   flutter test tool/store_marketing.dart --update-goldens
//
// Output lands in store/marketing/{ios,ipad,android,android_tablet}/.
//
// A raw capture tells someone what the app looks like. A listing image has to
// tell them what it is before they scroll past — the first two are all most
// people ever see, so each one carries a single claim and the art that backs
// it up. Four things follow from that and shape everything below:
//
//   * the claim has to survive a thumbnail, so the headline is set huge and
//     the sub-line carries nothing the headline needs;
//   * the dead space under a board is worth nothing, so the captures are
//     measured and windowed to what is actually drawn;
//   * every panel is one phone, at one size, in one place, so the six read as
//     a set rather than as six unrelated pictures;
//   * six near-black panels on one near-black gradient read as one grey smear
//     in a search result, so each panel takes its colour from a different one
//     of the game's own palettes.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/models/arrow.dart';
import 'package:arrows_game/models/direction.dart';
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

/// Same sizes the raw captures use, so these drop straight into the store.
/// App Store Connect rejects the old 1290x2796 iPhone size outright.
const _devices = <String, (Size, double)>{
  'ios': (Size(1206, 2622), 3),
  'ipad': (Size(2048, 2732), 2),
  'android': (Size(1080, 2400), 3),
  'android_tablet': (Size(1600, 2560), 2),
};

enum _Art {
  /// One capture, in the phone.
  device,

  /// The blocking rule, drawn rather than described, in the same phone.
  rule,

  /// One board under three palettes, cut into bands of the same phone.
  triptych,
}

typedef _Panel = ({
  _Art art,
  String source,
  Color hue,
  String headline,
  String sub,
});

/// The listing, in order. One and two do the selling; the rest answer the
/// questions someone has once they are interested. The hue is the signature
/// line colour of whichever palette that panel's capture was rendered in, so
/// the frame and the screen inside it agree.
final _panels = <_Panel>[
  (
    art: _Art.device,
    source: '01_hard_board',
    hue: GameThemes.midnight.arrowLine,
    headline: 'Tap the arrow\nwith a clear path',
    sub: 'A neon logic puzzle.\nEighty hand-built boards.',
  ),
  (
    art: _Art.rule,
    source: '',
    hue: GameThemes.ocean.arrowLine,
    headline: 'An arrow blocks\nits whole body',
    sub: 'Not just its head — read the whole\nshape before you tap.',
  ),
  (
    art: _Art.device,
    source: '03_expert_board',
    hue: GameThemes.aurora.arrowLine,
    headline: 'Then it gets hard',
    sub:
        'Eighteen by eighteen, and a hundred\nand thirty-eight arrows in one knot.',
  ),
  (
    art: _Art.device,
    source: '04_levels',
    hue: GameThemes.midnight.accent,
    headline: 'Eighty boards,\nfour difficulties',
    sub: 'Three hearts a board. The hearts\nyou keep become your stars.',
  ),
  (
    art: _Art.triptych,
    source: '',
    hue: GameThemes.ocean.arrowLine,
    headline: 'Six colour themes',
    sub: 'One board, three of the six.\nEvery arrow, every screen, recoloured.',
  ),
  (
    art: _Art.device,
    source: '02_home',
    hue: GameThemes.aurora.accent,
    headline: 'No account.\nNo internet.',
    sub:
        'A new board every day, a streak to\nkeep, and it all stays on your phone.',
  ),
];

/// The three captures the themes panel is built from.
const _triptych = ['theme_ocean', 'theme_ember', 'theme_solar'];

/// The captures that decide the shared window. A board screen fills about
/// three fifths of the display and the rest is black, while the level list
/// and the home screen run nearly to the bottom; sizing each phone to its own
/// content gave six phones of six different heights. So the window is taken
/// from the board screens — the shape the listing is mostly made of — and
/// every other capture is slid into it, losing a little at the bottom rather
/// than changing the phone.
const _shapers = ['01_hard_board', '03_expert_board'];

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(File(path).readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

Future<ui.Image> _decode(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    fail('Missing $path — run tool/store_screenshots.dart first.');
  }
  final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

/// Where the drawn part of a capture starts and ends, as fractions of its
/// height.
typedef _Content = ({double top, double bottom});

const _Content _whole = (top: 0.0, bottom: 1.0);

/// Measured once per capture and kept, so every panel can ask about captures
/// it does not itself show.
final _measured = <String, _Content>{};

Future<_Content> _contentOf(String platform, String source) async {
  final key = '$platform/$source';
  final hit = _measured[key];
  if (hit != null) return hit;
  final image = await _decode('store/screenshots/$platform/$source.png');
  final content = await _measure(image);
  image.dispose();
  return _measured[key] = content;
}

Future<_Content> _measure(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return _whole;
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final w = image.width;
  final h = image.height;

  // Only the middle of the width is measured. The hint and grid buttons float
  // in the bottom-right corner of every board screen, a long way below the
  // board; counting them would mean "content" ran to the bottom of the
  // capture and nothing would ever be cropped.
  final from = (w * 0.15).round();
  final to = (w * 0.85).round();
  const step = 8;
  final sampled = ((to - from) / step).ceil();
  final some = math.max(3, (sampled * 0.03).round());

  var first = h;
  var last = 0;
  for (var y = 0; y < h; y++) {
    var lit = 0;
    final row = y * w * 4;
    for (var x = from; x < to; x += step) {
      final i = row + x * 4;
      // Rough luminance. The backgrounds are #000–#0A and the art is neon, so
      // anything well clear of black counts as drawn.
      final v = (bytes[i] * 54 + bytes[i + 1] * 183 + bytes[i + 2] * 19) >> 8;
      if (v > 26) lit++;
    }
    if (lit >= some) {
      if (y < first) first = y;
      last = y;
    }
  }
  if (first >= last) return _whole;
  return (top: first / h, bottom: (last + 1) / h);
}

/// Slides [content] into a window of exactly [span], anchored to the top of
/// what is drawn. A capture with more content than fits loses it from the
/// bottom; a board screen, which has less, keeps its own top edge.
_Content _window(_Content content, double span) {
  final top =
      (content.top - 0.015).clamp(0.0, math.max(0.0, 1.0 - span)).toDouble();
  return (top: top, bottom: math.min(1.0, top + span));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The rule panel draws a live board through [GameBoard], which takes its
    // colours from the active palette. Ocean's cyan keeps the arrows clear of
    // the red cross and the green tick painted over them.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'theme_id': 'ocean'});
    await AppStore.instance.init();
    await ThemeController.instance.load();
    await _loadFont('DMSans', 'assets/fonts/DMSans.ttf');
    await _loadFont(
        'MaterialIcons', '$_materialFonts/MaterialIcons-Regular.otf');
  });

  for (final entry in _devices.entries) {
    final platform = entry.key;
    final (size, dpr) = entry.value;
    final logical = size / dpr;

    group(platform, () {
      for (var i = 0; i < _panels.length; i++) {
        final panel = _panels[i];
        final index = (i + 1).toString().padLeft(2, '0');
        final name = panel.art == _Art.device ? panel.source : panel.art.name;

        testWidgets('$index $name', (tester) async {
          final shots = <ui.Image>[];
          final windows = <_Content>[];
          var aspect = 0.46;

          await tester.runAsync(() async {
            // The window is the same for every panel on this platform, so
            // every phone comes out the same size and sits in the same place.
            var span = 0.0;
            for (final source in _shapers) {
              final content = await _contentOf(platform, source);
              span = math.max(span, content.bottom + 0.06);
            }
            span = span.clamp(0.2, 1.0);

            final sources = switch (panel.art) {
              _Art.device => [panel.source],
              _Art.triptych => _triptych,
              _Art.rule => const <String>[],
            };
            for (final source in sources) {
              final image =
                  await _decode('store/screenshots/$platform/$source.png');
              shots.add(image);
              windows.add(_window(await _contentOf(platform, source), span));
            }
            aspect = size.width / (size.height * span);
          });
          for (final image in shots) {
            addTearDown(image.dispose);
          }

          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = dpr;
          addTearDown(tester.view.reset);

          // Art scales off the frame width, so one layout serves a phone and
          // a 12.9" iPad without a second set of numbers. Type cannot: a
          // tablet frame is far squarer, and a headline sized off its width
          // would eat half the picture. It takes whichever of the two
          // dimensions is tighter against the phone's proportions.
          final unit = logical.width / 430;
          final type = math.min(unit, logical.height / 935);

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(size: logical),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: _Frame(
                  panel: panel,
                  shots: shots,
                  windows: windows,
                  aspect: aspect,
                  unit: unit,
                  type: type,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 120));

          await expectLater(
            find.byType(_Frame),
            matchesGoldenFile(
                '../store/marketing/$platform/${index}_$name.png'),
          );
        });
      }
    });
  }
}

// ---------------------------------------------------------------------------
// The frame
// ---------------------------------------------------------------------------

/// The panel hue, pushed down to a background lightness. Mixing the hue into
/// black instead desaturates it on the way, and six muddy roses and mauves
/// are no better than six near-blacks.
Color _deep(Color hue, double lightness) {
  final hsl = HSLColor.fromColor(hue);
  return hsl
      .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
      .withLightness(lightness)
      .toColor();
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.panel,
    required this.shots,
    required this.windows,
    required this.aspect,
    required this.unit,
    required this.type,
  });

  final _Panel panel;
  final List<ui.Image> shots;
  final List<_Content> windows;
  final double aspect;
  final double unit;
  final double type;

  @override
  Widget build(BuildContext context) {
    final hue = panel.hue;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deep(hue, 0.17), _deep(hue, 0.085), _deep(hue, 0.04)],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150 * unit,
            right: -140 * unit,
            child: _Bloom(color: hue.withOpacity(0.45), size: 460 * unit),
          ),
          Positioned(
            bottom: -170 * unit,
            left: -150 * unit,
            child: _Bloom(color: hue.withOpacity(0.24), size: 480 * unit),
          ),
          Positioned(
            top: 300 * unit,
            left: 0,
            right: 0,
            child: Center(
              child: _Bloom(color: hue.withOpacity(0.20), size: 520 * unit),
            ),
          ),
          ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 62 * type),
                // Fixed heights, not whatever the words happen to need: a
                // one-line headline must not lift that panel's phone higher
                // up the frame than the others.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30 * type),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 93 * type,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            panel.headline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontVariations: const [
                                FontVariation('wght', 800)
                              ],
                              fontWeight: FontWeight.w800,
                              fontSize: 44 * type,
                              height: 1.06,
                              letterSpacing: -1.3 * type,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.55),
                                  blurRadius: 18 * type,
                                  offset: Offset(0, 3 * type),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * type),
                      SizedBox(
                        height: 50 * type,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            panel.sub,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontVariations: const [
                                FontVariation('wght', 500)
                              ],
                              fontSize: 18 * type,
                              height: 1.38,
                              letterSpacing: -0.1 * type,
                              color: Colors.white.withOpacity(0.74),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40 * type),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final (w, h) = _fit(box, aspect);
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: _Body(
                            screen: _screen(),
                            aspect: aspect,
                            hue: hue,
                            unit: unit,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _screen() {
    switch (panel.art) {
      case _Art.device:
      case _Art.triptych:
        return CustomPaint(painter: _Slice(shots: shots, windows: windows));
      case _Art.rule:
        return const _RuleScreen();
    }
  }
}

/// Fill the height the headline left over, but never run wider than the
/// frame — a windowed capture is much squarer than the raw one, so it is
/// usually the width that binds. The same box always gives the same answer,
/// which is what keeps every panel's phone identical.
(double, double) _fit(BoxConstraints box, double aspect) {
  var w =
      (box.maxHeight * aspect).clamp(box.maxWidth * 0.70, box.maxWidth * 0.94);
  var h = w / aspect;
  if (h > box.maxHeight) {
    h = box.maxHeight;
    w = h * aspect;
  }
  return (w, h);
}

/// The phone. The old version pasted a whole capture into a rounded rectangle
/// with a hairline border; a third of it was the empty black under the board,
/// and the hairline read as a crop mark rather than a device.
class _Body extends StatelessWidget {
  const _Body({
    required this.screen,
    required this.aspect,
    required this.hue,
    required this.unit,
  });

  final Widget screen;
  final double aspect;
  final Color hue;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final bezel = 7 * unit;
    final outer = BorderRadius.circular(44 * unit);
    final inner = BorderRadius.circular(44 * unit - bezel);

    return AspectRatio(
      aspectRatio: aspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: outer,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A3F4D), Color(0xFF141720), Color(0xFF2A2E3A)],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            // Two passes: a tight one that seats the body on the background
            // and a wide soft one that lifts it off.
            BoxShadow(
              color: Colors.black.withOpacity(0.70),
              blurRadius: 26 * unit,
              offset: Offset(0, 10 * unit),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 80 * unit,
              spreadRadius: 6 * unit,
              offset: Offset(0, 34 * unit),
            ),
            // The screen's own light, spilling past the bezel.
            BoxShadow(
              color: hue.withOpacity(0.30),
              blurRadius: 90 * unit,
              spreadRadius: -10 * unit,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(bezel),
          child: ClipRRect(
            borderRadius: inner,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                screen,
                // A lit edge, the way a glass front catches the light.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: inner,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1.0 * unit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a horizontal slice of each image into its own vertical band of the
/// screen. With one image that is a plain crop; with three captures of the
/// same board under three palettes, the screens line up across the seams and
/// the board simply changes colour as it crosses them.
class _Slice extends CustomPainter {
  _Slice({required this.shots, required this.windows});

  final List<ui.Image> shots;
  final List<_Content> windows;

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width / shots.length;
    for (var i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final window = windows[i];
      final h = shot.height.toDouble();
      final src = Rect.fromLTRB(
        0,
        h * window.top,
        shot.width.toDouble(),
        h * window.bottom,
      );
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(i * bandWidth, 0, bandWidth, size.height));
      canvas.drawImageRect(
        shot,
        src,
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }
    // A lit seam, so the colour change reads as deliberate rather than as a
    // rendering fault.
    for (var i = 1; i < shots.length; i++) {
      final x = i * bandWidth;
      canvas.drawRect(
        Rect.fromLTWH(
            x - size.width * 0.003, 0, size.width * 0.006, size.height),
        Paint()..color = Colors.white.withOpacity(0.12),
      );
    }
  }

  @override
  bool shouldRepaint(_Slice old) =>
      old.shots != shots || old.windows != windows;
}

// ---------------------------------------------------------------------------
// The rule
// ---------------------------------------------------------------------------

/// A five-by-five board built for one job: showing that an arrow's *body*
/// stops another arrow leaving. The old panel in this slot was a photograph
/// of the How to Play screen — five paragraphs of fourteen-point text, which
/// at thumbnail size is a grey rectangle and at full size is homework.
///
///   * the tall arrow runs up column two, so its body covers (2,2);
///   * the arrow at (2,3) points left into that body and cannot move;
///   * the arrow at (4,1) points left into empty cells and leaves.
final _ruleLevel = LevelData(
  id: 900,
  rows: 5,
  cols: 5,
  difficulty: 'Easy',
  arrows: [
    ArrowPiece(id: 1, row: 0, col: 2, direction: Direction.up, length: 4),
    ArrowPiece(id: 2, row: 2, col: 3, direction: Direction.left, length: 2),
    ArrowPiece(id: 3, row: 4, col: 1, direction: Direction.left, length: 2),
    // Three more so the board reads as a board. None of them touches the two
    // cells the marks land on, and each has a clear run of its own.
    ArrowPiece(id: 4, row: 0, col: 4, direction: Direction.right, length: 2),
    ArrowPiece(id: 5, row: 4, col: 4, direction: Direction.down, length: 2),
    ArrowPiece(id: 6, row: 1, col: 0, direction: Direction.left, length: 2),
  ],
);

/// The rule, laid out as a screen so it sits in the same phone as the rest of
/// the listing rather than floating on the background as a diagram.
class _RuleScreen extends StatelessWidget {
  const _RuleScreen();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Everything here scales off the screen it is drawn on, not off the
        // frame, so the phone can be any size.
        final w = box.maxWidth;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.055),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: w * 0.89,
                height: w * 0.89,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GameBoard(
                      session: PlaySession(_ruleLevel),
                      onTap: (_) {},
                      showGrid: true,
                    ),
                    CustomPaint(painter: _RuleMarks()),
                  ],
                ),
              ),
              SizedBox(height: w * 0.075),
              _Legend(
                ok: false,
                text: 'Blocked — its body is in the way',
                scale: w,
              ),
              SizedBox(height: w * 0.035),
              _Legend(
                ok: true,
                text: 'Clear — a clean run to the edge',
                scale: w,
              ),
            ],
          ),
        );
      },
    );
  }
}

const _blocked = Color(0xFFFF4D6D);
const _clear = Color(0xFF3DDC97);

/// Paints the two marks over the rule board. [GameBoard] centres a square
/// board inside a square box, so a cell is exactly a fifth of the box.
class _RuleMarks extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.min(size.width / 5, size.height / 5);
    Offset centre(num row, num col) =>
        Offset((col + 0.5) * cell, (row + 0.5) * cell);

    // Drawn as an outline over a barely-there wash: a solid highlight hides
    // the very arrow it is pointing at.
    final capsule = RRect.fromRectAndRadius(
      Rect.fromPoints(centre(0, 2), centre(3, 2)).inflate(cell * 0.40),
      Radius.circular(cell * 0.40),
    );
    canvas.drawRRect(capsule, Paint()..color = Colors.white.withOpacity(0.10));
    _dash(
      canvas,
      Path()..addRRect(capsule),
      color: Colors.white.withOpacity(0.80),
      width: cell * 0.055,
      dash: cell * 0.17,
      gap: cell * 0.12,
    );

    // Where that body stops the arrow at (2,3).
    final hit = centre(2, 2);
    final ring = cell * 0.40;
    _halo(canvas, hit, ring, cell, _blocked);
    canvas.drawCircle(hit, ring, Paint()..color = _blocked);
    final cross = Paint()
      ..color = Colors.white
      ..strokeWidth = cell * 0.11
      ..strokeCap = StrokeCap.round;
    final arm = ring * 0.44;
    canvas.drawLine(hit + Offset(-arm, -arm), hit + Offset(arm, arm), cross);
    canvas.drawLine(hit + Offset(arm, -arm), hit + Offset(-arm, arm), cross);

    // The corridor the arrow at (4,1) runs down, and the tick at the edge it
    // reaches.
    final exit = Path()
      ..moveTo(centre(4, 1).dx - cell * 0.42, centre(4, 1).dy)
      ..lineTo(0, centre(4, 1).dy);
    _dash(
      canvas,
      exit,
      color: _clear.withOpacity(0.85),
      width: cell * 0.16,
      dash: cell * 0.18,
      gap: cell * 0.14,
    );
    final tick = centre(4, 0);
    _halo(canvas, tick, ring, cell, _clear);
    canvas.drawCircle(tick, ring, Paint()..color = _clear);
    canvas.drawPath(
      Path()
        ..moveTo(tick.dx - ring * 0.42, tick.dy + ring * 0.02)
        ..lineTo(tick.dx - ring * 0.10, tick.dy + ring * 0.34)
        ..lineTo(tick.dx + ring * 0.44, tick.dy - ring * 0.34),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _halo(Canvas canvas, Offset at, double ring, double cell, Color color) {
    canvas.drawCircle(
      at,
      ring * 1.5,
      Paint()
        ..color = color.withOpacity(0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.30),
    );
  }

  void _dash(
    Canvas canvas,
    Path path, {
    required Color color,
    required double width,
    required double dash,
    required double gap,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = math.min(at + dash, metric.length);
        canvas.drawPath(metric.extractPath(at, end), paint);
        at = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_RuleMarks old) => false;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.ok, required this.text, required this.scale});

  final bool ok;
  final String text;

  /// The width of the screen this sits on.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colour = ok ? _clear : _blocked;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: scale * 0.045, vertical: scale * 0.032),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(scale * 0.05),
        border:
            Border.all(color: colour.withOpacity(0.45), width: scale * 0.004),
      ),
      child: Row(
        children: [
          Container(
            width: scale * 0.034,
            height: scale * 0.034,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colour),
          ),
          SizedBox(width: scale * 0.030),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontVariations: const [FontVariation('wght', 600)],
                fontSize: scale * 0.042,
                height: 1.25,
                color: Colors.white.withOpacity(0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}
