import { describe, expect, it } from "vitest";
import { EMPTY_STATS, recordRound } from "../lib/stats";

describe("recordRound", () => {
  it("counts a shut box as a new best and starts a streak", () => {
    const record = recordRound(EMPTY_STATS, 0, true);
    expect(record.isNewBest).toBe(true);
    expect(record.stats).toEqual({
      rounds: 1,
      shutBoxes: 1,
      bestRound: 0,
      currentStreak: 1,
      bestStreak: 1,
    });
  });

  it("breaks the streak and keeps a better score", () => {
    const first = recordRound(EMPTY_STATS, 0, true).stats;
    const record = recordRound(first, 12, false);
    expect(record.isNewBest).toBe(false);
    expect(record.stats.currentStreak).toBe(0);
    expect(record.stats.bestStreak).toBe(1);
    expect(record.stats.bestRound).toBe(0);
    expect(record.stats.shutBoxes).toBe(1);
  });
});
