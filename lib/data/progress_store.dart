import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/level_generator.dart';

class DailyRecord {
  const DailyRecord({required this.date, required this.stars});

  final String date;
  final int stars;

  Map<String, dynamic> toJson() => {'date': date, 'stars': stars};

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        date: json['date'] as String,
        stars: json['stars'] as int,
      );
}

class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _keyMax = 'max_unlocked_level';
  static const _keyStars = 'level_stars_';
  static const _keySound = 'settings_sound';
  static const _keyHaptics = 'settings_haptics';
  static const _keySeenHowTo = 'seen_how_to';
  static const _keyBestDaily = 'best_daily';
  static const _keyDailyDate = 'daily_date';
  static const _keyDailyHistory = 'daily_history';
  static const _keyTheme = 'theme_id';
  static const _keyRemoveAds = 'entitlement_remove_ads';
  static const _keyThemePack = 'entitlement_theme_pack';
  static const _keyDisplayName = 'display_name';
  static const _keyWinStreakAds = 'wins_since_interstitial';
  static const _keyBonusHints = 'bonus_hints';
  static const _keyShowGrid = 'settings_show_grid';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // —— Progress ——

  int get maxUnlocked {
    final v = _prefs?.getInt(_keyMax) ?? 1;
    return v < 1 ? 1 : v;
  }

  Future<void> unlockUpTo(int levelId) async {
    await init();
    if (levelId > maxUnlocked) {
      await _prefs!.setInt(_keyMax, levelId);
      notifyListeners();
    }
  }

  Future<void> completeLevel(int levelId, {required int stars}) async {
    await init();
    final key = '$_keyStars$levelId';
    final prev = _prefs!.getInt(key) ?? 0;
    if (stars > prev) {
      await _prefs!.setInt(key, stars);
    }
    await unlockUpTo(levelId + 1);
    notifyListeners();
  }

  /// Clears level progress and stars. Purchases, settings, and daily history
  /// are deliberately kept.
  Future<void> resetProgress() async {
    await init();
    for (var i = 1; i <= LevelCatalog.count; i++) {
      await _prefs!.remove('$_keyStars$i');
    }
    await _prefs!.remove(_keyMax);
    notifyListeners();
  }

  int starsFor(int levelId) => _prefs?.getInt('$_keyStars$levelId') ?? 0;

  bool isUnlocked(int levelId) => levelId <= maxUnlocked;

  int get totalStars {
    var sum = 0;
    for (var i = 1; i <= LevelCatalog.count; i++) {
      sum += starsFor(i);
    }
    return sum;
  }

  int get clearedCount {
    var n = 0;
    for (var i = 1; i <= LevelCatalog.count; i++) {
      if (starsFor(i) > 0) n++;
    }
    return n;
  }

  // —— Settings ——

  bool get soundEnabled => _prefs?.getBool(_keySound) ?? true;

  Future<void> setSoundEnabled(bool value) async {
    await init();
    await _prefs!.setBool(_keySound, value);
    notifyListeners();
  }

  bool get hapticsEnabled => _prefs?.getBool(_keyHaptics) ?? true;

  Future<void> setHapticsEnabled(bool value) async {
    await init();
    await _prefs!.setBool(_keyHaptics, value);
    notifyListeners();
  }

  bool get showGrid => _prefs?.getBool(_keyShowGrid) ?? false;

  Future<void> setShowGrid(bool value) async {
    await init();
    await _prefs!.setBool(_keyShowGrid, value);
    notifyListeners();
  }

  bool get seenHowTo => _prefs?.getBool(_keySeenHowTo) ?? false;

  Future<void> setSeenHowTo(bool value) async {
    await init();
    await _prefs!.setBool(_keySeenHowTo, value);
    notifyListeners();
  }

  String get themeId => _prefs?.getString(_keyTheme) ?? 'midnight';

  Future<void> setThemeId(String id) async {
    await init();
    await _prefs!.setString(_keyTheme, id);
    notifyListeners();
  }

  String get displayName {
    final n = _prefs?.getString(_keyDisplayName);
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return 'Player';
  }

  Future<void> setDisplayName(String name) async {
    await init();
    await _prefs!.setString(_keyDisplayName, name.trim());
    notifyListeners();
  }

  // —— Entitlements ——

  bool get removeAdsOwned => _prefs?.getBool(_keyRemoveAds) ?? false;

  Future<void> setRemoveAdsOwned(bool value) async {
    await init();
    await _prefs!.setBool(_keyRemoveAds, value);
    notifyListeners();
  }

  bool get themePackOwned => _prefs?.getBool(_keyThemePack) ?? false;

  Future<void> setThemePackOwned(bool value) async {
    await init();
    await _prefs!.setBool(_keyThemePack, value);
    notifyListeners();
  }

  bool get adsEnabled => !removeAdsOwned;

  int get bonusHints => _prefs?.getInt(_keyBonusHints) ?? 0;

  Future<void> addBonusHints(int count) async {
    await init();
    await _prefs!.setInt(_keyBonusHints, bonusHints + count);
    notifyListeners();
  }

  Future<bool> consumeBonusHint() async {
    await init();
    if (bonusHints <= 0) return false;
    await _prefs!.setInt(_keyBonusHints, bonusHints - 1);
    notifyListeners();
    return true;
  }

  int get winsSinceInterstitial => _prefs?.getInt(_keyWinStreakAds) ?? 0;

  Future<void> bumpWinForAds() async {
    await init();
    await _prefs!.setInt(_keyWinStreakAds, winsSinceInterstitial + 1);
  }

  Future<void> resetWinsSinceInterstitial() async {
    await init();
    await _prefs!.setInt(_keyWinStreakAds, 0);
  }

  // —— Daily ——

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  int? get dailyBestStars {
    if (_prefs?.getString(_keyDailyDate) != _todayKey) return null;
    return _prefs?.getInt(_keyBestDaily);
  }

  Future<void> recordDaily(int stars) async {
    await init();
    final today = _todayKey;
    final prevDate = _prefs!.getString(_keyDailyDate);
    final prev = prevDate == today ? (_prefs!.getInt(_keyBestDaily) ?? 0) : 0;
    if (stars > prev) {
      await _prefs!.setString(_keyDailyDate, today);
      await _prefs!.setInt(_keyBestDaily, stars);
    }
    await _upsertDailyHistory(
        today, stars > prev ? stars : (prev > 0 ? prev : stars));
    notifyListeners();
  }

  Future<void> _upsertDailyHistory(String date, int stars) async {
    final list = List<DailyRecord>.from(dailyHistory);
    final idx = list.indexWhere((e) => e.date == date);
    if (idx >= 0) {
      if (stars > list[idx].stars) {
        list[idx] = DailyRecord(date: date, stars: stars);
      }
    } else {
      list.add(DailyRecord(date: date, stars: stars));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    final trimmed = list.take(90).toList();
    final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await _prefs!.setString(_keyDailyHistory, encoded);
  }

  List<DailyRecord> get dailyHistory {
    final raw = _prefs?.getString(_keyDailyHistory);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DailyRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  int get dailyStreak {
    final history = dailyHistory;
    if (history.isEmpty) return 0;
    final byDate = {for (final h in history) h.date: h.stars};
    var streak = 0;
    var day = DateTime.now();
    // Allow today incomplete: start from yesterday if today missing.
    if (!byDate.containsKey(_formatDate(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    while (byDate.containsKey(_formatDate(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _formatDate(DateTime n) => '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

typedef ProgressStore = AppStore;
