import 'game_models.dart';

final class GameRules {
  const GameRules._();

  static bool hasValidMove({required Set<int> openTiles, required int target}) {
    return validMoves(openTiles: openTiles, target: target).isNotEmpty;
  }

  static List<List<int>> validMoves({
    required Set<int> openTiles,
    required int target,
  }) {
    final tiles = openTiles.toList()..sort();
    final moves = <List<int>>[];

    void search(int start, int remaining, List<int> path) {
      if (remaining == 0) {
        moves.add(List<int>.unmodifiable(path));
        return;
      }

      for (var index = start; index < tiles.length; index++) {
        final tile = tiles[index];
        if (tile > remaining) {
          break;
        }
        path.add(tile);
        search(index + 1, remaining - tile, path);
        path.removeLast();
      }
    }

    search(0, target, <int>[]);
    moves.sort(_compareMoves);
    return List<List<int>>.unmodifiable(moves);
  }

  static bool isValidSelection({
    required Set<int> openTiles,
    required DiceRoll roll,
    required Set<int> selectedTiles,
  }) {
    if (selectedTiles.isEmpty) {
      return false;
    }

    final selectedTotal = selectedTiles.fold(0, (sum, tile) => sum + tile);
    return selectedTotal == roll.total && openTiles.containsAll(selectedTiles);
  }

  static PlayerBoard closeTiles({
    required PlayerBoard player,
    required Set<int> selectedTiles,
  }) {
    final nextOpenTiles = Set<int>.of(player.openTiles)
      ..removeAll(selectedTiles);
    return player.copyWith(openTiles: nextOpenTiles);
  }

  static int score(PlayerBoard player) => player.remainingTotal;

  static int _compareMoves(List<int> a, List<int> b) {
    final lengthCompare = a.length.compareTo(b.length);
    if (lengthCompare != 0) {
      return lengthCompare;
    }
    for (var index = 0; index < a.length; index++) {
      final tileCompare = b[index].compareTo(a[index]);
      if (tileCompare != 0) {
        return tileCompare;
      }
    }
    return 0;
  }
}
