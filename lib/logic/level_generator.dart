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
  static const int _maxAttempts = 60000;

  /// Shortest run after a turn: a single-cell jog reads as a glitch rather
  /// than a corner.
  static const int _minBendRun = 2;

  LevelData generate({
    required int id,
    required int rows,
    required int cols,
    int? arrowCount,
    double fill = 0,
    int maxLength = 1,
    double bendChance = 0,
    int maxBends = 2,
    int captiveCount = 0,
    String difficulty = 'Easy',
    String? label,
  }) {
    final occupied = <(int, int)>{};
    final placed = <ArrowPiece>[];

    // Pen the animals first and mark their cells taken, so the arrows are
    // woven around them and no exit path is ever planned through one.
    final captives = _placeCaptives(rows, cols, captiveCount);
    for (final captive in captives) {
      occupied.addAll(captive.cells);
    }
    final reserved = occupied.length;

    final targetCells = ((rows * cols - reserved) * fill).round();
    var attempts = 0;

    bool reachedTarget() => arrowCount != null
        ? placed.length >= arrowCount
        : occupied.length - reserved >= targetCells;

    // Sweep the empty cells in a shuffled order rather than sampling at
    // random. Once a board is most of the way full a random pick nearly
    // always lands on a taken cell, so sampling stalls out while whole
    // regions have never been tried — which is what leaves a dense board
    // with one big hole in it. A sweep tries every empty cell, so the only
    // cells still empty at the end are the ones no arrow can legally use.
    var sweeping = true;
    while (sweeping && !reachedTarget() && attempts < _maxAttempts) {
      sweeping = false;
      final empties = <(int, int)>[
        for (var r = 0; r < rows; r++)
          for (var c = 0; c < cols; c++)
            if (!occupied.contains((r, c))) (r, c),
      ]..shuffle(_rng);
      // Centre cells first. An arrow is placed in reverse-removal order, so
      // it needs a corridor to the edge past everything already down: a cell
      // by the rim needs almost none, one in the middle needs the longest.
      // Claiming the middle while the board is still open spends that room
      // where it is scarce, and leaves the easy rim cells for last — which
      // is both denser overall and stops the hole opening up in the centre.
      int rim((int, int) p) =>
          min(min(p.$1, rows - 1 - p.$1), min(p.$2, cols - 1 - p.$2));
      empties.sort((a, b) => rim(b).compareTo(rim(a)));

      for (final (row, col) in empties) {
        if (reachedTarget() || attempts >= _maxAttempts) break;
        attempts++;
        if (occupied.contains((row, col))) continue;

        // Try every way the arrow could face and keep the one that grows the
        // longest body, rather than the first that merely fits. On a packed
        // board most directions back straight into another arrow and give a
        // single cell, so taking the first leaves a field of stubs; taking
        // the best keeps the long woven bodies the late packs are built on.
        final dirs = List<Direction>.from(Direction.values)..shuffle(_rng);
        Direction? bestDir;
        var bestLength = 0;
        List<(Direction, int)> bestBends = const [];
        var bestCells = 0;

        for (final dir in dirs) {
          if (!_pathClear(row, col, dir, rows, cols, occupied)) continue;

          final (length, bends) = _growBody(
            row,
            col,
            dir,
            rows,
            cols,
            occupied,
            maxLength,
            bendChance,
            maxBends,
          );
          var cells = length;
          for (final (_, run) in bends) {
            cells += run;
          }
          if (cells > bestCells) {
            bestCells = cells;
            bestDir = dir;
            bestLength = length;
            bestBends = bends;
          }
        }

        if (bestDir == null) continue;

        final piece = ArrowPiece(
          id: placed.length,
          row: row,
          col: col,
          direction: bestDir,
          length: bestLength,
          bends: bestBends,
          accent: LevelSpec.accentAt(placed.length),
        );
        placed.add(piece);
        occupied.addAll(piece.cells);
        sweeping = true;
      }
    }

    return LevelData(
      id: id,
      rows: rows,
      cols: cols,
      label: label,
      difficulty: difficulty,
      arrows: placed,
      captives: captives,
    );
  }

  /// Drops [count] animal pens into the middle band of the board, far enough
  /// apart that their fences do not touch. Kept off the rim so the arrows
  /// have room to close around them on every side.
  List<Captive> _placeCaptives(int rows, int cols, int count) {
    if (count <= 0 || rows < 9 || cols < 9) return const [];
    const span = 2;
    final out = <Captive>[];
    const margin = 2;
    for (var tries = 0; tries < 200 && out.length < count; tries++) {
      final row = margin + _rng.nextInt(rows - span - margin * 2 + 1);
      final col = margin + _rng.nextInt(cols - span - margin * 2 + 1);
      final clash = out.any((o) =>
          (row - o.row).abs() < span + 2 && (col - o.col).abs() < span + 2);
      if (clash) continue;
      out.add(Captive(
        row: row,
        col: col,
        span: span,
        kind: CaptiveKind.values[out.length % CaptiveKind.values.length],
      ));
    }
    return out;
  }

  /// Grows a body backwards from the tip: a straight run first, then up to
  /// [maxBends] right-angle turns, so dense boards read like a woven maze of
  /// bent paths instead of a field of parallel sticks.
  ///
  /// Body cells never enter the arrow's own flight path, so the arrow can
  /// always slide out tip-first along its own track.
  (int, List<(Direction, int)>) _growBody(
    int row,
    int col,
    Direction dir,
    int rows,
    int cols,
    Set<(int, int)> occupied,
    int maxLength,
    double bendChance,
    int maxBends,
  ) {
    final taken = <(int, int)>{(row, col)};
    var r = row;
    var c = col;
    var budget = maxLength - 1;

    bool free(int rr, int cc) {
      if (rr < 0 || rr >= rows || cc < 0 || cc >= cols) return false;
      if (occupied.contains((rr, cc)) || taken.contains((rr, cc))) return false;
      if (dir.dRow == 0) {
        if (rr == row && (cc - col) * dir.dCol > 0) return false;
      } else {
        if (cc == col && (rr - row) * dir.dRow > 0) return false;
      }
      return true;
    }

    int room(Direction travel, int limit) {
      var n = 0;
      var rr = r;
      var cc = c;
      while (n < limit) {
        rr += travel.dRow;
        cc += travel.dCol;
        if (!free(rr, cc)) break;
        n++;
      }
      return n;
    }

    void commit(Direction travel, int n) {
      for (var i = 0; i < n; i++) {
        r += travel.dRow;
        c += travel.dCol;
        taken.add((r, c));
      }
    }

    final back = dir.opposite;
    // Reserve room for the first turn up front: a greedy straight run would
    // otherwise eat the whole length budget and corners would never appear.
    var attemptBend = _rng.nextDouble() < bendChance;
    final straightLimit = attemptBend ? max(1, budget - _minBendRun) : budget;
    final straightRoom = room(back, straightLimit);
    final straight = straightRoom < 1 ? 0 : _pickLength(straightRoom);
    commit(back, straight);
    budget -= straight;

    // A body may only turn once the head has a whole cell of straight shaft
    // behind it. With none, the tip sits right on the corner: the chevron
    // overlaps the rounding and reads as a kink in the line rather than an
    // arrowhead. When there was no room to back up, stay a plain arrow.
    if (straight < 1) attemptBend = false;

    final bends = <(Direction, int)>[];
    var travel = back;
    while (attemptBend && budget >= _minBendRun && bends.length < maxBends) {
      final turns = List<Direction>.from(travel.perpendicular)..shuffle(_rng);
      var turned = false;
      for (final turn in turns) {
        // A single-cell jog reads as a glitch rather than a corner.
        final fits = room(turn, budget);
        if (fits < _minBendRun) continue;
        final run = _minBendRun + _rng.nextInt(fits - _minBendRun + 1);
        commit(turn, run);
        bends.add((turn, run));
        budget -= run;
        travel = turn;
        turned = true;
        break;
      }
      if (!turned) break;
      attemptBend = _rng.nextDouble() < bendChance;
    }

    return (straight + 1, bends);
  }

  /// Biased toward longer arrows so boards read like the woven-line reference
  /// art instead of a field of dots.
  int _pickLength(int maxFit) {
    if (maxFit <= 1) return 1;
    final a = 1 + _rng.nextInt(maxFit);
    final b = 1 + _rng.nextInt(maxFit);
    return a > b ? a : b;
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

  /// Tutorial boards stay small and hand-placed. They introduce arrow length
  /// first, then corners: level 5 hides one bend among straight arrows and
  /// level 6 builds a chain around two of them.
  ///
  /// Placements are `[tipRow, tipCol, directionIndex, length]` plus optional
  /// `directionIndex, runLength` pairs for each bend; the body runs backwards
  /// from the tip, so an up-arrow's tail sits *below* it.
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
        // First corner the player meets: the body turns up behind the tip,
        // which is what puts arrow 2 behind it in the queue.
        [4, 2, 2, 2, 0, 2],
        [2, 0, 0, 3],
      ],
    ).toLevel(5),
    const LevelSpec(
      rows: 6,
      cols: 6,
      label: 'Knot',
      // One free arrow and one eight-long chain, hinged on the two bent
      // bodies: each arrow's only way out runs through the next one's cells.
      placements: [
        [0, 0, 0, 1],
        [0, 2, 1, 1],
        [3, 2, 2, 2, 1, 2],
        [3, 1, 0, 3],
        [1, 1, 3, 2],
        [1, 4, 1, 2],
        [2, 4, 3, 2],
        [2, 5, 1, 2],
        [3, 5, 3, 2, 1, 2],
      ],
    ).toLevel(6),
  ];

  static List<LevelData> get _generated {
    final levels = <LevelData>[];
    var id = _handcrafted.length + 1;

    // (label, rows, cols, fill, maxLength, bendChance, maxBends, count,
    // difficulty, captives). Boards grow, arrows get longer and corners get both more
    // likely and more numerous together, so late packs read like the dense
    // woven maze — a six-turn body on Endless Edge is a square wave — while
    // staying generated in reverse-removal (always solvable) order. Warmup
    // keeps to a single corner; the tutorial has only just introduced them.
    // Animals show up once a board is wide enough to close around them.
    final packDefs =
        <(String, int, int, double, int, double, int, int, String, int)>[
      ('Warmup', 7, 7, 0.46, 4, 0.20, 1, 4, 'Easy', 0),
      ('Warmup', 8, 8, 0.52, 4, 0.25, 1, 4, 'Easy', 0),
      ('Focus', 9, 9, 0.58, 5, 0.30, 2, 5, 'Medium', 1),
      ('Focus', 10, 10, 0.63, 5, 0.35, 2, 5, 'Medium', 1),
      ('Tangled', 11, 11, 0.68, 6, 0.45, 2, 6, 'Medium', 1),
      ('Tangled', 12, 12, 0.72, 7, 0.50, 2, 6, 'Medium', 2),
      ('Pressure', 13, 13, 0.76, 8, 0.60, 3, 7, 'Hard', 2),
      ('Pressure', 14, 14, 0.80, 9, 0.65, 3, 7, 'Hard', 2),
      ('Master', 15, 15, 0.83, 11, 0.70, 4, 7, 'Hard', 2),
      ('Master', 16, 16, 0.85, 12, 0.75, 4, 7, 'Hard', 2),
      ('Endless Edge', 17, 17, 0.88, 14, 0.80, 5, 8, 'Expert', 3),
      ('Endless Edge', 18, 18, 0.90, 16, 0.85, 6, 8, 'Expert', 3),
    ];

    for (final pack in packDefs) {
      final (
        label,
        rows,
        cols,
        fill,
        maxLength,
        bendChance,
        maxBends,
        count,
        difficulty,
        captives
      ) = pack;
      for (var i = 0; i < count; i++) {
        levels.add(
          _gen.generate(
            id: id,
            rows: rows,
            cols: cols,
            fill: fill,
            maxLength: maxLength,
            bendChance: bendChance,
            maxBends: maxBends,
            captiveCount: captives,
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
