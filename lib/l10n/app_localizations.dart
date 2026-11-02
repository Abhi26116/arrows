import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('id'),
    Locale('pt')
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Clear the board. Order is everything.'**
  String get appTagline;

  /// No description provided for @statStars.
  ///
  /// In en, this message translates to:
  /// **'stars'**
  String get statStars;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'streak'**
  String get statStreak;

  /// No description provided for @statCleared.
  ///
  /// In en, this message translates to:
  /// **'cleared'**
  String get statCleared;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue · {level}'**
  String actionContinue(int level);

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start playing'**
  String get actionStart;

  /// No description provided for @navDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get navDaily;

  /// No description provided for @navDailyBest.
  ///
  /// In en, this message translates to:
  /// **'Daily · {stars}'**
  String navDailyBest(String stars);

  /// No description provided for @navLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get navLevels;

  /// No description provided for @navThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get navThemes;

  /// No description provided for @navStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get navStreak;

  /// No description provided for @navHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to'**
  String get navHowTo;

  /// No description provided for @tooltipShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tooltipShop;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tooltipBack;

  /// No description provided for @levelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsTitle;

  /// No description provided for @levelsStarsOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total}'**
  String levelsStarsOf(int earned, int total);

  /// No description provided for @gameTooltipUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gameTooltipUndo;

  /// No description provided for @gameTooltipHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get gameTooltipHint;

  /// No description provided for @gameTooltipRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart board'**
  String get gameTooltipRestart;

  /// No description provided for @gameTooltipShowGrid.
  ///
  /// In en, this message translates to:
  /// **'Show grid'**
  String get gameTooltipShowGrid;

  /// No description provided for @gameTooltipHideGrid.
  ///
  /// In en, this message translates to:
  /// **'Hide grid'**
  String get gameTooltipHideGrid;

  /// No description provided for @gameLevelNumber.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {id}'**
  String gameLevelNumber(int id);

  /// No description provided for @gameToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get gameToday;

  /// No description provided for @gameCleared.
  ///
  /// In en, this message translates to:
  /// **'CLEARED'**
  String get gameCleared;

  /// No description provided for @gameDailyClear.
  ///
  /// In en, this message translates to:
  /// **'DAILY CLEAR'**
  String get gameDailyClear;

  /// No description provided for @gameLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {id}'**
  String gameLevelLabel(int id);

  /// No description provided for @gameMissHint.
  ///
  /// In en, this message translates to:
  /// **'{miss} miss · {hint} hint'**
  String gameMissHint(int miss, int hint);

  /// No description provided for @gameReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get gameReplay;

  /// No description provided for @gameNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get gameNext;

  /// No description provided for @gameDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get gameDone;

  /// No description provided for @gameOutOfHearts.
  ///
  /// In en, this message translates to:
  /// **'OUT OF HEARTS'**
  String get gameOutOfHearts;

  /// No description provided for @gameArrowsCleared.
  ///
  /// In en, this message translates to:
  /// **'{cleared} of {total} arrows cleared'**
  String gameArrowsCleared(int cleared, int total);

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of hearts'**
  String get gameOverTitle;

  /// No description provided for @gameOverBody.
  ///
  /// In en, this message translates to:
  /// **'The board resets. Watch a short ad for one more heart, or try again from the start.'**
  String get gameOverBody;

  /// No description provided for @gameExtraHeart.
  ///
  /// In en, this message translates to:
  /// **'Extra heart'**
  String get gameExtraHeart;

  /// No description provided for @gameRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get gameRetry;

  /// No description provided for @gameQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get gameQuit;

  /// No description provided for @gameRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart board?'**
  String get gameRestartTitle;

  /// No description provided for @gameRestartBody.
  ///
  /// In en, this message translates to:
  /// **'Every arrow comes back and your hearts reset.'**
  String get gameRestartBody;

  /// No description provided for @gameRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get gameRestart;

  /// No description provided for @gameCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gameCancel;

  /// No description provided for @gameLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this board?'**
  String get gameLeaveTitle;

  /// No description provided for @gameLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'It starts from the beginning next time.'**
  String get gameLeaveBody;

  /// No description provided for @gameKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get gameKeepPlaying;

  /// No description provided for @gameLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get gameLeave;

  /// No description provided for @gameNoAdReady.
  ///
  /// In en, this message translates to:
  /// **'No ad ready — try again.'**
  String get gameNoAdReady;

  /// No description provided for @gameHintAdHint.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad in Shop for bonus hints, or try again.'**
  String get gameHintAdHint;

  /// No description provided for @howToTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToTitle;

  /// No description provided for @howToStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow'**
  String get howToStep1Title;

  /// No description provided for @howToStep1Body.
  ///
  /// In en, this message translates to:
  /// **'It flies in the direction it points — up, down, left, or right.'**
  String get howToStep1Body;

  /// No description provided for @howToStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Clear path = gone'**
  String get howToStep2Title;

  /// No description provided for @howToStep2Body.
  ///
  /// In en, this message translates to:
  /// **'If nothing sits on the straight path from its head to the edge, the whole arrow slides off — bends and all.'**
  String get howToStep2Body;

  /// No description provided for @howToStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Bodies can bend'**
  String get howToStep3Title;

  /// No description provided for @howToStep3Body.
  ///
  /// In en, this message translates to:
  /// **'An arrow blocks every cell it covers, head to tail, and some bodies turn corners. Follow the whole shape before you tap.'**
  String get howToStep3Body;

  /// No description provided for @howToStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Three hearts'**
  String get howToStep4Title;

  /// No description provided for @howToStep4Body.
  ///
  /// In en, this message translates to:
  /// **'A blocked tap costs a heart. Lose all three and the board resets — hearts left become your stars.'**
  String get howToStep4Body;

  /// No description provided for @howToStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Clear them all'**
  String get howToStep5Title;

  /// No description provided for @howToStep5Body.
  ///
  /// In en, this message translates to:
  /// **'Empty the board to win. Tap the grid button to show cell lines, or Hint when you are stuck.'**
  String get howToStep5Body;

  /// No description provided for @howToDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get howToDone;

  /// No description provided for @howToGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it — Play'**
  String get howToGotIt;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsSoundSub.
  ///
  /// In en, this message translates to:
  /// **'Clear, blocked, and win cues'**
  String get settingsSoundSub;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsSub.
  ///
  /// In en, this message translates to:
  /// **'Tap and block feedback'**
  String get settingsHapticsSub;

  /// No description provided for @settingsGrid.
  ///
  /// In en, this message translates to:
  /// **'Cell grid'**
  String get settingsGrid;

  /// No description provided for @settingsGridSub.
  ///
  /// In en, this message translates to:
  /// **'Show the grid behind the arrows'**
  String get settingsGridSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get settingsShop;

  /// No description provided for @settingsShopSub.
  ///
  /// In en, this message translates to:
  /// **'Remove ads, theme pack, bonus hints'**
  String get settingsShopSub;

  /// No description provided for @settingsThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get settingsThemes;

  /// No description provided for @settingsThemesSub.
  ///
  /// In en, this message translates to:
  /// **'Six palettes for the board'**
  String get settingsThemesSub;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy options'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'Change your ad consent choices'**
  String get settingsPrivacySub;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get settingsReset;

  /// No description provided for @settingsResetSub.
  ///
  /// In en, this message translates to:
  /// **'Start over from the first board'**
  String get settingsResetSub;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset progress?'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In en, this message translates to:
  /// **'Levels lock again and stars go back to zero. Purchases, themes, and your daily streak are kept.'**
  String get settingsResetBody;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Progress reset'**
  String get settingsResetDone;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsStatStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get settingsStatStars;

  /// No description provided for @settingsStatCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get settingsStatCleared;

  /// No description provided for @settingsStatReached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get settingsStatReached;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @themesTitle.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themesTitle;

  /// No description provided for @themesUnlockInShop.
  ///
  /// In en, this message translates to:
  /// **'Unlock Theme Pack in Shop'**
  String get themesUnlockInShop;

  /// No description provided for @themesFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get themesFree;

  /// No description provided for @themesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get themesActive;

  /// No description provided for @themesPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get themesPremium;

  /// No description provided for @themesPremiumPack.
  ///
  /// In en, this message translates to:
  /// **'Premium · Theme Pack'**
  String get themesPremiumPack;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get shopRemoveAds;

  /// No description provided for @shopRemoveAdsBody.
  ///
  /// In en, this message translates to:
  /// **'No banners or interstitials. Rewarded hints stay free.'**
  String get shopRemoveAdsBody;

  /// No description provided for @shopThemePack.
  ///
  /// In en, this message translates to:
  /// **'Theme Pack'**
  String get shopThemePack;

  /// No description provided for @shopThemePackBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock Aurora, Noir, and Solar themes forever.'**
  String get shopThemePackBody;

  /// No description provided for @shopBonusHint.
  ///
  /// In en, this message translates to:
  /// **'Bonus Hint'**
  String get shopBonusHint;

  /// No description provided for @shopBonusHintWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad for a bonus hint ({ready} ready).'**
  String shopBonusHintWatch(int ready);

  /// No description provided for @shopBonusHintFree.
  ///
  /// In en, this message translates to:
  /// **'Ads are removed, so hints are on the house ({ready} ready).'**
  String shopBonusHintFree(int ready);

  /// No description provided for @shopWatchAnAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad'**
  String get shopWatchAnAd;

  /// No description provided for @shopFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get shopFree;

  /// No description provided for @shopNonConsumable.
  ///
  /// In en, this message translates to:
  /// **'Non-consumable'**
  String get shopNonConsumable;

  /// No description provided for @shopOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get shopOwned;

  /// No description provided for @shopBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get shopBuy;

  /// No description provided for @shopWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get shopWatch;

  /// No description provided for @shopClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get shopClaim;

  /// No description provided for @shopRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get shopRestore;

  /// No description provided for @shopRestoreNote.
  ///
  /// In en, this message translates to:
  /// **'Purchases are tied to your store account and can be restored on any device you sign in to.'**
  String get shopRestoreNote;

  /// No description provided for @shopHintAdded.
  ///
  /// In en, this message translates to:
  /// **'Bonus hint added'**
  String get shopHintAdded;

  /// No description provided for @shopAdNotReady.
  ///
  /// In en, this message translates to:
  /// **'Ad not ready — try again in a moment.'**
  String get shopAdNotReady;

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyTitle;

  /// No description provided for @dailyStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day streak} other{{days} day streak}}'**
  String dailyStreakDays(int days);

  /// No description provided for @dailyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Play today\'s board and it shows up here.'**
  String get dailyEmpty;

  /// No description provided for @dailyPlayToday.
  ///
  /// In en, this message translates to:
  /// **'Play today'**
  String get dailyPlayToday;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageOnboardingTitle;

  /// No description provided for @languageOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Settings.'**
  String get languageOnboardingBody;

  /// No description provided for @languageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Arrows?'**
  String get reviewTitle;

  /// No description provided for @reviewBody.
  ///
  /// In en, this message translates to:
  /// **'A rating helps other people find the game. It takes a moment.'**
  String get reviewBody;

  /// No description provided for @reviewRate.
  ///
  /// In en, this message translates to:
  /// **'Rate it'**
  String get reviewRate;

  /// No description provided for @reviewLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get reviewLater;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is out. Update for the latest boards and fixes.'**
  String updateBody(String version);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'hi', 'id', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'hi': return AppLocalizationsHi();
    case 'id': return AppLocalizationsId();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
