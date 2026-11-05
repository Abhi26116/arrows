// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Clear the board. Order is everything.';

  @override
  String get statStars => 'stars';

  @override
  String get statStreak => 'streak';

  @override
  String get statCleared => 'cleared';

  @override
  String actionContinue(int level) {
    return 'Continue · $level';
  }

  @override
  String get actionStart => 'Start playing';

  @override
  String get navDaily => 'Daily';

  @override
  String navDailyBest(String stars) {
    return 'Daily · $stars';
  }

  @override
  String get navLevels => 'Levels';

  @override
  String get navThemes => 'Themes';

  @override
  String get navStreak => 'Streak';

  @override
  String get navHowTo => 'How to';

  @override
  String get tooltipShop => 'Shop';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipBack => 'Back';

  @override
  String get levelsTitle => 'Levels';

  @override
  String levelsStarsOf(int earned, int total) {
    return '$earned of $total';
  }

  @override
  String get gameTooltipUndo => 'Undo';

  @override
  String get gameTooltipHint => 'Hint';

  @override
  String get gameTooltipRestart => 'Restart board';

  @override
  String get gameTooltipShowGrid => 'Show grid';

  @override
  String get gameTooltipHideGrid => 'Hide grid';

  @override
  String gameLevelNumber(int id) {
    return 'LEVEL $id';
  }

  @override
  String get gameToday => 'TODAY';

  @override
  String get gameCleared => 'CLEARED';

  @override
  String get gameDailyClear => 'DAILY CLEAR';

  @override
  String gameLevelLabel(int id) {
    return 'Level $id';
  }

  @override
  String gameMissHint(int miss, int hint) {
    return '$miss miss · $hint hint';
  }

  @override
  String get gameReplay => 'Replay';

  @override
  String get gameNext => 'Next';

  @override
  String get gameDone => 'Done';

  @override
  String get gameOutOfHearts => 'OUT OF HEARTS';

  @override
  String gameArrowsCleared(int cleared, int total) {
    return '$cleared of $total arrows cleared';
  }

  @override
  String get gameOverTitle => 'Out of hearts';

  @override
  String get gameOverBody =>
      'The board resets. Watch a short ad for one more heart, or try again from the start.';

  @override
  String get gameExtraHeart => 'Extra heart';

  @override
  String get gameRetry => 'Retry';

  @override
  String get gameQuit => 'Quit';

  @override
  String get gameRestartTitle => 'Restart board?';

  @override
  String get gameRestartBody => 'Every arrow comes back and your hearts reset.';

  @override
  String get gameRestart => 'Restart';

  @override
  String get gameCancel => 'Cancel';

  @override
  String get gameLeaveTitle => 'Leave this board?';

  @override
  String get gameLeaveBody => 'It starts from the beginning next time.';

  @override
  String get gameKeepPlaying => 'Keep playing';

  @override
  String get gameLeave => 'Leave';

  @override
  String get gameNoAdReady => 'No ad ready — try again.';

  @override
  String get gameHintAdHint =>
      'Watch a short ad in Shop for bonus hints, or try again.';

  @override
  String get howToTitle => 'How to Play';

  @override
  String get howToStep1Title => 'Tap an arrow';

  @override
  String get howToStep1Body =>
      'It flies in the direction it points — up, down, left, or right.';

  @override
  String get howToStep2Title => 'Clear path = gone';

  @override
  String get howToStep2Body =>
      'If nothing sits on the straight path from its head to the edge, the whole arrow slides off — bends and all.';

  @override
  String get howToStep3Title => 'Bodies can bend';

  @override
  String get howToStep3Body =>
      'An arrow blocks every cell it covers, head to tail, and some bodies turn corners. Follow the whole shape before you tap.';

  @override
  String get howToStep4Title => 'Three hearts';

  @override
  String get howToStep4Body =>
      'A blocked tap costs a heart. Lose all three and the board resets — hearts left become your stars.';

  @override
  String get howToStep5Title => 'Clear them all';

  @override
  String get howToStep5Body =>
      'Empty the board to win. Tap the grid button to show cell lines, or Hint when you are stuck.';

  @override
  String get howToDone => 'Done';

  @override
  String get howToGotIt => 'Got it — Play';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundSub => 'Clear, blocked, and win cues';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsSub => 'Tap and block feedback';

  @override
  String get settingsGrid => 'Cell grid';

  @override
  String get settingsGridSub => 'Show the grid behind the arrows';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsShop => 'Shop';

  @override
  String get settingsShopSub => 'Remove ads, theme pack, bonus hints';

  @override
  String get settingsThemes => 'Themes';

  @override
  String get settingsThemesSub => 'Six palettes for the board';

  @override
  String get settingsPrivacy => 'Privacy options';

  @override
  String get settingsPrivacySub => 'Change your ad consent choices';

  @override
  String get settingsReset => 'Reset progress';

  @override
  String get settingsResetSub => 'Start over from the first board';

  @override
  String get settingsResetTitle => 'Reset progress?';

  @override
  String get settingsResetBody =>
      'Levels lock again and stars go back to zero. Purchases, themes, and your daily streak are kept.';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get settingsResetDone => 'Progress reset';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsStatStars => 'Stars';

  @override
  String get settingsStatCleared => 'Cleared';

  @override
  String get settingsStatReached => 'Reached';

  @override
  String get settingsAbout => 'About';

  @override
  String get themesTitle => 'Themes';

  @override
  String get themesUnlockInShop => 'Unlock Theme Pack in Shop';

  @override
  String get themesFree => 'Free';

  @override
  String get themesActive => 'Active';

  @override
  String get themesPremium => 'Premium';

  @override
  String get themesPremiumPack => 'Premium · Theme Pack';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopRemoveAds => 'Remove Ads';

  @override
  String get shopRemoveAdsBody =>
      'No banners or interstitials. Rewarded hints stay free.';

  @override
  String get shopThemePack => 'Theme Pack';

  @override
  String get shopThemePackBody =>
      'Unlock Aurora, Noir, and Solar themes forever.';

  @override
  String get shopBonusHint => 'Bonus Hint';

  @override
  String shopBonusHintWatch(int ready) {
    return 'Watch a short ad for a bonus hint ($ready ready).';
  }

  @override
  String shopBonusHintFree(int ready) {
    return 'Ads are removed, so hints are on the house ($ready ready).';
  }

  @override
  String get shopWatchAnAd => 'Watch an ad';

  @override
  String get shopFree => 'Free';

  @override
  String get shopNonConsumable => 'Non-consumable';

  @override
  String get shopOwned => 'Owned';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopWatch => 'Watch';

  @override
  String get shopClaim => 'Claim';

  @override
  String get shopRestore => 'Restore purchases';

  @override
  String get shopRestoreNote =>
      'Purchases are tied to your store account and can be restored on any device you sign in to.';

  @override
  String get shopHintAdded => 'Bonus hint added';

  @override
  String get shopAdNotReady => 'Ad not ready — try again in a moment.';

  @override
  String get dailyTitle => 'Daily';

  @override
  String dailyStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get dailyEmpty => 'Play today\'s board and it shows up here.';

  @override
  String get dailyPlayToday => 'Play today';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageOnboardingTitle => 'Choose your language';

  @override
  String get languageOnboardingBody =>
      'You can change this any time in Settings.';

  @override
  String get languageContinue => 'Continue';

  @override
  String get reviewTitle => 'Enjoying Arrows?';

  @override
  String get reviewBody =>
      'A rating helps other people find the game. It takes a moment.';

  @override
  String get reviewRate => 'Rate it';

  @override
  String get reviewLater => 'Not now';

  @override
  String get updateTitle => 'Update available';

  @override
  String updateBody(String version) {
    return 'Version $version is out. Update for the latest boards and fixes.';
  }

  @override
  String get updateNow => 'Update';

  @override
  String get updateLater => 'Later';
}
