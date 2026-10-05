import { describe, expect, it } from "vitest";
import { type DiceRoll } from "../lib/game/models";
import { hasValidMove, isValidSelection, validMoves } from "../lib/game/rules";

const allTiles = new Set([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

describe("GameRules", () => {
  it("finds valid combinations for a rolled total", () => {
    const moves = validMoves(allTiles, 8);
    expect(moves).toContainEqual([8]);
    expect(moves).toContainEqual([3, 5]);
    expect(moves).toContainEqual([1, 2, 5]);
  });

  it("detects when a player has no legal move", () => {
    expect(hasValidMove(new Set([1, 2, 3]), 12)).toBe(false);
  });

  it("validates selected open tiles against a dice roll", () => {
    const roll: DiceRoll = { first: 3, second: 5 };
    expect(isValidSelection(new Set([1, 2, 3, 4, 5]), roll, new Set([3, 5]))).toBe(true);
  });
});
