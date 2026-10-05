/** Standard Flip10 rules: 10 tiles, 2 dice. */
export const TILE_COUNT = 10;
export const DICE_COUNT = 2;

/** Rerolls granted each round. */
export const REROLLS_PER_ROUND = 1;

export type GamePhase =
  | "waitingForRoll"
  | "choosingTiles"
  | "blocked"
  | "complete";

export type DiceRoll = {
  readonly first: number;
  readonly second: number;
};

export function rollTotal(roll: DiceRoll): number {
  return roll.first + roll.second;
}

export type PlayerBoard = {
  readonly openTiles: ReadonlySet<number>;
};

export function initialBoard(): PlayerBoard {
  return {
    openTiles: new Set(
      Array.from({ length: TILE_COUNT }, (_, index) => index + 1),
    ),
  };
}

export function remainingTotal(board: PlayerBoard): number {
  let sum = 0;
  for (const tile of board.openTiles) sum += tile;
  return sum;
}

export function isShut(board: PlayerBoard): boolean {
  return board.openTiles.size === 0;
}

export type GameSnapshot = {
  readonly players: readonly PlayerBoard[];
  readonly activePlayerIndex: number;
  readonly phase: GamePhase;
  readonly currentRoll: DiceRoll | null;
  readonly selectedTiles: ReadonlySet<number>;
  readonly totalScore: number;
  readonly rerollsLeft: number;
};

export function initialSnapshot(): GameSnapshot {
  return {
    players: [initialBoard()],
    activePlayerIndex: 0,
    phase: "waitingForRoll",
    currentRoll: null,
    selectedTiles: new Set(),
    totalScore: 0,
    rerollsLeft: REROLLS_PER_ROUND,
  };
}

export function activePlayer(snapshot: GameSnapshot): PlayerBoard {
  const player = snapshot.players[snapshot.activePlayerIndex];
  if (!player) throw new Error("No active player");
  return player;
}

export function selectedTotal(snapshot: GameSnapshot): number {
  let sum = 0;
  for (const tile of snapshot.selectedTiles) sum += tile;
  return sum;
}

export function canReroll(snapshot: GameSnapshot): boolean {
  return (
    snapshot.rerollsLeft > 0 &&
    (snapshot.phase === "choosingTiles" || snapshot.phase === "blocked")
  );
}

export function isSelectionValid(snapshot: GameSnapshot): boolean {
  const roll = snapshot.currentRoll;
  if (!roll) return false;
  return selectedTotal(snapshot) === rollTotal(roll);
}
