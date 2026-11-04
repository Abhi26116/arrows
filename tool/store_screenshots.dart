// Generates store-ready screenshots at the exact pixel sizes Apple and Google
// ask for. Not part of the normal test suite — run it deliberately:
//
//   flutter test tool/store_screenshots.dart --update-goldens \
//     --dart-define=SCREENSHOT_MODE=true
//
// SCREENSHOT_MODE keeps kDebugMode-only developer notes out of the images —
// goldens always run in debug, so without it they render into the shots.
//
// Output lands in store/screenshots/{ios,ipad,android}/. 01-06 are the listing
// shots; iap_review_shop is the separate one both stores ask for when they
// review the in-app purchases.
import 'dart:convert';
import 'dart:io';

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/main.dart';
import 'package:arrows_game/screens/game_screen.dart';
import 'package:arrows_game/screens/home_screen.dart';
import 'package:arrows_game/screens/how_to_play_screen.dart';
import 'package:arrows_game/screens/level_select_screen.dart';
import 'package:arrows_game/screens/shop_screen.dart';
import 'package:arrows_game/services/iap_service.dart';
import 'package:arrows_game/screens/themes_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:arrows_game/theme/theme_controller.dart';
import 'package:arrows_game/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _materialFonts =
    '/Users/mac/development/flutter/bin/cache/artifacts/material_fonts';

/// iPhone 6.3" (1206x2622 — what App Store Connect now asks for under
/// "iPhone with Dynamic Island"; it rejects the old 1290x2796), iPad Pro 12.9"
/// (2048x2732 — the size the App Store asks for when an app supports iPad) and
/// a common Android phone.
const _devices = <String, (Size, double)>{
  'ios': (Size(1206, 2622), 3),
  'ipad': (Size(2048, 2732), 2),
  'android': (Size(1080, 2400), 3),
  // Play asks for tablet shots separately, and without them the listing is
  // marked down for large screens however well the app behaves on one.
  'android_tablet': (Size(1600, 2560), 2),
};

/// `days` ago, in the key format [AppStore] writes.
String _dateKey(int days) {
  final n = DateTime.now().subtract(Duration(days: days));
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

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
      // Without this the home screen's first frame pushes the onboarding
      // language picker over itself, and the "02_home" capture is a list of
      // languages rather than the game.
      'settings_chose_language': true,
      'theme_id': 'midnight',
      // A streak worth showing on the home screen's stat row.
      'daily_date': _dateKey(0),
      'best_daily': 3,
      'daily_history': jsonEncode([
        for (var i = 0; i < 14; i++)
          {'date': _dateKey(i), 'stars': i % 4 == 0 ? 2 : 3},
      ]),
      for (var i = 1; i <= 33; i++) 'level_stars_$i': i % 3 == 0 ? 2 : 3,
    });
    await ThemeController.instance.load();
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The same wrapper the real app installs, so the tablet shots show the
        // enlarged interface an iPad actually gets rather than a phone one.
        builder: (context, child) => TabletScale(child: child!),
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

    /// Same capture, rendered under a different palette. Each theme owns a
    /// signature neon colour, and a listing that only ever shows one of them
    /// throws away the game's best asset.
    Future<void> themedShot(
      WidgetTester tester,
      String themeId,
      Widget page,
      String name,
    ) async {
      final owned = AppStore.instance.themePackOwned;
      // setTheme refuses the premium palettes unless the pack is owned, and
      // for a screenshot it is the colour that matters, not the entitlement.
      await AppStore.instance.setThemePackOwned(true);
      await ThemeController.instance.setTheme(themeId);
      addTearDown(() async {
        await AppStore.instance.setThemePackOwned(owned);
        await ThemeController.instance.setTheme('midnight');
      });
      await shot(tester, page, name);
    }

    group(platform, () {
      testWidgets('01 hard board', (t) async {
        await shot(
            t, GameScreen(customLevel: LevelCatalog.byId(56)), '01_hard_board');
      });
      testWidgets('02 home', (t) => shot(t, const HomeScreen(), '02_home'));
      testWidgets('03 expert board', (t) async {
        // Aurora's violet, so the carousel does not run pink all the way
        // down — this is the shot that sits third.
        await themedShot(t, 'aurora',
            GameScreen(customLevel: LevelCatalog.byId(78)), '03_expert_board');
      });
      // The three crops the themes panel is built from: one board, three
      // signature colours, as far apart in hue as the palettes go.
      for (final (id, level) in const [
        ('ocean', 30),
        ('ember', 30),
        ('solar', 30),
      ]) {
        testWidgets('theme $id', (t) async {
          await themedShot(t, id, GameScreen(customLevel: LevelCatalog.byId(level)),
              'theme_$id');
        });
      }
      testWidgets('04 levels', (t) async {
        await shot(t, const LevelSelectScreen(), '04_levels');
      });
      testWidgets('05 themes', (t) async {
        await shot(t, const ThemesScreen(), '05_themes');
      });
      testWidgets('06 how to play', (t) async {
        await shot(t, const HowToPlayScreen(), '06_how_to_play');
      });
      // Not a store listing shot — this is the one Apple and Google ask for
      // when reviewing the in-app purchases, so both products have to be
      // showing as still buyable rather than owned.
      testWidgets('iap review shop', (t) async {
        // With ads back on, the screen builds an AdBanner and the ads SDK is
        // not present under `flutter test`; swallow its channel calls so the
        // banner just renders empty.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_mobile_ads'),
          (call) async => null,
        );
        // setUp marks both as owned so the listing shots have no ad banner.
        // Go through AppStore's own setters: it caches SharedPreferences on
        // first init, so a freshly mocked instance would not reach it.
        await AppStore.instance.setRemoveAdsOwned(false);
        await AppStore.instance.setThemePackOwned(false);
        // AppStore holds the SharedPreferences instance it cached on the very
        // first init, so setUp's re-mock cannot undo this — put it back here or
        // every later shot renders an ad banner.
        addTearDown(() async {
          // Back to exactly what setUp establishes: ads removed (so no banner
          // in the listing shots) and the theme pack still locked (so the
          // themes shot keeps showing its padlocks and upsell).
          await AppStore.instance.setRemoveAdsOwned(true);
          await AppStore.instance.setThemePackOwned(false);
        });
        // The store is not reachable under `flutter test`, so prices would
        // read "Non-consumable". Stand in the real ones.
        IapService.instance.products = [
          ProductDetails(
            id: 'arrows_remove_ads',
            title: 'Remove Ads',
            description: 'No banners or interstitials.',
            price: r'$1.99',
            rawPrice: 1.99,
            currencyCode: 'USD',
            currencySymbol: r'$',
          ),
          ProductDetails(
            id: 'arrows_theme_pack',
            title: 'Theme Pack',
            description: 'Aurora, Noir and Solar themes.',
            price: r'$0.99',
            rawPrice: 0.99,
            currencyCode: 'USD',
            currencySymbol: r'$',
          ),
        ];
        addTearDown(() => IapService.instance.products = []);
        await shot(t, const ShopScreen(), 'iap_review_shop');
      });
    });
  }
}
