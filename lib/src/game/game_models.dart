enum GamePhase { waitingForRoll, choosingTiles, blocked, complete }

enum RulesetPreset { classic9, flip10, extended12, custom }

final class GameRuleset {
  const GameRuleset({
    required this.preset,
    required this.name,
    required this.tileCount,
    required this.useSingleDieWhenLow,
  });

  const GameRuleset.custom({required int tileCount})
    : this(
        preset: RulesetPreset.custom,
        name: 'Custom',
        tileCount: tileCount,
        useSingleDieWhenLow: false,
      );

  static const classic9 = GameRuleset(
    preset: RulesetPreset.classic9,
    name: 'Classic 9',
    tileCount: 9,
    useSingleDieWhenLow: true,
  );

  static const flip10 = GameRuleset(
    preset: RulesetPreset.flip10,
    name: 'Flip10',
    tileCount: 10,
    useSingleDieWhenLow: false,
  );

  static const extended12 = GameRuleset(
    preset: RulesetPreset.extended12,
    name: 'Extended 12',
    tileCount: 12,
    useSingleDieWhenLow: false,
  );

  static const presets = [classic9, flip10, extended12];

  final RulesetPreset preset;
  final String name;
  final int tileCount;
  final bool useSingleDieWhenLow;

  int diceCountFor(Set<int> openTiles) {
    if (useSingleDieWhenLow && openTiles.every((tile) => tile <= 6)) {
      return 1;
    }
    return 2;
  }

  static GameRuleset fromPresetName(String? name) {
    for (final ruleset in presets) {
      if (ruleset.preset.name == name) {
        return ruleset;
      }
    }
    return flip10;
  }
}

final class DiceRoll {
  const DiceRoll(this.first, [this.second])
    : assert(first >= 1 && first <= 6),
      assert(second == null || (second >= 1 && second <= 6));

  final int first;
  final int? second;

  int get total => first + (second ?? 0);
  List<int> get values => second == null ? [first] : [first, second!];
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
    required this.ruleset,
    required List<PlayerBoard> players,
    required this.activePlayerIndex,
    required this.phase,
    this.currentRoll,
    Iterable<int> selectedTiles = const [],
  }) : players = List<PlayerBoard>.unmodifiable(players),
       selectedTiles = Set<int>.unmodifiable(selectedTiles);

  factory GameSnapshot.initial({
    int playerCount = 1,
    GameRuleset ruleset = GameRuleset.flip10,
  }) {
    assert(playerCount > 0);
    assert(ruleset.tileCount > 0);

    return GameSnapshot(
      ruleset: ruleset,
      players: List<PlayerBoard>.generate(
        playerCount,
        (index) =>
            PlayerBoard.newPlayer(index: index, tileCount: ruleset.tileCount),
      ),
      activePlayerIndex: 0,
      phase: GamePhase.waitingForRoll,
    );
  }

  final GameRuleset ruleset;
  final List<PlayerBoard> players;
  final int activePlayerIndex;
  final GamePhase phase;
  final DiceRoll? currentRoll;
  final Set<int> selectedTiles;

  int get tileCount => ruleset.tileCount;
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
    GameRuleset? ruleset,
    List<PlayerBoard>? players,
    int? activePlayerIndex,
    GamePhase? phase,
    DiceRoll? currentRoll,
    bool clearRoll = false,
    Iterable<int>? selectedTiles,
  }) {
    return GameSnapshot(
      ruleset: ruleset ?? this.ruleset,
      players: players ?? this.players,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      phase: phase ?? this.phase,
      currentRoll: clearRoll ? null : currentRoll ?? this.currentRoll,
      selectedTiles: selectedTiles ?? this.selectedTiles,
    );
  }
}

final class RoundRecord {
  RoundRecord({
    required this.roundNumber,
    required Iterable<int> scores,
    required Iterable<int> winnerIndexes,
  }) : scores = List<int>.unmodifiable(scores),
       winnerIndexes = List<int>.unmodifiable(winnerIndexes);

  final int roundNumber;
  final List<int> scores;
  final List<int> winnerIndexes;

  int get bestScore => scores.reduce((a, b) => a < b ? a : b);
}

final class MatchSnapshot {
  MatchSnapshot({
    required this.playerCount,
    required this.targetRounds,
    required this.ruleset,
    required Iterable<RoundRecord> roundHistory,
  }) : roundHistory = List<RoundRecord>.unmodifiable(roundHistory);

  final int playerCount;
  final int targetRounds;
  final GameRuleset ruleset;
  final List<RoundRecord> roundHistory;

  int get completedRounds => roundHistory.length;
  int get currentRoundNumber => (completedRounds + 1).clamp(1, targetRounds);
  bool get isComplete => completedRounds >= targetRounds;

  List<int> get cumulativeScores {
    final totals = List<int>.filled(playerCount, 0);
    for (final record in roundHistory) {
      for (
        var index = 0;
        index < record.scores.length && index < playerCount;
        index++
      ) {
        totals[index] += record.scores[index];
      }
    }
    return List<int>.unmodifiable(totals);
  }

  List<int> get winnerIndexes {
    if (!isComplete || roundHistory.isEmpty) {
      return const [];
    }
    final totals = cumulativeScores;
    final best = totals.reduce((a, b) => a < b ? a : b);
    return [
      for (var index = 0; index < totals.length; index++)
        if (totals[index] == best) index,
    ];
  }
}
