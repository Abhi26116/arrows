import 'package:arrows_game/screens/game_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [placeBoard] gets the space under the progress bar — these sizes are what
/// that space measures on the devices named.
void main() {
  test('a tall phone gets its board centred under the header', () {
    const space = Size(402, 669); // iPhone 15-class
    final board = placeBoard(space);
    expect(board.side, 394);
    expect(board.top, (space.height - board.side) / 2);
  });

  test('a short phone lifts the board just clear of the floating buttons', () {
    const space = Size(375, 538); // iPhone SE
    final board = placeBoard(space);
    // Still as wide as the screen allows: lifted, not shrunk.
    expect(board.side, 367);
    expect(space.height - board.top - board.side, 120);
    expect(board.top, lessThan((space.height - board.side) / 2));
  });

  test('a landscape tablet uses its full height, beside the buttons', () {
    const space = Size(976, 586); // iPad Pro 12.9", landscape
    final board = placeBoard(space);
    expect(board.side, 578);
    expect(board.top, 4);
  });
}
