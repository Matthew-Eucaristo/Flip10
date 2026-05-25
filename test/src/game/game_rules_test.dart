import 'package:flip10/src/game/game_models.dart';
import 'package:flip10/src/game/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRules', () {
    test('finds valid combinations for a rolled total', () {
      final moves = GameRules.validMoves(
        openTiles: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        target: 8,
      );

      expect(moves, contains(equals([8])));
      expect(moves, contains(equals([3, 5])));
      expect(moves, contains(equals([1, 2, 5])));
    });

    test('detects when a player has no legal move', () {
      final hasMove = GameRules.hasValidMove(openTiles: {1, 2, 3}, target: 12);

      expect(hasMove, isFalse);
    });

    test('validates selected open tiles against a dice roll', () {
      final isValid = GameRules.isValidSelection(
        openTiles: {1, 2, 3, 4, 5},
        roll: const DiceRoll(3, 5),
        selectedTiles: {3, 5},
      );

      expect(isValid, isTrue);
    });
  });
}
