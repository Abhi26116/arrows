import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an animal never shares a cell with an arrow', () {
    for (final level in LevelCatalog.all) {
      final arrowCells = <(int, int)>{
        for (final a in level.arrows) ...a.cells,
      };
      for (final captive in level.captives) {
        for (final cell in captive.cells) {
          expect(arrowCells.contains(cell), isFalse,
              reason: 'level ${level.id}: arrow sits on the animal at $cell');
          expect(cell.$1 >= 0 && cell.$1 < level.rows, isTrue);
          expect(cell.$2 >= 0 && cell.$2 < level.cols, isTrue);
        }
      }
    }
  });

  test('later packs pen animals in, the tutorial does not', () {
    final early = LevelCatalog.all.where((l) => l.id <= 8);
    expect(early.every((l) => l.captives.isEmpty), isTrue,
        reason: 'the first boards should stay plain');
    expect(LevelCatalog.all.any((l) => l.captives.isNotEmpty), isTrue);
  });

  test('an animal is penned until its fence is clear, then loose', () {
    final level = LevelCatalog.all.firstWhere((l) => l.captives.isNotEmpty);
    final captive = level.captives.first;
    final controller = GameController(level.clone());

    Set<(int, int)> taken() => {
          for (final a in controller.arrows.values) ...a.cells,
        };

    expect(captive.isPennedBy(taken()), isTrue,
        reason: 'a fresh board should have the animal fenced in');

    // Clearing the board clears the fence with it.
    expect(captive.isPennedBy(<(int, int)>{}), isFalse);
  });
}
