enum GamePhase { waitingForRoll, choosingTiles, blocked, complete }

final class DiceRoll {
  const DiceRoll(this.first, this.second)
    : assert(first >= 1 && first <= 6),
      assert(second >= 1 && second <= 6);

  final int first;
  final int second;

  int get total => first + second;
  List<int> get values => [first, second];
}

final class PlayerBoard {
  PlayerBoard({
    required this.index,
    required this.name,
    required Iterable<int> openTiles,
    this.score,
  }) : openTiles = Set<int>.unmodifiable(openTiles);

  factory PlayerBoard.newPlayer({required int index, required int tileCount}) {
    return PlayerBoard(
      index: index,
      name: 'Player ${index + 1}',
      openTiles: List<int>.generate(tileCount, (tile) => tile + 1),
    );
  }

  final int index;
  final String name;
  final Set<int> openTiles;
  final int? score;

  bool get isComplete => score != null;
  bool get isShut => isComplete && score == 0;
  int get remainingTotal => openTiles.fold(0, (sum, tile) => sum + tile);

  PlayerBoard copyWith({Iterable<int>? openTiles, int? score}) {
    return PlayerBoard(
      index: index,
      name: name,
      openTiles: openTiles ?? this.openTiles,
      score: score ?? this.score,
    );
  }
}

final class GameSnapshot {
  GameSnapshot({
    required this.tileCount,
    required List<PlayerBoard> players,
    required this.activePlayerIndex,
    required this.phase,
    this.currentRoll,
    Iterable<int> selectedTiles = const [],
  }) : players = List<PlayerBoard>.unmodifiable(players),
       selectedTiles = Set<int>.unmodifiable(selectedTiles);

  factory GameSnapshot.initial({int playerCount = 1, int tileCount = 10}) {
    assert(playerCount > 0);
    assert(tileCount > 0);

    return GameSnapshot(
      tileCount: tileCount,
      players: List<PlayerBoard>.generate(
        playerCount,
        (index) => PlayerBoard.newPlayer(index: index, tileCount: tileCount),
      ),
      activePlayerIndex: 0,
      phase: GamePhase.waitingForRoll,
    );
  }

  final int tileCount;
  final List<PlayerBoard> players;
  final int activePlayerIndex;
  final GamePhase phase;
  final DiceRoll? currentRoll;
  final Set<int> selectedTiles;

  PlayerBoard get activePlayer => players[activePlayerIndex];
  int get selectedTotal => selectedTiles.fold(0, (sum, tile) => sum + tile);
  bool get isSelectionValid => selectedTotal == currentRoll?.total;

  List<PlayerBoard> get rankedPlayers {
    final completePlayers =
        players.where((player) => player.isComplete).toList()
          ..sort((a, b) => a.score!.compareTo(b.score!));
    return List<PlayerBoard>.unmodifiable(completePlayers);
  }

  List<PlayerBoard> get winners {
    if (phase != GamePhase.complete || rankedPlayers.isEmpty) {
      return const [];
    }

    final bestScore = rankedPlayers.first.score;
    return List<PlayerBoard>.unmodifiable(
      rankedPlayers.where((player) => player.score == bestScore),
    );
  }

  PlayerBoard? get winner {
    final roundWinners = winners;
    if (roundWinners.length != 1) {
      return null;
    }
    return roundWinners.single;
  }

  GameSnapshot copyWith({
    int? tileCount,
    List<PlayerBoard>? players,
    int? activePlayerIndex,
    GamePhase? phase,
    DiceRoll? currentRoll,
    bool clearRoll = false,
    Iterable<int>? selectedTiles,
  }) {
    return GameSnapshot(
      tileCount: tileCount ?? this.tileCount,
      players: players ?? this.players,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      phase: phase ?? this.phase,
      currentRoll: clearRoll ? null : currentRoll ?? this.currentRoll,
      selectedTiles: selectedTiles ?? this.selectedTiles,
    );
  }
}
