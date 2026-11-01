import 'package:arrows_game/models/arrow.dart';
import 'package:arrows_game/models/direction.dart';
import 'package:arrows_game/widgets/arrow_glyph.dart';
import 'package:flutter_test/flutter_test.dart';

List<Offset> spineOf(ArrowPiece a, double cell) => [
      for (final (r, c) in a.cells)
        Offset((c + 0.5) * cell, (r + 0.5) * cell),
    ];

void main() {
  const cell = 40.0;

  test('every arrow length draws something, down to a single cell', () {
    for (final length in [1, 2, 5]) {
      final arrow = ArrowPiece(
        id: 0,
        row: 3,
        col: 3,
        direction: Direction.right,
        length: length,
      );
      final path = buildArrowPath(
        spine: spineOf(arrow, cell),
        direction: arrow.direction,
        cell: cell,
      );
      final bounds = path.getBounds();
      expect(bounds.isEmpty, isFalse, reason: 'length $length drew nothing');
      // The chevron is scaled to the run it sits on, so a single-cell arrow
      // gets a smaller head than a long one — but still a legible arrow, not
      // a bare tick.
      expect(bounds.height, greaterThan(cell * 0.4), reason: 'length $length');
      expect(bounds.width, greaterThan(cell * 0.5), reason: 'length $length');
    }
  });

  test('a body that turns at the tip still leads with its head', () {
    // length 1 then an immediate turn: the second cell sits beside the tip,
    // not behind it, so the head has to follow the arrow's facing rather
    // than the first segment of the body.
    final arrow = ArrowPiece(
      id: 0,
      row: 3,
      col: 3,
      direction: Direction.up,
      length: 1,
      bends: [(Direction.right, 3)],
    );
    final bounds = buildArrowPath(
      spine: spineOf(arrow, cell),
      direction: arrow.direction,
      cell: cell,
    ).getBounds();

    final tipY = (arrow.row + 0.5) * cell;
    expect(bounds.top, lessThan(tipY - cell * 0.25),
        reason: 'the head should reach past the tip cell, pointing up');
  });

  test('the home artwork never stacks two arrows on one cell', () {
    // Home draws these straight through with no board behind them, so a
    // shared cell reads as one arrow printed over another.
    final seen = <(int, int), int>{};
    for (final arrow in MiniBoardArt.arrows) {
      for (final cell in arrow.cells) {
        expect(seen.containsKey(cell), isFalse,
            reason: 'arrow ${arrow.id} lands on ${seen[cell]} at $cell');
        seen[cell] = arrow.id;
        expect(cell.$1, inInclusiveRange(0, 3), reason: 'row off the grid');
        expect(cell.$2, inInclusiveRange(0, 5), reason: 'col off the grid');
      }
    }
  });

  test('a bent arrow is drawn across every cell it turns through', () {
    final arrow = ArrowPiece(
      id: 0,
      row: 4,
      col: 0,
      direction: Direction.left,
      length: 4,
      bends: [(Direction.up, 3)],
    );
    final bounds = buildArrowPath(
      spine: spineOf(arrow, cell),
      direction: arrow.direction,
      cell: cell,
    ).getBounds();

    // Four cells across and four up share the corner cell, so the spine
    // covers three cell steps each way, plus the reach past each end.
    expect(bounds.width, greaterThan(cell * 3));
    expect(bounds.height, greaterThan(cell * 3));
    expect(bounds.width, lessThan(cell * 4));
    expect(bounds.height, lessThan(cell * 4));
  });

  test('simplifySpine keeps corners and drops the straight runs', () {
    final straight = [
      for (var i = 0; i < 5; i++) Offset(i * cell, 0),
    ];
    expect(simplifySpine(straight), [straight.first, straight.last]);

    final elbow = [
      const Offset(0, 0),
      const Offset(cell, 0),
      const Offset(2 * cell, 0),
      const Offset(2 * cell, cell),
      const Offset(2 * cell, 2 * cell),
    ];
    expect(simplifySpine(elbow), [
      const Offset(0, 0),
      const Offset(2 * cell, 0),
      const Offset(2 * cell, 2 * cell),
    ]);
  });

  test('slicePolyline walks a bent track by arc length', () {
    final track = [
      const Offset(0, 0),
      const Offset(100, 0),
      const Offset(100, 100),
    ];
    expect(slicePolyline(track, 0, 50), [
      const Offset(0, 0),
      const Offset(50, 0),
    ]);
    // Straddling the corner keeps it.
    expect(slicePolyline(track, 50, 150), [
      const Offset(50, 0),
      const Offset(100, 0),
      const Offset(100, 50),
    ]);
    expect(slicePolyline(track, 10, 10), isEmpty);
  });
}
