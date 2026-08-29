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
