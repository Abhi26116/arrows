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

  /// Each entry: `[row, col, directionIndex]` or `[row, col, directionIndex,
  /// length]`, where row/col is the arrow tip, directionIndex maps to
  /// `Direction.values` and length defaults to 1.
  final List<List<int>> placements;

  LevelData toLevel(int id) {
    final arrows = <ArrowPiece>[];
    for (var i = 0; i < placements.length; i++) {
      final p = placements[i];
      arrows.add(
        ArrowPiece(
          id: i,
          row: p[0],
          col: p[1],
          direction: Direction.values[p[2]],
          length: p.length > 3 ? p[3] : 1,
          colorIndex: i % 6,
        ),
      );
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
