import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_models.dart';
import 'game_rules.dart';

typedef DiceRoller = DiceRoll Function();

/// Sole writer of [GameSnapshot]. UI listens via [ChangeNotifier] and
/// treats each new snapshot as the rendering source of truth.
final class GameController extends ChangeNotifier {
  GameController({DiceRoller? diceRoller})
    : _diceRoller = diceRoller ?? _randomRoll,
      _snapshot = GameSnapshot.initial();

  final DiceRoller _diceRoller;
  GameSnapshot _snapshot;
  static final Random _random = Random();

  GameSnapshot get snapshot => _snapshot;

  /// Reset the session: open tiles, total score, phase. Bound to the
  /// header "New game" button.
  void newGame() {
    _snapshot = GameSnapshot.initial();
    notifyListeners();
  }

  /// Start the next round with fresh open tiles, keeping the
  /// [GameSnapshot.totalScore] running total. Bound to the "Play again"
  /// button shown after a round completes.
  void nextRound() {
    _snapshot = _snapshot.copyWith(
      players: [PlayerBoard.initial()],
      phase: GamePhase.waitingForRoll,
      clearRoll: true,
      selectedTiles: const <int>{},
      rerollsLeft: kRerollsPerRound,
    );
    notifyListeners();
  }

  void roll() {
    if (_snapshot.phase != GamePhase.waitingForRoll) {
      return;
    }

    final roll = _diceRoller();
    final hasMove = GameRules.hasValidMove(
      openTiles: _snapshot.activePlayer.openTiles,
      target: roll.total,
    );

    _snapshot = _snapshot.copyWith(
      currentRoll: roll,
      selectedTiles: const <int>{},
      phase: hasMove ? GamePhase.choosingTiles : GamePhase.blocked,
    );
    notifyListeners();
  }

  /// Spend this round's reroll: toss fresh dice while choosing tiles or
  /// when blocked. A rerolled dead roll may still land blocked again —
  /// the reroll is spent either way.
  void reroll() {
    if (!_snapshot.canReroll) {
      return;
    }

    final roll = _diceRoller();
    final hasMove = GameRules.hasValidMove(
      openTiles: _snapshot.activePlayer.openTiles,
      target: roll.total,
    );

    _snapshot = _snapshot.copyWith(
      currentRoll: roll,
      selectedTiles: const <int>{},
      phase: hasMove ? GamePhase.choosingTiles : GamePhase.blocked,
      rerollsLeft: _snapshot.rerollsLeft - 1,
    );
    notifyListeners();
  }

  /// Returns true when the tap changed the selection; false when the
  /// tile could not be picked (closed, or would overshoot the roll) so
  /// the UI can play rejection feedback.
  bool toggleTile(int tile) {
    if (_snapshot.phase != GamePhase.choosingTiles ||
        !_snapshot.activePlayer.openTiles.contains(tile)) {
      return false;
    }

    final selectedTiles = Set<int>.of(_snapshot.selectedTiles);
    if (selectedTiles.contains(tile)) {
      selectedTiles.remove(tile);
    } else {
      final nextTotal = _snapshot.selectedTotal + tile;
      if (nextTotal > _snapshot.currentRoll!.total) {
        return false;
      }
      selectedTiles.add(tile);
    }

    _snapshot = _snapshot.copyWith(selectedTiles: selectedTiles);
    notifyListeners();
    return true;
  }

  void selectMove(List<int> tiles) {
    final roll = _snapshot.currentRoll;
    final selectedTiles = Set<int>.of(tiles);

    if (_snapshot.phase != GamePhase.choosingTiles ||
        roll == null ||
        !GameRules.isValidSelection(
          openTiles: _snapshot.activePlayer.openTiles,
          roll: roll,
          selectedTiles: selectedTiles,
        )) {
      return;
    }

    _snapshot = _snapshot.copyWith(selectedTiles: selectedTiles);
    notifyListeners();
  }

  void closeSelection() {
    final roll = _snapshot.currentRoll;
    if (roll == null ||
        !GameRules.isValidSelection(
          openTiles: _snapshot.activePlayer.openTiles,
          roll: roll,
          selectedTiles: _snapshot.selectedTiles,
        )) {
      return;
    }

    final activePlayer = GameRules.closeTiles(
      player: _snapshot.activePlayer,
      selectedTiles: _snapshot.selectedTiles,
    );
    final players = _snapshot.players.toList();
    players[_snapshot.activePlayerIndex] = activePlayer;

    if (activePlayer.isShut) {
      _completeTurn(players, score: 0);
      return;
    }

    _snapshot = _snapshot.copyWith(
      players: players,
      phase: GamePhase.waitingForRoll,
      clearRoll: true,
      selectedTiles: const <int>{},
    );
    notifyListeners();
  }

  void scoreBlockedTurn() {
    if (_snapshot.phase != GamePhase.blocked) {
      return;
    }

    _completeTurn(_snapshot.players.toList(), score: _snapshot.remainingTotal);
  }

  void _completeTurn(List<PlayerBoard> players, {required int score}) {
    _snapshot = _snapshot.copyWith(
      players: players,
      totalScore: _snapshot.totalScore + score,
      phase: GamePhase.complete,
      clearRoll: true,
      selectedTiles: const <int>{},
    );
    notifyListeners();
  }

  static DiceRoll _randomRoll() =>
      DiceRoll(_random.nextInt(6) + 1, _random.nextInt(6) + 1);
}
