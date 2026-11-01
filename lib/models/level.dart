import 'arrow.dart';
import 'direction.dart';

class LevelData {
  const LevelData({
    required this.id,
    required this.rows,
    required this.cols,
    required this.arrows,
    this.label,
    this.difficulty = 'Easy',
  });

  final int id;
  final int rows;
  final int cols;
  final List<ArrowPiece> arrows;
  final String? label;

  /// Shown as the board title: Easy / Medium / Hard / Expert.
  final String difficulty;

  LevelData clone() => LevelData(
        id: id,
        rows: rows,
        cols: cols,
        label: label,
        difficulty: difficulty,
        arrows: arrows.map((a) => a.copy()).toList(),
      );
}

class LevelSpec {
  const LevelSpec({
    required this.rows,
    required this.cols,
    required this.placements,
    this.label,
    this.difficulty = 'Easy',
  });

  final int rows;
  final int cols;
  final String? label;
  final String difficulty;

  /// Each entry is `[row, col, directionIndex]`, optionally followed by
  /// `length`, then by any number of `directionIndex, runLength` pairs.
  ///
  /// row/col is the arrow tip, directionIndex maps to `Direction.values` and
  /// length (default 1) counts the straight run back from the tip. Each extra
  /// pair bends the body, travelling further tailwards in that direction — so
  /// `[2, 6, 2, 4, 0, 3]` is an arrow pointing left with a four-cell shaft
  /// that then turns and runs three cells up.
  final List<List<int>> placements;

  /// Every seventh arrow is painted in the accent colour. Decoration only —
  /// it spaces the highlights out evenly across a board.
  static bool accentAt(int index) => index % 7 == 3;

  LevelData toLevel(int id) {
    final arrows = <ArrowPiece>[];
    for (var i = 0; i < placements.length; i++) {
      final p = placements[i];
      final bends = <(Direction, int)>[];
      for (var j = 4; j + 1 < p.length; j += 2) {
        bends.add((Direction.values[p[j]], p[j + 1]));
      }
      final piece = ArrowPiece(
        id: i,
        row: p[0],
        col: p[1],
        direction: Direction.values[p[2]],
        length: p.length > 3 ? p[3] : 1,
        bends: bends,
        accent: accentAt(i),
      );
      assert(
        !piece.blocksItself,
        'level $id arrow $i bends back into its own flight path',
      );
      arrows.add(piece);
    }
    return LevelData(
      id: id,
      rows: rows,
      cols: cols,
      arrows: arrows,
      label: label,
      difficulty: difficulty,
    );
  }
}
