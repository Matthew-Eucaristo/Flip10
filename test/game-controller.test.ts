import { describe, expect, it } from "vitest";
import { GameController } from "../lib/game/controller";
import { type DiceRoll, REROLLS_PER_ROUND, activePlayer } from "../lib/game/models";

const roll = (first: number, second: number): DiceRoll => ({ first, second });

describe("GameController", () => {
  it("closes selected tiles and waits for the next roll", () => {
    const controller = new GameController(() => roll(3, 5));
    controller.roll();
    controller.selectMove([3, 5]);
    controller.closeSelection();
    const snapshot = controller.getSnapshot();
    expect(snapshot.phase).toBe("waitingForRoll");
    expect(activePlayer(snapshot).openTiles.has(3)).toBe(false);
    expect(activePlayer(snapshot).openTiles.has(5)).toBe(false);
    expect(snapshot.currentRoll).toBeNull();
  });

  it("shows the rolled total after a roll", () => {
    const controller = new GameController(() => roll(4, 5));
    controller.roll();
    expect(controller.getSnapshot().phase).toBe("choosingTiles");
    expect(controller.getSnapshot().currentRoll).toEqual(roll(4, 5));
  });

  it("rejects invalid move presets from callers", () => {
    const controller = new GameController(() => roll(3, 5));
    controller.roll();
    let notifications = 0;
    controller.subscribe(() => {
      notifications += 1;
    });
    controller.selectMove([9]);
    expect(controller.getSnapshot().selectedTiles.size).toBe(0);
    expect(notifications).toBe(0);
    controller.selectMove([3, 5]);
    expect(controller.getSnapshot().selectedTiles).toEqual(new Set([3, 5]));
    expect(notifications).toBe(1);
  });

  it("roll of 1+1 with tile 2 closed is blocked", () => {
    const controller = new GameController(() => roll(1, 1));
    controller.roll();
    controller.selectMove([2]);
    controller.closeSelection();
    expect(activePlayer(controller.getSnapshot()).openTiles.has(2)).toBe(false);
    controller.roll();
    expect(controller.getSnapshot().phase).toBe("blocked");
    controller.scoreBlockedTurn();
    expect(controller.getSnapshot().phase).toBe("complete");
    expect(controller.getSnapshot().totalScore).toBe(53);
  });

  it("nextRound preserves the running total but resets open tiles", () => {
    const controller = new GameController(() => roll(1, 1));
    controller.roll();
    controller.selectMove([2]);
    controller.closeSelection();
    controller.nextRound();
    expect(controller.getSnapshot().phase).toBe("waitingForRoll");
    expect(activePlayer(controller.getSnapshot()).openTiles).toEqual(
      new Set([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
    );
    expect(controller.getSnapshot().totalScore).toBe(0);
  });

  it("newGame resets open tiles, total, and phase", () => {
    const controller = new GameController(() => roll(1, 1));
    controller.roll();
    controller.selectMove([2]);
    controller.closeSelection();
    controller.roll();
    controller.scoreBlockedTurn();
    controller.newGame();
    const snapshot = controller.getSnapshot();
    expect(snapshot.phase).toBe("waitingForRoll");
    expect(snapshot.totalScore).toBe(0);
    expect(activePlayer(snapshot).openTiles).toEqual(
      new Set([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
    );
  });

  it("total accumulates across multiple rounds", () => {
    const controller = new GameController(() => roll(1, 1));
    for (let round = 1; round <= 3; round += 1) {
      if (round > 1) controller.nextRound();
      controller.roll();
      controller.selectMove([2]);
      controller.closeSelection();
      controller.roll();
      controller.scoreBlockedTurn();
      expect(controller.getSnapshot().totalScore).toBe(53 * round);
    }
  });

  it("scoreBlockedTurn is a no-op when phase is not blocked", () => {
    const controller = new GameController(() => roll(1, 1));
    controller.roll();
    controller.scoreBlockedTurn();
    expect(controller.getSnapshot().phase).toBe("choosingTiles");
    expect(controller.getSnapshot().totalScore).toBe(0);
  });

  it("toggleTile reports whether the pick was accepted", () => {
    const controller = new GameController(() => roll(2, 3));
    expect(controller.toggleTile(1)).toBe(false);
    controller.roll();
    expect(controller.toggleTile(2)).toBe(true);
    expect(controller.toggleTile(4)).toBe(false);
    expect(controller.toggleTile(2)).toBe(true);
    expect(controller.getSnapshot().selectedTiles.size).toBe(0);
  });

  it("reroll spends the once-per-round reroll and clears selection", () => {
    const rolls = [roll(2, 3), roll(1, 4)];
    let index = 0;
    const controller = new GameController(() => rolls[index++ % rolls.length]!);
    controller.roll();
    controller.selectMove([2, 3]);
    controller.reroll();
    const snapshot = controller.getSnapshot();
    expect(snapshot.currentRoll).toEqual(roll(1, 4));
    expect(snapshot.selectedTiles.size).toBe(0);
    expect(snapshot.rerollsLeft).toBe(0);
    expect(snapshot.phase).toBe("choosingTiles");
  });

  it("reroll escapes a blocked roll", () => {
    const rolls = [roll(1, 1), roll(1, 1), roll(5, 6)];
    let index = 0;
    const controller = new GameController(() => rolls[index++ % rolls.length]!);
    controller.roll();
    controller.selectMove([2]);
    controller.closeSelection();
    controller.roll();
    expect(controller.getSnapshot().phase).toBe("blocked");
    controller.reroll();
    expect(controller.getSnapshot().phase).toBe("choosingTiles");
    expect(controller.getSnapshot().currentRoll).toEqual(roll(5, 6));
    expect(controller.getSnapshot().rerollsLeft).toBe(0);
  });

  it("reroll is unavailable before the first roll and after complete", () => {
    const controller = new GameController(() => roll(1, 1));
    controller.reroll();
    expect(controller.getSnapshot().currentRoll).toBeNull();
    expect(controller.getSnapshot().rerollsLeft).toBe(1);
    controller.roll();
    controller.selectMove([2]);
    controller.closeSelection();
    controller.roll();
    controller.scoreBlockedTurn();
    controller.reroll();
    expect(controller.getSnapshot().phase).toBe("complete");
  });

  it("nextRound restores the reroll", () => {
    const controller = new GameController(() => roll(1, 1));
    controller.roll();
    controller.reroll();
    controller.nextRound();
    expect(controller.getSnapshot().rerollsLeft).toBe(REROLLS_PER_ROUND);
  });
});
