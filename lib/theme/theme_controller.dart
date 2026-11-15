import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import 'game_themes.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  GameTheme _theme = GameThemes.midnight;

  GameTheme get theme => _theme;
  GameTheme get palette => _theme;

  /// Free themes always; premium ones with the theme pack, or during a
  /// rewarded day's trial of that one theme.
  bool canUse(GameTheme theme) =>
      !theme.premium ||
      AppStore.instance.themePackOwned ||
      AppStore.instance.themeTrialActive(theme.id);

  /// Also the place a finished trial ends: the saved premium theme is only
  /// honoured while it can still be used.
  Future<void> load() async {
    final candidate = GameThemes.byId(AppStore.instance.themeId);
    _theme = canUse(candidate) ? candidate : GameThemes.midnight;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    final candidate = GameThemes.byId(id);
    if (!canUse(candidate)) return;
    await AppStore.instance.setThemeId(id);
    _theme = candidate;
    notifyListeners();
  }
}
