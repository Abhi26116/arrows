import 'dart:math';

import '../models/arrow.dart';
import '../models/direction.dart';
import '../models/level.dart';

/// Generates solvable levels by placing arrows in reverse-removal order.
///
/// An arrow is only placed when the corridor from its tip to the board edge is
/// still empty, so removing arrows in reverse placement order always works.
class LevelGenerator {
  LevelGenerator([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  /// Stop after this many consecutive failed placements — the board is full.
  static const int _stallLimit = 2500;
  static const int _maxAttempts = 60000;

  LevelData generate({
    required int id,
    required int rows,
    required int cols,
    int? arrowCount,
    double fill = 0,
    int maxLength = 1,
    String difficulty = 'Easy',
    String? label,
  }) {
    final occupied = <(int, int)>{};
    final placed = <ArrowPiece>[];
    final targetCells = (rows * cols * fill).round();
    var attempts = 0;
    var stall = 0;

    bool reachedTarget() => arrowCount != null
        ? placed.length >= arrowCount
        : occupied.length >= targetCells;

    while (!reachedTarget() && attempts < _maxAttempts && stall < _stallLimit) {
      attempts++;
      stall++;
      final row = _rng.nextInt(rows);
      final col = _rng.nextInt(cols);
      if (occupied.contains((row, col))) continue;

      final dirs = List<Direction>.from(Direction.values)..shuffle(_rng);
      for (final dir in dirs) {
        if (!_pathClear(row, col, dir, rows, cols, occupied)) continue;

        final fits = _bodyRoom(row, col, dir, rows, cols, occupied, maxLength);
        if (fits < 1) continue;

        final piece = ArrowPiece(
          id: placed.length,
          row: row,
          col: col,
          direction: dir,
          length: _pickLength(fits),
          colorIndex: placed.length % 6,
        );
        placed.add(piece);
        occupied.addAll(piece.cells);
        stall = 0;
        break;
      }
    }

    return LevelData(
      id: id,
      rows: rows,
      cols: cols,
      label: label,
      difficulty: difficulty,
      arrows: placed,
    );
  }

  /// Biased toward longer arrows so boards read like the woven-line reference
  /// art instead of a field of dots.
  int _pickLength(int maxFit) {
    if (maxFit <= 1) return 1;
    final a = 1 + _rng.nextInt(maxFit);
    final b = 1 + _rng.nextInt(maxFit);
    return a > b ? a : b;
  }

  /// How many cells (including the tip) the body can occupy behind the tip.
  int _bodyRoom(
    int row,
    int col,
    Direction dir,
    int rows,
    int cols,
    Set<(int, int)> occupied,
    int maxLength,
  ) {
    var room = 1;
    for (var i = 1; i < maxLength; i++) {
      final r = row - dir.dRow * i;
      final c = col - dir.dCol * i;
      if (r < 0 || r >= rows || c < 0 || c >= cols) break;
      if (occupied.contains((r, c))) break;
      room++;
    }
    return room;
  }

  bool _pathClear(
    int row,
    int col,
    Direction dir,
    int rows,
    int cols,
    Set<(int, int)> occupied,
  ) {
    var r = row + dir.dRow;
    var c = col + dir.dCol;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      if (occupied.contains((r, c))) return false;
      r += dir.dRow;
      c += dir.dCol;
    }
    return true;
  }
}

class LevelPack {
  const LevelPack(this.name, this.startId, this.endId);
  final String name;
  final int startId;
  final int endId;
}

class LevelCatalog {
  LevelCatalog._();

  static final _gen = LevelGenerator(Random(42));

  static List<LevelData>? _cache;
  static List<LevelPack>? _packs;

  static List<LevelData> get all {
    _cache ??= [..._handcrafted, ..._generated];
    return _cache!;
  }

  static LevelData byId(int id) => all.firstWhere((l) => l.id == id);

  static int get count => all.length;

  static List<LevelPack> get packs {
    _packs ??= _buildPacks();
    return _packs!;
  }

