import 'dart:math';

import '../logic/level_generator.dart';
import '../models/level.dart';

class DailyChallenge {
  DailyChallenge._();

  static int get seed {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  static LevelData levelForToday() {
    final gen = LevelGenerator(Random(seed));
    // Mid-hard daily board, same look as the later packs.
    return gen.generate(
      id: 0,
      rows: 12,
      cols: 12,
      fill: 0.58,
      maxLength: 6,
      difficulty: 'Daily',
      label: 'Daily',
    );
  }
}
