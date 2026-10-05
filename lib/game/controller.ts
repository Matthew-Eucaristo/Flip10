import {
  type DiceRoll,
  type GameSnapshot,
  type PlayerBoard,
  REROLLS_PER_ROUND,
  activePlayer,
  canReroll,
  initialBoard,
  initialSnapshot,
  remainingTotal,
  rollTotal,
  selectedTotal,
} from "./models";
import { closeTiles, hasValidMove, isValidSelection } from "./rules";

export type DiceRoller = () => DiceRoll;

export function randomRoll(): DiceRoll {
  return {
    first: Math.floor(Math.random() * 6) + 1,
    second: Math.floor(Math.random() * 6) + 1,
  };
}

/** Sole writer of GameSnapshot. UI subscribes and renders each new snapshot. */
export class GameController {
  private snapshot: GameSnapshot;
  private readonly listeners = new Set<() => void>();

  constructor(private readonly diceRoller: DiceRoller = randomRoll) {
    this.snapshot = initialSnapshot();
  }

  getSnapshot(): GameSnapshot {
    return this.snapshot;
  }

  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  newGame(): void {
    this.snapshot = initialSnapshot();
    this.emit();
  }

  nextRound(): void {
    this.snapshot = {
      ...this.snapshot,
      players: [initialBoard()],
      phase: "waitingForRoll",
      currentRoll: null,
      selectedTiles: new Set(),
      rerollsLeft: REROLLS_PER_ROUND,
    };
    this.emit();
  }

  roll(): void {
    if (this.snapshot.phase !== "waitingForRoll") return;
    this.applyRoll(this.diceRoller(), this.snapshot.rerollsLeft);
  }

  reroll(): void {
    if (!canReroll(this.snapshot)) return;
    this.applyRoll(this.diceRoller(), this.snapshot.rerollsLeft - 1);
  }

  /** Returns true when the tap changed the selection. */
  toggleTile(tile: number): boolean {
    const player = activePlayer(this.snapshot);
    if (this.snapshot.phase !== "choosingTiles" || !player.openTiles.has(tile)) {
      return false;
    }

    const selectedTiles = new Set(this.snapshot.selectedTiles);
    if (selectedTiles.has(tile)) {
      selectedTiles.delete(tile);
    } else {
      const roll = this.snapshot.currentRoll;
      if (!roll) return false;
      if (selectedTotal(this.snapshot) + tile > rollTotal(roll)) return false;
      selectedTiles.add(tile);
    }

    this.snapshot = { ...this.snapshot, selectedTiles };
    this.emit();
    return true;
  }

  selectMove(tiles: readonly number[]): void {
    const roll = this.snapshot.currentRoll;
    const selectedTiles = new Set(tiles);
    if (
      this.snapshot.phase !== "choosingTiles" ||
      !roll ||
      !isValidSelection(activePlayer(this.snapshot).openTiles, roll, selectedTiles)
    ) {
      return;
    }
    this.snapshot = { ...this.snapshot, selectedTiles };
    this.emit();
  }

  closeSelection(): void {
    const roll = this.snapshot.currentRoll;
    const player = activePlayer(this.snapshot);
    if (
      !roll ||
      !isValidSelection(player.openTiles, roll, this.snapshot.selectedTiles)
    ) {
      return;
    }

    const nextPlayer = closeTiles(player, this.snapshot.selectedTiles);
    const players = this.snapshot.players.slice();
    players[this.snapshot.activePlayerIndex] = nextPlayer;

    if (nextPlayer.openTiles.size === 0) {
      this.completeTurn(players, 0);
      return;
    }

    this.snapshot = {
      ...this.snapshot,
      players,
      phase: "waitingForRoll",
      currentRoll: null,
      selectedTiles: new Set(),
    };
    this.emit();
  }

  scoreBlockedTurn(): void {
    if (this.snapshot.phase !== "blocked") return;
    this.completeTurn(this.snapshot.players.slice(), remainingTotal(activePlayer(this.snapshot)));
  }

  private applyRoll(roll: DiceRoll, rerollsLeft: number): void {
    const legal = hasValidMove(activePlayer(this.snapshot).openTiles, rollTotal(roll));
    this.snapshot = {
      ...this.snapshot,
      currentRoll: roll,
      selectedTiles: new Set(),
      phase: legal ? "choosingTiles" : "blocked",
      rerollsLeft,
    };
    this.emit();
  }

  private completeTurn(players: PlayerBoard[], score: number): void {
    this.snapshot = {
      ...this.snapshot,
      players,
      totalScore: this.snapshot.totalScore + score,
      phase: "complete",
      currentRoll: null,
      selectedTiles: new Set(),
    };
    this.emit();
  }

  private emit(): void {
    for (const listener of this.listeners) listener();
  }
}
