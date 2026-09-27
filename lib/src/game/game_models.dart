/// Standard Flip10 rules: 10 tiles, 2 dice. These constants are the
/// single source of truth for the board size and dice count; tweaking
/// the game (e.g. for variants) is a one-line change here.
const int kTileCount = 10;
const int kDiceCount = 2;

/// Rerolls granted each round. A reroll tosses fresh dice while choosing
/// tiles or when blocked — the only escape from a dead roll.
const int kRerollsPerRound = 1;

enum GamePhase { waitingForRoll, choosingTiles, blocked, complete }

final class DiceRoll {
  const DiceRoll(this.first, this.second)
    : assert(first >= 1 && first <= 6),
      assert(second >= 1 && second <= 6);

  final int first;
  final int second;
  int get total => first + second;
}

/// Per-player state. The single-player game has exactly one
/// [PlayerBoard] in [GameSnapshot.players], but the model is shaped
/// so that adding a multiplayer pass-and-play mode later is purely a
/// controller change (length of the list + UI for who is active).
final class PlayerBoard {
  PlayerBoard({required Iterable<int> openTiles})
    : openTiles = Set<int>.unmodifiable(openTiles);

  factory PlayerBoard.initial() =>
      PlayerBoard(openTiles: List<int>.generate(kTileCount, (i) => i + 1));

  final Set<int> openTiles;

  int get remainingTotal => openTiles.fold(0, (sum, tile) => sum + tile);
  bool get isShut => openTiles.isEmpty;

  PlayerBoard copyWith({Iterable<int>? openTiles}) {
    return PlayerBoard(openTiles: openTiles ?? this.openTiles);
  }
}

/// The single immutable state object the UI renders. Anything that
/// changes during play (open tiles, current roll, phase, selection,
/// running total) is on this object; [GameController] is the only
/// thing that produces new instances.
final class GameSnapshot {
  GameSnapshot({
    required List<PlayerBoard> players,
    required this.activePlayerIndex,
    required this.phase,
    this.currentRoll,
    Iterable<int> selectedTiles = const [],
    this.totalScore = 0,
    this.rerollsLeft = kRerollsPerRound,
  }) : players = List<PlayerBoard>.unmodifiable(players),
       selectedTiles = Set<int>.unmodifiable(selectedTiles);

  factory GameSnapshot.initial() => GameSnapshot(
    players: [PlayerBoard.initial()],
    activePlayerIndex: 0,
    phase: GamePhase.waitingForRoll,
  );

  final List<PlayerBoard> players;
  final int activePlayerIndex;
  final GamePhase phase;
  final DiceRoll? currentRoll;
  final Set<int> selectedTiles;

  /// Cumulative points scored across all completed rounds in this
  /// session. Reset by [GameController.newGame]; preserved by
  /// [GameController.nextRound].
  final int totalScore;

  /// Rerolls remaining this round. Spent by [GameController.reroll].
  final int rerollsLeft;

  PlayerBoard get activePlayer => players[activePlayerIndex];

  /// True while a reroll could still change the outcome of this round.
  bool get canReroll =>
      rerollsLeft > 0 &&
      (phase == GamePhase.choosingTiles || phase == GamePhase.blocked);

  int get remainingTotal => activePlayer.remainingTotal;
  int get selectedTotal => selectedTiles.fold(0, (sum, tile) => sum + tile);
  bool get isSelectionValid => selectedTotal == currentRoll?.total;
  bool get isShut => activePlayer.isShut;

  GameSnapshot copyWith({
    List<PlayerBoard>? players,
    int? activePlayerIndex,
    GamePhase? phase,
    DiceRoll? currentRoll,
    bool clearRoll = false,
    Iterable<int>? selectedTiles,
    int? totalScore,
    int? rerollsLeft,
  }) {
    return GameSnapshot(
      players: players ?? this.players,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      phase: phase ?? this.phase,
      currentRoll: clearRoll ? null : currentRoll ?? this.currentRoll,
      selectedTiles: selectedTiles ?? this.selectedTiles,
      totalScore: totalScore ?? this.totalScore,
      rerollsLeft: rerollsLeft ?? this.rerollsLeft,
    );
  }
}
