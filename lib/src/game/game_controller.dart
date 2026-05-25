import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_models.dart';
import 'game_rules.dart';

typedef DiceRoller = DiceRoll Function();

final class GameController extends ChangeNotifier {
  GameController({DiceRoller? diceRoller})
    : _diceRoller = diceRoller ?? _randomRoll,
      _snapshot = GameSnapshot.initial();

  final DiceRoller _diceRoller;
  GameSnapshot _snapshot;
  static final Random _random = Random();

  GameSnapshot get snapshot => _snapshot;

  void newRound({int? playerCount, int? tileCount}) {
    _snapshot = GameSnapshot.initial(
      playerCount: playerCount ?? _snapshot.players.length,
      tileCount: tileCount ?? _snapshot.tileCount,
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

  void toggleTile(int tile) {
    if (_snapshot.phase != GamePhase.choosingTiles ||
        !_snapshot.activePlayer.openTiles.contains(tile)) {
      return;
    }

    final selectedTiles = Set<int>.of(_snapshot.selectedTiles);
    if (selectedTiles.contains(tile)) {
      selectedTiles.remove(tile);
    } else {
      final nextTotal = _snapshot.selectedTotal + tile;
      if (nextTotal > _snapshot.currentRoll!.total) {
        return;
      }
      selectedTiles.add(tile);
    }

    _snapshot = _snapshot.copyWith(selectedTiles: selectedTiles);
    notifyListeners();
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

    final players = _snapshot.players.toList();
    final activePlayer = GameRules.closeTiles(
      player: _snapshot.activePlayer,
      selectedTiles: _snapshot.selectedTiles,
    );
    players[_snapshot.activePlayerIndex] = activePlayer;

    if (activePlayer.openTiles.isEmpty) {
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

    _completeTurn(
      _snapshot.players.toList(),
      score: _snapshot.activePlayer.remainingTotal,
    );
  }

  void _completeTurn(List<PlayerBoard> players, {required int score}) {
    final activePlayer = players[_snapshot.activePlayerIndex];
    players[_snapshot.activePlayerIndex] = activePlayer.copyWith(
      openTiles: activePlayer.openTiles,
      score: score,
    );

    final nextPlayerIndex = players.indexWhere((player) => !player.isComplete);
    final isRoundComplete = nextPlayerIndex == -1;

    _snapshot = _snapshot.copyWith(
      players: players,
      activePlayerIndex: isRoundComplete
          ? _snapshot.activePlayerIndex
          : nextPlayerIndex,
      phase: isRoundComplete ? GamePhase.complete : GamePhase.waitingForRoll,
      clearRoll: true,
      selectedTiles: const <int>{},
    );
    notifyListeners();
  }

  static DiceRoll _randomRoll() {
    return DiceRoll(_random.nextInt(6) + 1, _random.nextInt(6) + 1);
  }
}
