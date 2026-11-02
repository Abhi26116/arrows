import 'dart:math' as math;

import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/models/arrow.dart';
import 'package:arrows_game/models/direction.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/models/level.dart';
import 'package:arrows_game/screens/game_screen.dart';
import 'package:arrows_game/theme/app_theme.dart';
import 'package:arrows_game/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:arrows_game/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A bent arrow whose body turns up behind its tip, with a straight arrow
/// parked in the far end of that bend.
LevelData _bentPair() => LevelData(
      id: 2,
      rows: 5,
      cols: 5,
      difficulty: 'Easy',
      arrows: [
        ArrowPiece(
          id: 0,
          row: 2,
          col: 0,
          direction: Direction.left,
          length: 3,
          bends: [(Direction.up, 2)],
        ),
        ArrowPiece(id: 1, row: 0, col: 0, direction: Direction.right),
      ],
    );

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('a bent arrow slides out along its own track', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark,
      home: GameScreen(customLevel: _bentPair()),
    ));
    await tester.pump();

    Future<Offset> cell(int row, int col) async {
      final rect = tester.getRect(find.byType(GameBoard));
      final size = math.min(rect.width / 5, rect.height / 5);
      final origin = rect.center - Offset(size * 5 / 2, size * 5 / 2);
      return origin + Offset((col + 0.5) * size, (row + 0.5) * size);
    }

    // The straight arrow runs into the far end of the bend, two turns from
    // the tip, so it costs a heart.
    await tester.tapAt(await cell(0, 0));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 1));

    // Tapping the bend's own body still picks up the bent arrow, and it
    // leaves even though its tail points the other way.
    await tester.tapAt(await cell(0, 2));
    await tester.pumpAndSettle();

    await tester.tapAt(await cell(0, 0));
    await tester.pumpAndSettle();
    expect(find.text('CLEARED'), findsOneWidget);
  });

  testWidgets('tapping empty space does nothing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  /// The board is square, so its width is what sizes it on a phone. These
  /// numbers are the whole point of the gutter being 4 rather than 14, and of
  /// the button band being paid for only when the leftover height does not
  /// already cover it.
  Future<void> expectBoardFillsWidth(
    WidgetTester tester, {
    required Size logical,
    required double dpr,
    required double safeTop,
    required double safeBottom,
  }) async {
    tester.view.physicalSize = logical * dpr;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = FakeViewPadding(
      top: safeTop * dpr,
      bottom: safeBottom * dpr,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark,
      home: GameScreen(customLevel: LevelCatalog.byId(72)),
    ));
    await tester.pump();

    final box = tester.getRect(find.byType(GameBoard));
    final side = math.min(box.width, box.height);

    // Edge to edge bar the gutter on each side.
    expect(side, closeTo(logical.width - 8, 0.5),
        reason: 'board should fill the width on ${logical.width}pt');

    // The painted board is that square, centred in the padded box.
    final boardBottom = box.center.dy + side / 2;
    final hintTop = tester.getRect(
      find.byIcon(Icons.lightbulb_outline_rounded),
    ).top;
    expect(boardBottom, lessThanOrEqualTo(hintTop),
        reason: 'board should clear the floating buttons on '
            '${logical.width}x${logical.height}pt');
  }

  testWidgets('the board fills the width on a tall phone', (tester) async {
    await expectBoardFillsWidth(
      tester,
      logical: const Size(393, 852),
      dpr: 3,
      safeTop: 59,
      safeBottom: 34,
    );
  });

  testWidgets('a short phone keeps the board clear of the buttons',
      (tester) async {
    await expectBoardFillsWidth(
      tester,
      logical: const Size(375, 667),
      dpr: 2,
      safeTop: 20,
      safeBottom: 0,
    );
  });

  testWidgets('the board hangs off the header on a tall phone',
      (tester) async {
    // A square board leaves slack on a tall screen. It belongs under the
    // board, where the floating buttons already sit, not above it as a dead
    // band between the progress bar and the first row of arrows.
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark,
      home: GameScreen(customLevel: LevelCatalog.byId(72)),
    ));
    await tester.pump();

    final box = tester.getRect(find.byType(GameBoard));
    final side = math.min(box.width, box.height);
    final boardTop = box.center.dy - side / 2;
    final total = LevelCatalog.byId(72).arrows.length;
    final counter = tester.getRect(find.text('0/$total'));

    expect(boardTop - counter.bottom, lessThan(48),
        reason: 'slack above the board should stay capped');
  });

  testWidgets('header title and hearts sit on the screen centre',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
