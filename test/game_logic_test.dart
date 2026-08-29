import 'dart:math';

import 'package:arrows_game/logic/game_controller.dart';
import 'package:arrows_game/logic/level_generator.dart';
import 'package:arrows_game/models/arrow.dart';
import 'package:arrows_game/models/direction.dart';
import 'package:arrows_game/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocked arrow cannot clear', () {
    final level = LevelData(
      id: 99,
      rows: 3,
      cols: 3,
      arrows: [
        ArrowPiece(id: 0, row: 1, col: 0, direction: Direction.right),
        ArrowPiece(id: 1, row: 1, col: 2, direction: Direction.right),
      ],
    );
    final c = GameController(level);
    expect(c.preview(0).result, MoveResult.blocked);
    expect(c.preview(1).result, MoveResult.cleared);
    c.tryMove(1);
    expect(c.preview(0).result, MoveResult.cleared);
  });

  test('a long arrow occupies every cell behind its tip', () {
    final arrow =
        ArrowPiece(id: 0, row: 2, col: 4, direction: Direction.right, length: 3);
    expect(arrow.cells, [(2, 4), (2, 3), (2, 2)]);
    expect(arrow.tailCol, 2);
    expect(arrow.covers(2, 3), isTrue);
    expect(arrow.covers(2, 1), isFalse);
    expect(arrow.covers(1, 3), isFalse);
  });

  test('an arrow body blocks another arrow', () {
    final level = LevelData(
      id: 98,
      rows: 5,
      cols: 5,
      arrows: [
        // Body spans (0,2)..(2,2); tip at (0,2) pointing up.
        ArrowPiece(id: 0, row: 0, col: 2, direction: Direction.up, length: 3),
        // Fires right through the body at row 2.
        ArrowPiece(id: 1, row: 2, col: 0, direction: Direction.right),
        // Fires right below the body.
        ArrowPiece(id: 2, row: 3, col: 0, direction: Direction.right),
      ],
    );
    final c = GameController(level);
    expect(c.arrowAt(2, 2)?.id, 0);
    expect(c.preview(1).result, MoveResult.blocked);
    expect(c.preview(1).blockerId, 0);
    expect(c.preview(2).result, MoveResult.cleared);
    expect(c.preview(0).result, MoveResult.cleared);
  });

  test('a long arrow clears once its own corridor is empty', () {
    final level = LevelData(
      id: 97,
      rows: 4,
      cols: 6,
      arrows: [
        ArrowPiece(id: 0, row: 1, col: 2, direction: Direction.right, length: 3),
        ArrowPiece(id: 1, row: 1, col: 5, direction: Direction.right, length: 2),
      ],
    );
    final c = GameController(level);
    expect(c.preview(0).result, MoveResult.blocked);
    c.tryMove(1);
    expect(c.preview(0).result, MoveResult.cleared);
    c.tryMove(0);
    expect(c.isWon, isTrue);
  });

  test('generated levels are solvable via reverse placement order', () {
    final gen = LevelGenerator(Random(7));
    for (var i = 0; i < 20; i++) {
      final level = gen.generate(
        id: i,
        rows: 9,
        cols: 9,
        fill: 0.5,
        maxLength: 4,
      );
      expect(level.arrows, isNotEmpty, reason: 'level seed iteration $i');
      expect(
        _solvableByReverseIds(level),
        isTrue,
        reason: 'level seed iteration $i',
      );
    }
  });

  test('handcrafted levels are solvable by search', () {
    for (final level in LevelCatalog.all.take(6)) {
      expect(_isSolvableDfs(level), isTrue, reason: 'level ${level.id}');
    }
  });

  test('catalog levels are solvable and never overlap', () {
    for (final level in LevelCatalog.all) {
      final seen = <(int, int)>{};
      for (final a in level.arrows) {
        for (final cell in a.cells) {
          expect(cell.$1 >= 0 && cell.$1 < level.rows, isTrue,
              reason: 'level ${level.id} row out of bounds');
          expect(cell.$2 >= 0 && cell.$2 < level.cols, isTrue,
              reason: 'level ${level.id} col out of bounds');
          expect(seen.add(cell), isTrue,
              reason: 'level ${level.id} overlaps at $cell');
        }
      }
      // Generated boards are built in reverse-removal order; the handcrafted
      // openers are ordered by hand and covered by the DFS test above.
      if (level.id > 6) {
        expect(_solvableByReverseIds(level), isTrue,
            reason: 'level ${level.id}');
      }
    }
  });

  test('a session loses a heart per blocked tap and ends at zero', () {
    final level = LevelData(
      id: 96,
      rows: 3,
      cols: 3,
      arrows: [
        ArrowPiece(id: 0, row: 1, col: 0, direction: Direction.right),
        ArrowPiece(id: 1, row: 1, col: 2, direction: Direction.right),
      ],
    );
    final s = PlaySession(level);
    expect(s.lives, 3);
    expect(s.progress, 0);

    s.tap(0); // blocked
    expect(s.lives, 2);
    s.tap(0);
    s.tap(0);
    expect(s.lives, 0);
    expect(s.isOutOfLives, isTrue);

    s.grantLife();
    expect(s.lives, 1);

    s.tap(1); // clears
    expect(s.progress, 0.5);
  });

  test('undo restores the board but not a heart', () {
    final level = LevelData(
      id: 95,
      rows: 3,
      cols: 3,
      arrows: [
        ArrowPiece(id: 0, row: 1, col: 0, direction: Direction.right),
        ArrowPiece(id: 1, row: 1, col: 2, direction: Direction.right),
      ],
    );
    final s = PlaySession(level);
    s.tap(0); // blocked -> heart lost
    s.tap(1); // cleared
    expect(s.controller.remaining, 1);
    expect(s.canUndo, isTrue);

    expect(s.undo(), isTrue);
    expect(s.controller.remaining, 2);
    expect(s.lives, 2);
    expect(s.canUndo, isFalse);
  });
}

bool _solvableByReverseIds(LevelData level) {
  final c = GameController(level.clone());
  final ids = c.arrows.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final id in ids) {
    if (c.preview(id).result != MoveResult.cleared) return false;
    c.tryMove(id);
  }
  return c.isWon;
}

bool _isSolvableDfs(LevelData level) {
  bool dfs(Map<int, ArrowPiece> arrows) {
    if (arrows.isEmpty) return true;
    final c = GameController(
      LevelData(
        id: level.id,
        rows: level.rows,
        cols: level.cols,
        arrows: arrows.values.map((a) => a.copy()).toList(),
      ),
    );
    final ids = c.clearableArrowIds();
    if (ids.isEmpty) return false;
    for (final id in ids) {
      final next = Map<int, ArrowPiece>.from(arrows)..remove(id);
      if (dfs(next)) return true;
    }
    return false;
  }

  return dfs({for (final a in level.arrows) a.id: a.copy()});
}
