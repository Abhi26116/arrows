import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrows_game/config/app_config.dart';
import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/models/level.dart';
import 'package:arrows_game/services/iap_service.dart';
import 'package:arrows_game/services/review_service.dart';
import 'package:arrows_game/theme/game_themes.dart';
import 'package:arrows_game/theme/theme_controller.dart';

/// FNV-1a over every placement, so any change to a board changes the value.
String fingerprint(Iterable<LevelData> levels) {
  final buf = StringBuffer();
  for (final l in levels) {
    buf.write('${l.id}:${l.rows}x${l.cols}:${l.label}:${l.difficulty}|');
    for (final a in l.arrows) {
      buf.write('${a.row},${a.col},${a.direction.index},${a.length},'
          '${a.bends.map((b) => '${b.$1.index}/${b.$2}').join('.')};');
    }
    for (final c in l.captives) {
      buf.write('c${c.row},${c.col},${c.span},${c.kind.index};');
    }
  }
  var h = 0x811c9dc5;
  for (final u in buf.toString().codeUnits) {
    h ^= u;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16);
}

/// Pinned when 1.1 was cut.
const chapterFingerprint = '1316bc2c';

void main() {
  group('levels', () {
    test('boards 1-80 are exactly the ones 1.0 shipped', () {
      // Taken from the 1.0.1 catalog. Saved stars are keyed by level id, so
      // if this moves, every player's progress now points at other boards.
      expect(
        fingerprint([for (var id = 1; id <= 80; id++) LevelCatalog.byId(id)]),
        'd52b00d5',
      );
    });

    test('the catalog holds 600 boards in named packs with no gaps', () {
      expect(LevelCatalog.count, 600);
      final packs = LevelCatalog.packs;
      expect(packs.first.startId, 1);
      expect(packs.last.endId, LevelCatalog.count);
      for (var i = 1; i < packs.length; i++) {
        expect(packs[i].startId, packs[i - 1].endId + 1);
      }
    });

    test('a chapter board is the same every time it is generated', () {
      for (final id in [81, 300, 600]) {
        expect(
          fingerprint([LevelCatalog.generateChapterLevel(id)]),
          fingerprint([LevelCatalog.byId(id)]),
        );
      }
      expect(fingerprint([LevelCatalog.byId(81)]),
          isNot(fingerprint([LevelCatalog.byId(82)])));
    });

    test('boards 81-600 stay the boards 1.1 shipped', () {
      // Same reason as the 1-80 check: a later change to the chapter tiers or
      // seeds would move players' stars onto different boards.
      expect(
        fingerprint([for (var id = 81; id <= 600; id++) LevelCatalog.byId(id)]),
        chapterFingerprint,
      );
    });

    test('each chapter climbs from a breather to an Expert finish', () {
      for (var chapter = 0; chapter < LevelCatalog.chapterNames.length; chapter++) {
        final start = LevelCatalog.legacyCount + chapter * LevelCatalog.chapterSize + 1;
        final first = LevelCatalog.byId(start);
        final last = LevelCatalog.byId(start + LevelCatalog.chapterSize - 1);
        expect(first.rows, lessThan(last.rows), reason: 'chapter $chapter');
        expect(last.difficulty, 'Expert', reason: 'chapter $chapter');
        expect(first.difficulty, isNot('Expert'), reason: 'chapter $chapter');
        expect(first.label, startsWith(LevelCatalog.chapterNames[chapter]));
      }
    });
  });

  group('store', () {
    // AppStore caches the SharedPreferences instance it first gets, and
    // setMockInitialValues swaps in a new one — so mock once, then wipe that
    // same instance before every test.
    setUpAll(() => SharedPreferences.setMockInitialValues({}));
    setUp(() async {
      await AppStore.instance.init();
      await (await SharedPreferences.getInstance()).clear();
    });

    test('a purchase pays out once even if the store delivers it twice', () async {
      expect(await AppStore.instance.claimPurchase('txn-1'), isTrue);
      expect(await AppStore.instance.claimPurchase('txn-1'), isFalse);
      expect(await AppStore.instance.claimPurchase('txn-2'), isTrue);
    });

    test('the bundle unlocks both and adds its hints only once', () async {
      await IapService.instance.unlockForTesting(AppConfig.iapBundle);
      expect(AppStore.instance.removeAdsOwned, isTrue);
      expect(AppStore.instance.themePackOwned, isTrue);
      expect(AppStore.instance.bonusHints, 30);
      await IapService.instance.unlockForTesting(AppConfig.iapBundle);
      expect(AppStore.instance.bonusHints, 30);
    });

    test('hint packs add their hints every time they are bought', () async {
      await IapService.instance.unlockForTesting(AppConfig.iapHints15);
      await IapService.instance.unlockForTesting(AppConfig.iapHints15);
      await IapService.instance.unlockForTesting(AppConfig.iapHints60);
      expect(AppStore.instance.bonusHints, 90);
    });

    test('remove ads keeps rewarded ads and comes with 10 hints', () async {
      await IapService.instance.unlockForTesting(AppConfig.iapRemoveAds);
      expect(AppStore.instance.adsEnabled, isFalse);
      expect(AppStore.instance.bonusHints, 10);
    });

    test('a theme trial opens one premium theme until it runs out', () async {
      final premium = GameThemes.all.where((t) => t.premium).toList();
      final controller = ThemeController.instance;
      expect(controller.canUse(premium.first), isFalse);

      await AppStore.instance
          .startThemeTrial(premium.first.id, const Duration(hours: 24));
      expect(controller.canUse(premium.first), isTrue);
      expect(controller.canUse(premium.last), isFalse);

      await AppStore.instance
          .startThemeTrial(premium.first.id, const Duration(seconds: -1));
      expect(controller.canUse(premium.first), isFalse);
    });

    test('the rating ask comes early, then at milestones, spaced out', () async {
      final review = ReviewService.instance;
      // Tutorial only: never.
      expect(await review.shouldAsk(totalCleared: 6, stars: 3), isFalse);
      // A perfect win just past the tutorial.
      expect(await review.shouldAsk(totalCleared: 7, stars: 3), isTrue);
      expect(await review.shouldAsk(totalCleared: 7, stars: 2), isFalse);
      // Any win a little later.
      expect(await review.shouldAsk(totalCleared: 10, stars: 1), isTrue);

      // After one ask: quiet for three weeks, then only at 30 cleared.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('review_ask_count', 1);
      await prefs.setInt('review_asked_at', DateTime.now().millisecondsSinceEpoch);
      expect(await review.shouldAsk(totalCleared: 40, stars: 3), isFalse);
      await prefs.setInt(
        'review_asked_at',
        DateTime.now().subtract(const Duration(days: 22)).millisecondsSinceEpoch,
      );
      expect(await review.shouldAsk(totalCleared: 29, stars: 3), isFalse);
      expect(await review.shouldAsk(totalCleared: 30, stars: 1), isTrue);

      // Three asks is the most there will ever be.
      await prefs.setInt('review_ask_count', 3);
      expect(await review.shouldAsk(totalCleared: 500, stars: 3), isFalse);
    });
  });
}