  static List<LevelPack> _buildPacks() {
    // Keep in sync with handcrafted count + generated pack sizes below.
    return const [
      LevelPack('Tutorial', 1, 6),
      LevelPack('Warmup', 7, 14),
      LevelPack('Focus', 15, 24),
      LevelPack('Tangled', 25, 36),
      LevelPack('Pressure', 37, 50),
      LevelPack('Master', 51, 64),
      LevelPack('Endless Edge', 65, 80),
    ];
  }

  /// Tutorial boards stay small and hand-placed — they introduce arrow length.
  /// Placements are `[tipRow, tipCol, directionIndex, length]`; the body runs
  /// backwards from the tip, so an up-arrow's tail sits *below* it.
  static final List<LevelData> _handcrafted = [
    const LevelSpec(
      rows: 3,
      cols: 3,
      label: 'First Shot',
      placements: [
        [1, 2, 3, 2],
      ],
    ).toLevel(1),
    const LevelSpec(
      rows: 4,
      cols: 4,
      label: 'Order Matters',
      placements: [
        [1, 1, 3, 2],
        [1, 3, 3, 1],
      ],
    ).toLevel(2),
    const LevelSpec(
      rows: 4,
      cols: 4,
      label: 'Crossroads',
      placements: [
        [0, 1, 1, 1],
        [2, 1, 3, 2],
        [2, 3, 0, 1],
      ],
    ).toLevel(3),
    const LevelSpec(
      rows: 5,
      cols: 5,
      label: 'Traffic',
      placements: [
        [0, 1, 3, 2],
        [0, 3, 3, 1],
        [2, 4, 1, 2],
        [2, 2, 0, 3],
        [4, 3, 2, 2],
      ],
    ).toLevel(4),
    const LevelSpec(
      rows: 5,
      cols: 5,
      label: 'Cascade',
      placements: [
        [1, 4, 1, 2],
        [2, 4, 2, 1],
        [2, 2, 1, 2],
        [4, 2, 2, 2],
        [2, 0, 0, 3],
      ],
    ).toLevel(5),
    const LevelSpec(
      rows: 6,
      cols: 6,
      label: 'Knot',
      placements: [
        [0, 2, 3, 3],
        [0, 4, 1, 1],
        [2, 4, 2, 2],
        [2, 1, 1, 2],
        [4, 3, 3, 3],
        [5, 5, 1, 2],
        [1, 5, 2, 1],
      ],
    ).toLevel(6),
  ];

  static List<LevelData> get _generated {
    final levels = <LevelData>[];
    var id = _handcrafted.length + 1;

    // (label, rows, cols, fill, maxLength, count, difficulty). Boards grow and
    // arrows get longer together, so late packs look like the dense woven grid
    // while staying generated in reverse-removal (always solvable) order.
    final packDefs = <(String, int, int, double, int, int, String)>[
      ('Warmup', 7, 7, 0.42, 3, 4, 'Easy'),
      ('Warmup', 8, 8, 0.46, 3, 4, 'Easy'),
      ('Focus', 9, 9, 0.50, 4, 5, 'Medium'),
      ('Focus', 10, 10, 0.54, 4, 5, 'Medium'),
      ('Tangled', 11, 11, 0.56, 5, 6, 'Medium'),
      ('Tangled', 12, 12, 0.58, 5, 6, 'Medium'),
      ('Pressure', 13, 13, 0.60, 6, 7, 'Hard'),
      ('Pressure', 14, 14, 0.62, 7, 7, 'Hard'),
      ('Master', 15, 15, 0.64, 8, 7, 'Hard'),
      ('Master', 16, 16, 0.66, 9, 7, 'Hard'),
      ('Endless Edge', 17, 17, 0.68, 10, 8, 'Expert'),
      ('Endless Edge', 18, 18, 0.70, 12, 8, 'Expert'),
    ];

    for (final pack in packDefs) {
      final (label, rows, cols, fill, maxLength, count, difficulty) = pack;
      for (var i = 0; i < count; i++) {
        levels.add(
          _gen.generate(
            id: id,
            rows: rows,
            cols: cols,
            fill: fill,
            maxLength: maxLength,
            difficulty: difficulty,
            label: '$label $id',
          ),
        );
        id++;
      }
    }
    return levels;
  }
}
