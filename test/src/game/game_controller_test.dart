import 'package:flip10/src/game/game_controller.dart';
import 'package:flip10/src/game/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController', () {
    test('closes selected tiles and waits for the next roll', () {
      final controller = GameController(diceRoller: () => const DiceRoll(3, 5));

      controller.roll();
      controller.selectMove([3, 5]);
      controller.closeSelection();

      final snapshot = controller.snapshot;
      expect(snapshot.phase, GamePhase.waitingForRoll);
      expect(snapshot.activePlayer.openTiles.contains(3), isFalse);
      expect(snapshot.activePlayer.openTiles.contains(5), isFalse);
      expect(snapshot.currentRoll, isNull);
    });

    test('shows the rolled total after a roll', () {
      final controller = GameController(diceRoller: () => const DiceRoll(4, 5));

      controller.roll();

      expect(controller.snapshot.phase, GamePhase.choosingTiles);
      expect(controller.snapshot.currentRoll?.total, 9);
    });

    test('rejects invalid move presets from callers', () {
      final controller = GameController(diceRoller: () => const DiceRoll(3, 5));

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

    test('roll of 1+1 with tile 2 closed is blocked', () {
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      // Round 1: roll 2, close tile 2 (sums to 2, valid).
      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      expect(controller.snapshot.phase, GamePhase.waitingForRoll);
      expect(controller.snapshot.activePlayer.openTiles.contains(2), isFalse);

      // Round 2: roll 2 again; tile 2 is closed, [1,1] is invalid, blocked.
      controller.roll();
      expect(controller.snapshot.phase, GamePhase.blocked);

      controller.scoreBlockedTurn();
      expect(controller.snapshot.phase, GamePhase.complete);
      // Open tiles: {1, 3, 4, 5, 6, 7, 8, 9, 10} → sum = 53
      expect(controller.snapshot.totalScore, 53);
    });

    test('nextRound preserves the running total but resets open tiles', () {
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      expect(controller.snapshot.phase, GamePhase.waitingForRoll);
      expect(controller.snapshot.totalScore, 0);

      controller.nextRound();
      expect(controller.snapshot.phase, GamePhase.waitingForRoll);
      expect(controller.snapshot.activePlayer.openTiles, {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
      });
      expect(controller.snapshot.totalScore, 0);
    });

    test('newGame resets open tiles, total, and phase', () {
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      controller.scoreBlockedTurn();
      expect(controller.snapshot.totalScore, 53);

      controller.newGame();
      expect(controller.snapshot.phase, GamePhase.waitingForRoll);
      expect(controller.snapshot.totalScore, 0);
      expect(controller.snapshot.activePlayer.openTiles, {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
      });
    });

    test('total accumulates across multiple rounds', () {
      // Sequence: round 1 (close 2, score 0), round 2 (block, score 53),
      // then nextRound and block again to add to total.
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      // Round 1
      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      controller.scoreBlockedTurn();
      expect(controller.snapshot.totalScore, 53);

      // Round 2
      controller.nextRound();
      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      controller.scoreBlockedTurn();
      expect(controller.snapshot.totalScore, 53 + 53);

      // Round 3
      controller.nextRound();
      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      controller.scoreBlockedTurn();
      expect(controller.snapshot.totalScore, 53 * 3);
    });

    test('scoreBlockedTurn is a no-op when phase is not blocked', () {
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      controller.roll();
      expect(controller.snapshot.phase, GamePhase.choosingTiles);

      controller.scoreBlockedTurn();
      expect(controller.snapshot.phase, GamePhase.choosingTiles);
      expect(controller.snapshot.totalScore, 0);
    });

    test('toggleTile reports whether the pick was accepted', () {
      final controller = GameController(
        diceRoller: () => const DiceRoll(2, 3), // total 5
      );

      // Not in choosingTiles yet.
      expect(controller.toggleTile(1), isFalse);

      controller.roll();
      expect(controller.toggleTile(2), isTrue);
      // Overshoot: 2 + 4 = 6 > 5.
      expect(controller.toggleTile(4), isFalse);
      // Deselecting is also an accepted pick.
      expect(controller.toggleTile(2), isTrue);
      expect(controller.snapshot.selectedTiles, isEmpty);
    });

    test('reroll spends the once-per-round reroll and clears selection', () {
      final rolls = [const DiceRoll(2, 3), const DiceRoll(1, 4)];
      var index = 0;
      final controller = GameController(
        diceRoller: () => rolls[index++ % rolls.length],
      );

      controller.roll();
      expect(controller.snapshot.currentRoll?.total, 5);
      expect(controller.snapshot.rerollsLeft, 1);
      expect(controller.snapshot.canReroll, isTrue);

      controller.selectMove([2, 3]);
      controller.reroll();

      expect(controller.snapshot.currentRoll?.total, 5);
      expect(controller.snapshot.selectedTiles, isEmpty);
      expect(controller.snapshot.rerollsLeft, 0);
      expect(controller.snapshot.canReroll, isFalse);
      expect(controller.snapshot.phase, GamePhase.choosingTiles);
    });

    test('reroll escapes a blocked roll', () {
      // Roll 2 → close tile 2 → roll 2 again (dead: only [2] or [1,1]
      // remain and neither is legal) → reroll lands 11.
      final rolls = [
        const DiceRoll(1, 1),
        const DiceRoll(1, 1),
        const DiceRoll(5, 6),
      ];
      var index = 0;
      final controller = GameController(
        diceRoller: () => rolls[index++ % rolls.length],
      );

      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      expect(controller.snapshot.phase, GamePhase.blocked);
      expect(controller.snapshot.canReroll, isTrue);

      controller.reroll();
      expect(controller.snapshot.phase, GamePhase.choosingTiles);
      expect(controller.snapshot.currentRoll?.total, 11);
      expect(controller.snapshot.rerollsLeft, 0);
    });

    test('reroll is unavailable before the first roll and after complete', () {
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      controller.reroll();
      expect(controller.snapshot.currentRoll, isNull);
      expect(controller.snapshot.rerollsLeft, 1);

      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      controller.scoreBlockedTurn();
      controller.reroll();
      expect(controller.snapshot.phase, GamePhase.complete);
    });

    test('nextRound restores the reroll', () {
      final controller = GameController(diceRoller: () => const DiceRoll(1, 1));

      controller.roll();
      controller.reroll();
      expect(controller.snapshot.rerollsLeft, 0);

      controller.nextRound();
      expect(controller.snapshot.rerollsLeft, kRerollsPerRound);
    });
  });
}
