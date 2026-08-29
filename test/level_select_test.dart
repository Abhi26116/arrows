import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/screens/level_select_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(WidgetTester tester, int maxUnlocked) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'seen_how_to': true,
      'settings_sound': false,
      'settings_haptics': false,
      'max_unlocked_level': maxUnlocked,
    });
    await AppStore.instance.init();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const LevelSelectScreen(),
    ));
    await tester.pump();
  }

  testWidgets('level list stops just past the player and hides the total',
      (tester) async {
    await pumpAt(tester, 3);

    // Cleared levels show their number, the rest show a padlock.
    expect(find.text('3'), findsOneWidget);
    // 3 unlocked + 6 lookahead = 9 tiles, so six are locked.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(6));
    expect(find.text('Warmup'), findsOneWidget);
    expect(find.text('Focus'), findsNothing);
    expect(find.text('${LevelCatalog.count}'), findsNothing);
    expect(find.text('More open up as you clear levels'), findsOneWidget);
  });

  testWidgets('later packs stay hidden until reached', (tester) async {
    await pumpAt(tester, 1);

    expect(find.text('Tutorial'), findsOneWidget);
    // 1 unlocked + 6 lookahead = tiles 1..7, so one Warmup tile shows.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(6));
    expect(find.text('Endless Edge'), findsNothing);
    expect(find.text('Master'), findsNothing);
  });
}
