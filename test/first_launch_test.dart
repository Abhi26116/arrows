import 'package:arrows_game/data/progress_store.dart';
import 'package:arrows_game/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A file of its own: AppStore keeps the first SharedPreferences it opens for
// the life of the isolate, so a first launch has to be the first thing here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a fresh install opens on the rules, not a language picker',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppStore.instance.init();
    // Following the phone, with nothing chosen.
    expect(AppStore.instance.localeCode, isNull);

    await tester.pumpWidget(const ArrowsApp());
    await tester.pump();
    await tester.tap(find.text('Clear the board'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Straight to How to Play, in the phone's language (English under test).
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('हिन्दी'), findsNothing);
    expect(find.text('Español'), findsNothing);
  });
}
