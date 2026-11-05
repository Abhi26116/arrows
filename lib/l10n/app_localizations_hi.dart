// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTagline => 'बोर्ड खाली करो। क्रम ही सब कुछ है।';

  @override
  String get statStars => 'सितारे';

  @override
  String get statStreak => 'लगातार';

  @override
  String get statCleared => 'पूरे';

  @override
  String actionContinue(int level) {
    return 'जारी रखें · $level';
  }

  @override
  String get actionStart => 'खेलना शुरू करें';

  @override
  String get navDaily => 'डेली';

  @override
  String navDailyBest(String stars) {
    return 'डेली · $stars';
  }

  @override
  String get navLevels => 'लेवल';

  @override
  String get navThemes => 'थीम';

  @override
  String get navStreak => 'स्ट्रीक';

  @override
  String get navHowTo => 'कैसे खेलें';

  @override
  String get tooltipShop => 'शॉप';

  @override
  String get tooltipSettings => 'सेटिंग्स';

  @override
  String get tooltipBack => 'वापस';

  @override
  String get levelsTitle => 'लेवल';

  @override
  String levelsStarsOf(int earned, int total) {
    return '$total में से $earned';
  }

  @override
  String get gameTooltipUndo => 'पिछली चाल';

  @override
  String get gameTooltipHint => 'संकेत';

  @override
  String get gameTooltipRestart => 'बोर्ड दोबारा';

  @override
  String get gameTooltipShowGrid => 'ग्रिड दिखाएँ';

  @override
  String get gameTooltipHideGrid => 'ग्रिड छिपाएँ';

  @override
  String gameLevelNumber(int id) {
    return 'लेवल $id';
  }

  @override
  String get gameToday => 'आज';

  @override
  String get gameCleared => 'पूरा हुआ';

  @override
  String get gameDailyClear => 'डेली पूरा';

  @override
  String gameLevelLabel(int id) {
    return 'लेवल $id';
  }

  @override
  String gameMissHint(int miss, int hint) {
    return '$miss चूक · $hint संकेत';
  }

  @override
  String get gameReplay => 'फिर से';

  @override
  String get gameNext => 'अगला';

  @override
  String get gameDone => 'हो गया';

  @override
  String get gameOutOfHearts => 'दिल खत्म';

  @override
  String gameArrowsCleared(int cleared, int total) {
    return '$total में से $cleared तीर हटे';
  }

  @override
  String get gameOverTitle => 'दिल खत्म';

  @override
  String get gameOverBody =>
      'बोर्ड रीसेट हो जाएगा। एक और दिल के लिए छोटा विज्ञापन देखें, या शुरू से कोशिश करें।';

  @override
  String get gameExtraHeart => 'एक और दिल';

  @override
  String get gameRetry => 'फिर कोशिश';

  @override
  String get gameQuit => 'बाहर';

  @override
  String get gameRestartTitle => 'बोर्ड दोबारा शुरू करें?';

  @override
  String get gameRestartBody =>
      'हर तीर वापस आ जाएगा और आपके दिल रीसेट हो जाएँगे।';

  @override
  String get gameRestart => 'दोबारा';

  @override
  String get gameCancel => 'रहने दें';

  @override
  String get gameLeaveTitle => 'यह बोर्ड छोड़ दें?';

  @override
  String get gameLeaveBody => 'अगली बार यह शुरू से चालू होगा।';

  @override
  String get gameKeepPlaying => 'खेलते रहें';

  @override
  String get gameLeave => 'छोड़ें';

  @override
  String get gameNoAdReady => 'कोई विज्ञापन तैयार नहीं — फिर कोशिश करें।';

  @override
  String get gameHintAdHint =>
      'बोनस संकेत के लिए शॉप में छोटा विज्ञापन देखें, या फिर कोशिश करें।';

  @override
  String get howToTitle => 'कैसे खेलें';

  @override
  String get howToStep1Title => 'तीर पर टैप करें';

  @override
  String get howToStep1Body =>
      'वह जिस दिशा में इशारा करता है उधर उड़ जाता है — ऊपर, नीचे, बाएँ या दाएँ।';

  @override
  String get howToStep2Title => 'रास्ता खाली = तीर गया';

  @override
  String get howToStep2Body =>
      'अगर उसके सिरे से किनारे तक सीधा रास्ता खाली है, तो पूरा तीर बाहर निकल जाता है — मोड़ों के साथ भी।';

  @override
  String get howToStep3Title => 'तीर मुड़ भी सकते हैं';

  @override
  String get howToStep3Body =>
      'तीर अपनी पूरी लंबाई की हर सेल रोकता है, सिरे से पूँछ तक, और कुछ तीर कोने पर मुड़ते हैं। टैप करने से पहले पूरी शक्ल देखें।';

  @override
  String get howToStep4Title => 'तीन दिल';

  @override
  String get howToStep4Body =>
      'रुका हुआ टैप एक दिल ले जाता है। तीनों गए तो बोर्ड रीसेट — और बचे हुए दिल ही आपके सितारे बनते हैं।';

  @override
  String get howToStep5Title => 'सारे हटा दें';

  @override
  String get howToStep5Body =>
      'बोर्ड खाली करके जीतें। सेल की लाइनें देखने के लिए ग्रिड बटन दबाएँ, और अटक जाएँ तो संकेत लें।';

  @override
  String get howToDone => 'हो गया';

  @override
  String get howToGotIt => 'समझ गया — खेलें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSound => 'आवाज़';

  @override
  String get settingsSoundSub => 'तीर हटने, रुकने और जीतने की आवाज़';

  @override
  String get settingsHaptics => 'कंपन';

  @override
  String get settingsHapticsSub => 'टैप और रुकावट पर हल्का कंपन';

  @override
  String get settingsGrid => 'सेल ग्रिड';

  @override
  String get settingsGridSub => 'तीरों के पीछे ग्रिड दिखाएँ';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsShop => 'शॉप';

  @override
  String get settingsShopSub => 'विज्ञापन हटाएँ, थीम पैक, बोनस संकेत';

  @override
  String get settingsThemes => 'थीम';

  @override
  String get settingsThemesSub => 'बोर्ड के लिए छह रंग-सेट';

  @override
  String get settingsPrivacy => 'प्राइवेसी विकल्प';

  @override
  String get settingsPrivacySub => 'विज्ञापन की सहमति बदलें';

  @override
  String get settingsReset => 'प्रगति रीसेट करें';

  @override
  String get settingsResetSub => 'पहले बोर्ड से दोबारा शुरू करें';

  @override
  String get settingsResetTitle => 'प्रगति रीसेट करें?';

  @override
  String get settingsResetBody =>
      'लेवल फिर से लॉक हो जाएँगे और सितारे शून्य हो जाएँगे। खरीदारी, थीम और आपकी डेली स्ट्रीक बनी रहेगी।';

  @override
  String get settingsResetConfirm => 'रीसेट';

  @override
  String get settingsResetDone => 'प्रगति रीसेट हो गई';

  @override
  String get settingsCancel => 'रहने दें';

  @override
  String get settingsStatStars => 'सितारे';

  @override
  String get settingsStatCleared => 'पूरे';

  @override
  String get settingsStatReached => 'पहुँचे';

  @override
  String get settingsAbout => 'ऐप के बारे में';

  @override
  String get themesTitle => 'थीम';

  @override
  String get themesUnlockInShop => 'शॉप में थीम पैक अनलॉक करें';

  @override
  String get themesFree => 'मुफ़्त';

  @override
  String get themesActive => 'चालू';

  @override
  String get themesPremium => 'प्रीमियम';

  @override
  String get themesPremiumPack => 'प्रीमियम · थीम पैक';

  @override
  String get shopTitle => 'शॉप';

  @override
  String get shopRemoveAds => 'विज्ञापन हटाएँ';

  @override
  String get shopRemoveAdsBody =>
      'कोई बैनर या बीच का विज्ञापन नहीं। इनाम वाले संकेत मुफ़्त ही रहेंगे।';

  @override
  String get shopThemePack => 'थीम पैक';

  @override
  String get shopThemePackBody =>
      'ऑरोरा, नॉयर और सोलर थीम हमेशा के लिए अनलॉक करें।';

  @override
  String get shopBonusHint => 'बोनस संकेत';

  @override
  String shopBonusHintWatch(int ready) {
    return 'एक बोनस संकेत के लिए छोटा विज्ञापन देखें ($ready तैयार)।';
  }

  @override
  String shopBonusHintFree(int ready) {
    return 'विज्ञापन हटे हुए हैं, तो संकेत मुफ़्त हैं ($ready तैयार)।';
  }

  @override
  String get shopWatchAnAd => 'विज्ञापन देखें';

  @override
  String get shopFree => 'मुफ़्त';

  @override
  String get shopNonConsumable => 'एक बार की खरीद';

  @override
  String get shopOwned => 'ले चुके हैं';

  @override
  String get shopBuy => 'खरीदें';

  @override
  String get shopWatch => 'देखें';

  @override
  String get shopClaim => 'लें';

  @override
  String get shopRestore => 'खरीदारी वापस लाएँ';

  @override
  String get shopRestoreNote =>
      'खरीदारी आपके स्टोर खाते से जुड़ी होती है और जिस भी डिवाइस पर आप साइन इन करें वहाँ वापस लाई जा सकती है।';

  @override
  String get shopHintAdded => 'बोनस संकेत जुड़ गया';

  @override
  String get shopAdNotReady =>
      'विज्ञापन तैयार नहीं — थोड़ी देर में कोशिश करें।';

  @override
  String get dailyTitle => 'डेली';

  @override
  String dailyStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन की स्ट्रीक',
      one: '1 दिन की स्ट्रीक',
    );
    return '$_temp0';
  }

  @override
  String get dailyEmpty => 'आज का बोर्ड खेलें, वह यहाँ दिखने लगेगा।';

  @override
  String get dailyPlayToday => 'आज खेलें';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSystem => 'फ़ोन की भाषा';

  @override
  String get languageOnboardingTitle => 'अपनी भाषा चुनें';

  @override
  String get languageOnboardingBody =>
      'इसे आप कभी भी सेटिंग्स में बदल सकते हैं।';

  @override
  String get languageContinue => 'आगे बढ़ें';

  @override
  String get reviewTitle => 'Arrows पसंद आ रहा है?';

  @override
  String get reviewBody =>
      'आपकी रेटिंग से दूसरों को यह गेम मिलने में मदद मिलती है। बस एक पल लगेगा।';

  @override
  String get reviewRate => 'रेटिंग दें';

  @override
  String get reviewLater => 'अभी नहीं';

  @override
  String get updateTitle => 'नया अपडेट आया है';

  @override
  String updateBody(String version) {
    return 'वर्ज़न $version आ गया है। नए बोर्ड और सुधारों के लिए अपडेट करें।';
  }

  @override
  String get updateNow => 'अपडेट करें';

  @override
  String get updateLater => 'बाद में';
}
