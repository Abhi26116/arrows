import '../models/arrow.dart';
import '../models/level.dart';

enum MoveResult { cleared, blocked, invalid }

class MoveOutcome {
  const MoveOutcome({
    required this.result,
    this.path = const [],
    this.blockerId,
  });

  final MoveResult result;

  /// Cells from the arrow tip forward, ending one step past the board edge.
  final List<(int, int)> path;
  final int? blockerId;
}

class GameController {
  GameController(LevelData level)
      : rows = level.rows,
        cols = level.cols,
        levelId = level.id,
        _arrows = {for (final a in level.arrows) a.id: a.copy()} {
    for (final a in _arrows.values) {
      _occupy(a);
    }
  }

  final int rows;
  final int cols;
  final int levelId;
  final Map<int, ArrowPiece> _arrows;

  /// Cell key -> arrow id, so blocking checks stay O(1) on dense boards.
  final Map<int, int> _cells = {};

  Map<int, ArrowPiece> get arrows => Map.unmodifiable(_arrows);
  int get remaining => _arrows.length;
  bool get isWon => _arrows.isEmpty;

  int _key(int row, int col) => row * cols + col;

  void _occupy(ArrowPiece a) {
    for (final (r, c) in a.cells) {
      _cells[_key(r, c)] = a.id;
    }
  }

  void _release(ArrowPiece a) {
    for (final (r, c) in a.cells) {
      _cells.remove(_key(r, c));
    }
  }

  ArrowPiece? arrowAt(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return null;
    final id = _cells[_key(row, col)];
    return id == null ? null : _arrows[id];
  }

  MoveOutcome preview(int arrowId) {
    final arrow = _arrows[arrowId];
    if (arrow == null) {
      return const MoveOutcome(result: MoveResult.invalid);
    }
    return _trace(arrow);
  }

  MoveOutcome tryMove(int arrowId) {
    final outcome = preview(arrowId);
    if (outcome.result == MoveResult.cleared) {
      final arrow = _arrows.remove(arrowId);
      if (arrow != null) _release(arrow);
    }
    return outcome;
  }

  /// Walks forward from the arrow tip to the board edge.
  MoveOutcome _trace(ArrowPiece arrow) {
    final path = <(int, int)>[(arrow.row, arrow.col)];
    var r = arrow.row + arrow.direction.dRow;
    var c = arrow.col + arrow.direction.dCol;

    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      path.add((r, c));
      final hit = arrowAt(r, c);
      if (hit != null && hit.id != arrow.id) {
        return MoveOutcome(
          result: MoveResult.blocked,
          path: path,
          blockerId: hit.id,
        );
      }
      r += arrow.direction.dRow;
      c += arrow.direction.dCol;
    }
    // One extra step past the board edge for the fly-out animation.
    path.add((r, c));
    return MoveOutcome(result: MoveResult.cleared, path: path);
  }

  /// Cells along the flight path (excluding start) used for hint highlighting.
  List<(int, int)> clearablePath(int arrowId) {
    final o = preview(arrowId);
    if (o.result != MoveResult.cleared) return const [];
    return o.path.length > 1 ? o.path.sublist(1) : const [];
  }

  List<int> clearableArrowIds() {
    return _arrows.keys
        .where((id) => preview(id).result == MoveResult.cleared)
        .toList();
  }
}

/// Snapshot-based controller with undo support and a lives counter.
class PlaySession {
  PlaySession(this.initial) {
    reset();
  }

  static const int maxLives = 3;

  final LevelData initial;
  late GameController controller;
  final List<Map<int, ArrowPiece>> _snapshots = [];
  int moves = 0;
  int mistakes = 0;

  int get totalArrows => initial.arrows.length;
  int get cleared => totalArrows - controller.remaining;

  double get progress =>
      totalArrows == 0 ? 1 : (cleared / totalArrows).clamp(0.0, 1.0);

  /// Hearts left. Undo rewinds the board but never refunds a heart.
  int get lives => (maxLives - mistakes).clamp(0, maxLives);
  bool get isOutOfLives => lives <= 0;

  bool get canUndo => _snapshots.length > 1;

  void reset() {
    controller = GameController(initial.clone());
    _snapshots.clear();
    _pushSnapshot();
    moves = 0;
    mistakes = 0;
  }

  void _pushSnapshot() {
    _snapshots.add({
      for (final e in controller.arrows.entries) e.key: e.value.copy(),
    });
  }

  MoveOutcome tap(int arrowId) {
    final outcome = controller.tryMove(arrowId);
    if (outcome.result == MoveResult.cleared) {
      moves++;
      _pushSnapshot();
    } else if (outcome.result == MoveResult.blocked) {
      mistakes++;
    }
    return outcome;
  }

  bool undo() {
    if (_snapshots.length <= 1) return false;
    _snapshots.removeLast();
    final snap = _snapshots.last;
    controller = GameController(
      LevelData(
        id: initial.id,
        rows: initial.rows,
        cols: initial.cols,
        label: initial.label,
        difficulty: initial.difficulty,
        arrows: snap.values.map((a) => a.copy()).toList(),
      ),
    );
    if (moves > 0) moves--;
    return true;
  }

  /// Gives a heart back (rewarded-ad continue).
  void grantLife() {
    if (mistakes > 0) mistakes--;
  }
}
