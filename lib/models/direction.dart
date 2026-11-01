enum Direction {
  up,
  down,
  left,
  right;

  int get dRow {
    switch (this) {
      case Direction.up:
        return -1;
      case Direction.down:
        return 1;
      case Direction.left:
      case Direction.right:
        return 0;
    }
  }

  int get dCol {
    switch (this) {
      case Direction.left:
        return -1;
      case Direction.right:
        return 1;
      case Direction.up:
      case Direction.down:
        return 0;
    }
  }

  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }

  /// The two directions at right angles to this one — the turns a bent arrow
  /// body is allowed to take.
  List<Direction> get perpendicular => dRow == 0
      ? const [Direction.up, Direction.down]
      : const [Direction.left, Direction.right];

  double get angle {
    switch (this) {
      case Direction.up:
        return -1.5708; // -pi/2
      case Direction.down:
        return 1.5708;
      case Direction.left:
        return 3.14159;
      case Direction.right:
        return 0;
    }
  }
}
