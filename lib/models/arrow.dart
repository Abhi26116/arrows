import 'dart:math' as math;

import 'direction.dart';

/// A single arrow piece.
///
/// [row]/[col] are the **tip** cell (where the head is drawn). The body extends
/// [length] cells backwards, opposite [direction], so a length-1 arrow occupies
/// exactly its tip cell.
class ArrowPiece {
  ArrowPiece({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.length = 1,
    this.colorIndex = 0,
  });

  final int id;
  int row;
  int col;
  final Direction direction;

  /// Number of cells the arrow occupies along its axis.
  final int length;
  final int colorIndex;

  int get tailRow => row - direction.dRow * (length - 1);
  int get tailCol => col - direction.dCol * (length - 1);

  bool get isHorizontal => direction.dRow == 0;

  /// Every cell the arrow occupies, tip first.
  List<(int, int)> get cells => [
        for (var i = 0; i < length; i++)
          (row - direction.dRow * i, col - direction.dCol * i),
      ];

  bool covers(int r, int c) {
    if (isHorizontal) {
      if (r != row) return false;
      return c >= math.min(col, tailCol) && c <= math.max(col, tailCol);
    }
    if (c != col) return false;
    return r >= math.min(row, tailRow) && r <= math.max(row, tailRow);
  }

  ArrowPiece copy() => ArrowPiece(
        id: id,
        row: row,
        col: col,
        direction: direction,
        length: length,
        colorIndex: colorIndex,
      );
}
