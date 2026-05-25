import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_models.dart';
import 'game_rules.dart';

typedef DiceRoller = DiceRoll Function(int diceCount);

final class GameController extends ChangeNotifier {
  GameController({
    DiceRoller? diceRoller,
    int playerCount = 1,
    GameRuleset ruleset = GameRuleset.flip10,
    int targetRounds = 3,
  }) : _diceRoller = diceRoller ?? _randomRoll,
       _playerCount = playerCount,
       _ruleset = ruleset,
       _targetRounds = targetRounds,
       _snapshot = GameSnapshot.initial(
         playerCount: playerCount,
         ruleset: ruleset,
       );

  final DiceRoller _diceRoller;
  GameSnapshot _snapshot;
  int _playerCount;
  GameRuleset _ruleset;
  int _targetRounds;
  final List<RoundRecord> _roundHistory = [];
  static final Random _random = Random();

  GameSnapshot get snapshot => _snapshot;
  MatchSnapshot get match => MatchSnapshot(
    playerCount: _playerCount,
    targetRounds: _targetRounds,
    ruleset: _ruleset,
    roundHistory: _roundHistory,
  );

  void newMatch({int? playerCount, GameRuleset? ruleset, int? targetRounds}) {
    _playerCount = playerCount ?? _playerCount;
    _ruleset = ruleset ?? _ruleset;
    _targetRounds = targetRounds ?? _targetRounds;
    _roundHistory.clear();
    _snapshot = GameSnapshot.initial(
      playerCount: _playerCount,
      ruleset: _ruleset,
    );
    notifyListeners();
  }

  void newRound({int? playerCount, int? tileCount}) {
    newMatch(
      playerCount: playerCount,
      ruleset: tileCount == null
          ? null
          : GameRuleset.custom(tileCount: tileCount),
    );
  }

  void nextRound() {
    if (_snapshot.phase != GamePhase.complete || match.isComplete) {
      return;
    }

    _snapshot = GameSnapshot.initial(
      playerCount: _playerCount,
      ruleset: _ruleset,
    );
    notifyListeners();
  }

  void roll() {
    if (_snapshot.phase != GamePhase.waitingForRoll || match.isComplete) {
      return;
    }

    final diceCount = _ruleset.diceCountFor(_snapshot.activePlayer.openTiles);
    final roll = _diceRoller(diceCount);
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

    if (isRoundComplete) {
      _recordRound(players);
    }

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

  void _recordRound(List<PlayerBoard> players) {
    final scores = [
      for (final player in players) player.score ?? player.remainingTotal,
    ];
    final bestScore = scores.reduce((a, b) => a < b ? a : b);
    final winnerIndexes = [
      for (var index = 0; index < scores.length; index++)
        if (scores[index] == bestScore) index,
    ];
    _roundHistory.add(
      RoundRecord(
        roundNumber: _roundHistory.length + 1,
        scores: scores,
        winnerIndexes: winnerIndexes,
      ),
    );
  }

  static DiceRoll _randomRoll(int diceCount) {
    if (diceCount == 1) {
      return DiceRoll(_random.nextInt(6) + 1);
    }
    return DiceRoll(_random.nextInt(6) + 1, _random.nextInt(6) + 1);
  }
}
