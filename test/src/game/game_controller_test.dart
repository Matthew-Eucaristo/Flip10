import 'package:flip10/src/game/game_controller.dart';
import 'package:flip10/src/game/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController', () {
    test('closes selected tiles and waits for the next roll', () {
      final controller = GameController(
        diceRoller: (_) => const DiceRoll(3, 5),
      );

      controller.roll();
      controller.toggleTile(3);
      controller.toggleTile(5);
      controller.closeSelection();

      final snapshot = controller.snapshot;
      expect(snapshot.phase, GamePhase.waitingForRoll);
      expect(snapshot.activePlayer.openTiles.contains(3), isFalse);
      expect(snapshot.activePlayer.openTiles.contains(5), isFalse);
      expect(snapshot.currentRoll, isNull);
    });

    test('scores a blocked turn and advances to the next player', () {
      var rollIndex = 0;
      final rolls = [const DiceRoll(6, 6), const DiceRoll(1, 1)];
      final controller = GameController(diceRoller: (_) => rolls[rollIndex++])
        ..newRound(playerCount: 2, tileCount: 3);

      controller.roll();
      expect(controller.snapshot.phase, GamePhase.blocked);

      controller.scoreBlockedTurn();

      final snapshot = controller.snapshot;
      expect(snapshot.players.first.score, 6);
      expect(snapshot.activePlayerIndex, 1);
      expect(snapshot.phase, GamePhase.waitingForRoll);
    });

    test('finishes the round when every player has a score', () {
      final controller = GameController(diceRoller: (_) => const DiceRoll(6, 6))
        ..newRound(playerCount: 1, tileCount: 3);

      controller.roll();
      controller.scoreBlockedTurn();

      expect(controller.snapshot.phase, GamePhase.complete);
      expect(controller.snapshot.winner?.score, 6);
    });

    test('rejects invalid move presets from callers', () {
      final controller = GameController(
        diceRoller: (_) => const DiceRoll(3, 5),
      );

      controller.roll();

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectMove([9]);

      expect(controller.snapshot.selectedTiles, isEmpty);
      expect(notifications, 0);

      controller.selectMove([3, 5]);

      expect(controller.snapshot.selectedTiles, {3, 5});
      expect(notifications, 1);
    });

    test('reports shared winners when players tie', () {
      final controller = GameController(diceRoller: (_) => const DiceRoll(6, 6))
        ..newRound(playerCount: 2, tileCount: 3);

      controller.roll();
      controller.scoreBlockedTurn();
      controller.roll();
      controller.scoreBlockedTurn();

      final snapshot = controller.snapshot;
      expect(snapshot.phase, GamePhase.complete);
      expect(snapshot.winner, isNull);
      expect(snapshot.winners.map((player) => player.name), [
        'Player 1',
        'Player 2',
      ]);
      expect(snapshot.winners.map((player) => player.score), [6, 6]);
    });

    test('advances a multi-round match and reports match winners', () {
      final controller = GameController(
        diceRoller: (_) => const DiceRoll(6, 6),
        playerCount: 1,
        ruleset: const GameRuleset.custom(tileCount: 3),
        targetRounds: 2,
      );

      controller.roll();
      controller.scoreBlockedTurn();

      expect(controller.snapshot.phase, GamePhase.complete);
      expect(controller.match.completedRounds, 1);
      expect(controller.match.isComplete, isFalse);

      controller.nextRound();
      controller.roll();
      controller.scoreBlockedTurn();

      expect(controller.match.completedRounds, 2);
      expect(controller.match.isComplete, isTrue);
      expect(controller.match.cumulativeScores, [12]);
      expect(controller.match.winnerIndexes, [0]);
    });

    test('uses one die for classic rules once all open tiles are low', () {
      final diceCounts = <int>[];
      final rolls = [
        const DiceRoll(4, 5),
        const DiceRoll(4, 4),
        const DiceRoll(3, 4),
        const DiceRoll(3),
      ];
      var rollIndex = 0;
      final controller = GameController(
        diceRoller: (diceCount) {
          diceCounts.add(diceCount);
          return rolls[rollIndex++];
        },
        ruleset: GameRuleset.classic9,
      );

      controller.roll();
      controller.selectMove([9]);
      controller.closeSelection();
      controller.roll();
      controller.selectMove([8]);
      controller.closeSelection();
      controller.roll();
      controller.selectMove([7]);
      controller.closeSelection();
      controller.roll();

      expect(diceCounts, [2, 2, 2, 1]);
      expect(controller.snapshot.currentRoll?.values, [3]);
    });
  });
}
