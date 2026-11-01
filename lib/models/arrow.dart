import 'direction.dart';

/// A single arrow piece, modelled as a path of cells.
///
/// [row]/[col] are the **tip** cell (where the head is drawn) and [direction]
/// is the way the head points. The body runs backwards from the tip: first
/// [length] cells straight back along the opposite of [direction], then one
/// run per entry in [bends], each travelling further tailwards in its own
/// direction. A length-1 arrow with no bends occupies exactly its tip cell.
///
/// An arrow leaves the board tip first, its body following its own track, so
/// whether it can escape still depends only on the straight corridor ahead of
/// the tip — bends change the shape, never the blocking rule.
class ArrowPiece {
  ArrowPiece({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.length = 1,
    this.bends = const [],
    this.accent = false,
  });

  final int id;
  final int row;
  final int col;
  final Direction direction;

  /// Cells in the first, straight run — including the tip.
  final int length;

  /// Further runs, tailwards, each `(travel direction, cell count)`.
  final List<(Direction, int)> bends;

  /// Painted in the theme's accent line colour. Decoration only: it carries
  /// no gameplay meaning, it just breaks up a dense board the way the
  /// reference art does.
  final bool accent;

  List<(int, int)>? _cells;

  /// Every cell the arrow occupies, tip first, tail last.
  List<(int, int)> get cells {
    final cached = _cells;
    if (cached != null) return cached;

    final out = <(int, int)>[(row, col)];
    var r = row;
    var c = col;
    final back = direction.opposite;
    for (var i = 1; i < length; i++) {
      r += back.dRow;
      c += back.dCol;
      out.add((r, c));
    }
    for (final (travel, count) in bends) {
      for (var i = 0; i < count; i++) {
        r += travel.dRow;
        c += travel.dCol;
        out.add((r, c));
      }
    }
    return _cells = List.unmodifiable(out);
  }

  bool get isBent => bends.isNotEmpty;

  (int, int) get tail => cells.last;
  int get tailRow => tail.$1;
  int get tailCol => tail.$2;

  bool get isHorizontal => direction.dRow == 0;

  bool covers(int r, int c) {
    for (final cell in cells) {
      if (cell.$1 == r && cell.$2 == c) return true;
    }
    return false;
  }

  /// True when part of the body sits in the arrow's own flight path, which
  /// would make it run into itself on the way out. Levels must never contain
  /// one; the generator refuses to build them.
  bool get blocksItself {
    final body = cells;
    for (var i = 1; i < body.length; i++) {
      final (r, c) = body[i];
      if (isHorizontal) {
        if (r == row && (c - col) * direction.dCol > 0) return true;
      } else {
        if (c == col && (r - row) * direction.dRow > 0) return true;
      }
    }
    return false;
  }

  ArrowPiece copy() => ArrowPiece(
        id: id,
        row: row,
        col: col,
        direction: direction,
        length: length,
        bends: bends,
        accent: accent,
      );
}
