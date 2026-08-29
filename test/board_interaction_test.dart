import 'dart:math' as math;

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/models/arrow.dart';
import 'package:arrows_game/models/direction.dart';
import 'package:arrows_game/models/level.dart';
import 'package:arrows_game/screens/game_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:arrows_game/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two arrows in a row: the left one is blocked until the right one leaves.
LevelData _twoInARow() => LevelData(
      id: 1,
      rows: 3,
      cols: 3,
      difficulty: 'Easy',
      arrows: [
        ArrowPiece(id: 0, row: 1, col: 0, direction: Direction.right),
        ArrowPiece(id: 1, row: 1, col: 2, direction: Direction.right),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'seen_how_to': true,
      // Keep audio/haptic plugins out of the widget test.
      'settings_sound': false,
      'settings_haptics': false,
    });
    await AppStore.instance.init();
  });

  Future<Offset> cellCenter(WidgetTester tester, int row, int col) async {
    final rect = tester.getRect(find.byType(GameBoard));
    final cell = math.min(rect.width / 3, rect.height / 3);
    final origin = rect.center - Offset(cell * 3 / 2, cell * 3 / 2);
    return origin + Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  testWidgets('tapping a blocked arrow costs a heart', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: GameScreen(customLevel: _twoInARow()),
    ));
    await tester.pump();

    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));

    await tester.tapAt(await cellCenter(tester, 1, 0));
    await tester.pump();

    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('clearing every arrow wins the level', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: GameScreen(customLevel: _twoInARow()),
    ));
    await tester.pump();

    // Right-hand arrow has a clear path out.
    await tester.tapAt(await cellCenter(tester, 1, 2));
    await tester.pumpAndSettle();

    // Which unblocks the left-hand one.
    await tester.tapAt(await cellCenter(tester, 1, 0));
    await tester.pumpAndSettle();

    expect(find.text('CLEARED'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
  });

  testWidgets('tapping empty space does nothing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: GameScreen(customLevel: _twoInARow()),
    ));
    await tester.pump();

    await tester.tapAt(await cellCenter(tester, 0, 0));
    await tester.pump();

    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
  });

  testWidgets('a near-miss tap still hits the closest arrow', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: GameScreen(customLevel: _twoInARow()),
    ));
    await tester.pump();

    // Just above the right-hand arrow, inside the empty cell overhead.
    final rect = tester.getRect(find.byType(GameBoard));
    final cell = math.min(rect.width / 3, rect.height / 3);
    final target = await cellCenter(tester, 1, 2);
    await tester.tapAt(target - Offset(0, cell * 0.6));
    await tester.pumpAndSettle();

    // It cleared instead of being ignored, and cost no heart.
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    await tester.tapAt(await cellCenter(tester, 1, 0));
    await tester.pumpAndSettle();
    expect(find.text('CLEARED'), findsOneWidget);
  });

  testWidgets('header title and hearts sit on the screen centre',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: GameScreen(customLevel: _twoInARow()),
    ));
    await tester.pump();

    final screenCentre = tester.getSize(find.byType(GameScreen)).width / 2;
    expect((tester.getCenter(find.text('Easy')).dx - screenCentre).abs(),
        lessThan(1));
    expect((tester.getCenter(find.text('LEVEL 1')).dx - screenCentre).abs(),
        lessThan(1));
    // Middle of the three hearts lands on the same centre line.
    expect(
        (tester.getCenter(find.byIcon(Icons.favorite_rounded).at(1)).dx -
                screenCentre)
            .abs(),
        lessThan(1));
  });
}
