// Turns the raw screen captures into the framed, captioned images that
// actually go on a store listing. Run it after tool/store_screenshots.dart:
//
//   flutter test tool/store_marketing.dart --update-goldens
//
// Output lands in store/marketing/{ios,ipad,android}/.
//
// A raw capture tells someone what the app looks like. A listing image has to
// tell them what it is before they scroll past — the first two are all most
// people ever see, so each one carries a single claim and the screen that
// backs it up.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrows_game/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _materialFonts =
    '/Users/mac/development/flutter/bin/cache/artifacts/material_fonts';

/// Same sizes the raw captures use, so these drop straight into the store.
const _devices = <String, (Size, double)>{
  'ios': (Size(1290, 2796), 3),
  'ipad': (Size(2048, 2732), 2),
  'android': (Size(1080, 2400), 3),
  'android_tablet': (Size(1600, 2560), 2),
};

/// The listing, in order. The first two do the selling; the rest answer the
/// questions someone has once they are interested.
const _panels = <({String source, String headline, String sub})>[
  (
    source: '01_hard_board',
    headline: 'Tap the arrow\nwith a clear path',
    sub: 'Get the order wrong and it slams\ninto whatever is in the way',
  ),
  (
    source: '06_how_to_play',
    headline: 'One rule to learn',
    sub: 'An arrow blocks every cell along its\nbody — not just its head',
  ),
  (
    source: '03_expert_board',
    headline: 'Then it gets hard',
    sub: 'Boards climb to eighty-nine arrows',
  ),
  (
    source: '04_levels',
    headline: 'Eighty hand-built\nboards',
    sub: 'Plus a new one every day,\nwith a streak to keep',
  ),
  (
    source: '05_themes',
    headline: 'Play in your\nown colours',
    sub: 'Six themes, three of them free',
  ),
  (
    source: '02_home',
    headline: 'No account.\nNo internet.',
    sub: 'Everything stays on your phone',
  ),
];

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(File(path).readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
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

        testWidgets('$index ${panel.source}', (tester) async {
          final file = File('store/screenshots/$platform/${panel.source}.png');
          if (!file.existsSync()) {
            fail('Missing ${file.path} — run tool/store_screenshots.dart '
                'first.');
          }

          // Decode by hand rather than going through an ImageProvider: the
          // image cache and a golden test do not agree on when a frame is
          // ready, and this is deterministic.
          late final ui.Image shot;
          await tester.runAsync(() async {
            final codec =
                await ui.instantiateImageCodec(file.readAsBytesSync());
            shot = (await codec.getNextFrame()).image;
          });
          addTearDown(shot.dispose);

          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = dpr;
          addTearDown(tester.view.reset);

          // Everything scales off the frame width, so one layout serves a
          // phone and a 12.9" iPad without a second set of numbers.
          final unit = logical.width / 430;

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(size: logical),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: _Panel(
                  shot: shot,
                  headline: panel.headline,
                  sub: panel.sub,
                  unit: unit,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          await expectLater(
            find.byType(_Panel),
            matchesGoldenFile(
                '../store/marketing/$platform/${index}_${panel.source}.png'),
          );
        });
      }
    });
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.shot,
    required this.headline,
    required this.sub,
    required this.unit,
  });

  final ui.Image shot;
  final String headline;
  final String sub;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Lifted well above the app's own background. The captures are almost
        // black, and on a near-black backdrop the whole image reads as one
        // dark rectangle in a search result — the device has to sit *on*
        // something for the eye to find it.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B2A6B),
            const Color(0xFF16326E),
            AppColors.bgMid,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80 * unit,
            right: -70 * unit,
            child: _Bloom(
                color: AppColors.accent.withOpacity(0.40), size: 340 * unit),
          ),
          Positioned(
            bottom: -60 * unit,
            left: -80 * unit,
            child: _Bloom(
                color: const Color(0xFF4FD1C5).withOpacity(0.22),
                size: 380 * unit),
          ),
          // A pool of light directly behind the device so its edges separate
          // from the background all the way down.
          Positioned(
            top: 200 * unit,
            left: 0,
            right: 0,
            child: Center(
              child: _Bloom(
                  color: AppColors.accent.withOpacity(0.22), size: 460 * unit),
            ),
          ),
          // Clipped so the screen can run off the bottom edge instead of being
          // shrunk to fit — it reads as a device you are holding, and it keeps
          // the caption large.
          ClipRect(
            child: Column(
              children: [
                SizedBox(height: 54 * unit),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26 * unit),
                  child: Column(
                    children: [
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontVariations: const [FontVariation('wght', 700)],
                          fontWeight: FontWeight.w700,
                          fontSize: 34 * unit,
                          height: 1.14,
                          letterSpacing: -0.6 * unit,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 12 * unit),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 15 * unit,
                          height: 1.42,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 34 * unit),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      widthFactor: 0.80,
                      child: _Device(shot: shot, unit: unit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The capture, given a rounded body and a rim so it reads as a screen rather
/// than a pasted rectangle.
class _Device extends StatelessWidget {
  const _Device({required this.shot, required this.unit});

  final ui.Image shot;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26 * unit);
    return AspectRatio(
      aspectRatio: shot.width / shot.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 40 * unit,
              spreadRadius: 2 * unit,
              offset: Offset(0, 16 * unit),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Top-aligned: the frame is shorter than the capture so that the
              // screen can bleed off the bottom, and cropping from the centre
              // would take the header with it.
              RawImage(
                image: shot,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              // A hairline rim; without it the dark capture melts into the
              // dark background.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                    width: 1.2 * unit,
                  ),
                ),
              ),
            ],
          ),
        ),
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
