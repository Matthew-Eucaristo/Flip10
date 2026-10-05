import {
  type DiceRoll,
  type PlayerBoard,
  rollTotal,
} from "./models";

export function validMoves(openTiles: ReadonlySet<number>, target: number): number[][] {
  const tiles = [...openTiles].sort((a, b) => a - b);
  const moves: number[][] = [];

  const search = (start: number, remaining: number, path: number[]) => {
    if (remaining === 0) {
      moves.push([...path]);
      return;
    }
    for (let index = start; index < tiles.length; index += 1) {
      const tile = tiles[index];
      if (tile === undefined || tile > remaining) break;
      path.push(tile);
      search(index + 1, remaining - tile, path);
      path.pop();
    }
  };

  search(0, target, []);
  moves.sort(compareMoves);
  return moves;
}

export function hasValidMove(openTiles: ReadonlySet<number>, target: number): boolean {
  return validMoves(openTiles, target).length > 0;
}

export function isValidSelection(
  openTiles: ReadonlySet<number>,
  roll: DiceRoll,
  selectedTiles: ReadonlySet<number>,
): boolean {
  if (selectedTiles.size === 0) return false;
  let selectedSum = 0;
  for (const tile of selectedTiles) {
    if (!openTiles.has(tile)) return false;
    selectedSum += tile;
  }
  return selectedSum === rollTotal(roll);
}

export function closeTiles(player: PlayerBoard, selectedTiles: ReadonlySet<number>): PlayerBoard {
  const next = new Set(player.openTiles);
  for (const tile of selectedTiles) next.delete(tile);
  return { openTiles: next };
}

function compareMoves(a: number[], b: number[]): number {
  const lengthCompare = a.length - b.length;
  if (lengthCompare !== 0) return lengthCompare;
  for (let index = 0; index < a.length; index += 1) {
    const tileCompare = (b[index] ?? 0) - (a[index] ?? 0);
    if (tileCompare !== 0) return tileCompare;
  }
  return 0;
}
