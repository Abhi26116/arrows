import 'arrow.dart';
import 'direction.dart';

/// An animal penned in by the arrows around it. It owns a square block of
/// cells that no arrow may use, so the board is woven around it; clearing the
/// arrows that ring that block sets it loose.
///
/// Decoration and progress only — the level is still won by clearing every
/// arrow, so a captive can never make a board unsolvable.
class Captive {
  const Captive({
    required this.row,
    required this.col,
    required this.span,
    required this.kind,
  });

  /// Top-left cell of the block.
  final int row;
  final int col;

  /// Width and height of the block, in cells.
  final int span;

  /// Which animal to draw; the painter maps this to a glyph.
  final CaptiveKind kind;

  /// Every cell the animal sits on.
  Iterable<(int, int)> get cells sync* {
    for (var r = row; r < row + span; r++) {
      for (var c = col; c < col + span; c++) {
        yield (r, c);
      }
    }
  }

  /// Whether anything in [occupied] still stands on the fence. The animal is
  /// loose the moment that ring is clear — it does not have to wait for the
  /// whole board.
  bool isPennedBy(Set<(int, int)> occupied) => fence.any(occupied.contains);

  /// The ring of cells just outside the block. An arrow standing on any of
  /// these is still penning the animal in.
  Iterable<(int, int)> get fence sync* {
    for (var r = row - 1; r <= row + span; r++) {
      for (var c = col - 1; c <= col + span; c++) {
        final inside = r >= row && r < row + span && c >= col && c < col + span;
        if (!inside) yield (r, c);
      }
    }
  }
}

enum CaptiveKind { paw, bunny }

class LevelData {
  const LevelData({
    required this.id,
    required this.rows,
    required this.cols,
    required this.arrows,
    this.captives = const [],
    this.label,
    this.difficulty = 'Easy',
  });

  final int id;
  final int rows;
  final int cols;
  final List<ArrowPiece> arrows;

  /// Animals penned in by the arrows. Usually empty on the early boards.
  final List<Captive> captives;

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
        captives: captives,
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
