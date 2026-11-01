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
      // The head is as wide as the chevron even when the shaft is a stub.
      expect(bounds.height, greaterThan(cell * 0.5), reason: 'length $length');
      expect(bounds.width, greaterThan(cell * 0.5), reason: 'length $length');
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
