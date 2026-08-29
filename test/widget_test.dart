import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'seen_how_to': true,
    });
    await AppStore.instance.init();
  });

  testWidgets('splash plays, then hands over to home', (tester) async {
    await tester.pumpWidget(const ArrowsApp());
    await tester.pump();

    // Splash is up first, with the wordmark and no home controls.
    expect(find.text('Clear the board'), findsOneWidget);
    expect(find.textContaining('Play'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('ARROWS'), findsOneWidget);
    expect(find.textContaining('Play'), findsWidgets);
  });

  testWidgets('tapping the splash skips straight to home', (tester) async {
    await tester.pumpWidget(const ArrowsApp());
    await tester.pump();

    await tester.tap(find.text('Clear the board'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Play'), findsWidgets);
  });
}
