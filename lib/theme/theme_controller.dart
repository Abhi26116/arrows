import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import 'game_themes.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  GameTheme _theme = GameThemes.midnight;

  GameTheme get theme => _theme;
  GameTheme get palette => _theme;

  Future<void> load() async {
    final id = AppStore.instance.themeId;
    final candidate = GameThemes.byId(id);
    if (candidate.premium && !AppStore.instance.themePackOwned) {
      _theme = GameThemes.midnight;
    } else {
      _theme = candidate;
    }
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    final candidate = GameThemes.byId(id);
    if (candidate.premium && !AppStore.instance.themePackOwned) {
      return;
    }
    await AppStore.instance.setThemeId(id);
    _theme = candidate;
    notifyListeners();
  }
}
