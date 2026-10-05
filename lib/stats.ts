export type GameStats = {
  rounds: number;
  shutBoxes: number;
  bestRound: number | null;
  currentStreak: number;
  bestStreak: number;
};

export type StatsRecord = {
  stats: GameStats;
  isNewBest: boolean;
};

export const EMPTY_STATS: GameStats = {
  rounds: 0,
  shutBoxes: 0,
  bestRound: null,
  currentStreak: 0,
  bestStreak: 0,
};

const KEYS = {
  rounds: "stats.rounds",
  shutBoxes: "stats.shutBoxes",
  bestRound: "stats.bestRound",
  streak: "stats.streak",
  bestStreak: "stats.bestStreak",
  sound: "settings.sound",
  haptics: "settings.haptics",
} as const;

export function recordRound(previous: GameStats, score: number, isShut: boolean): StatsRecord {
  const streak = isShut ? previous.currentStreak + 1 : 0;
  const isNewBest = previous.bestRound === null || score < previous.bestRound;
  const stats: GameStats = {
    rounds: previous.rounds + 1,
    shutBoxes: previous.shutBoxes + (isShut ? 1 : 0),
    bestRound: isNewBest ? score : previous.bestRound,
    currentStreak: streak,
    bestStreak: Math.max(previous.bestStreak, streak),
  };
  return { stats, isNewBest };
}

function storage(): Storage | null {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

function readInt(store: Storage, key: string): number | null {
  const raw = store.getItem(key);
  if (raw === null) return null;
  const value = Number(raw);
  return Number.isFinite(value) ? value : null;
}

export function loadStats(): GameStats {
  const store = storage();
  if (!store) return EMPTY_STATS;
  const best = readInt(store, KEYS.bestRound);
  return {
    rounds: readInt(store, KEYS.rounds) ?? 0,
    shutBoxes: readInt(store, KEYS.shutBoxes) ?? 0,
    bestRound: store.getItem(KEYS.bestRound) === null ? null : best,
    currentStreak: readInt(store, KEYS.streak) ?? 0,
    bestStreak: readInt(store, KEYS.bestStreak) ?? 0,
  };
}

export function saveStats(stats: GameStats): void {
  const store = storage();
  if (!store || stats.bestRound === null) return;
  store.setItem(KEYS.rounds, String(stats.rounds));
  store.setItem(KEYS.shutBoxes, String(stats.shutBoxes));
  store.setItem(KEYS.bestRound, String(stats.bestRound));
  store.setItem(KEYS.streak, String(stats.currentStreak));
  store.setItem(KEYS.bestStreak, String(stats.bestStreak));
}

export function loadSoundOn(): boolean {
  const store = storage();
  if (!store || store.getItem(KEYS.sound) === null) return true;
  return store.getItem(KEYS.sound) === "true";
}

export function loadHapticsOn(): boolean {
  const store = storage();
  if (!store || store.getItem(KEYS.haptics) === null) return true;
  return store.getItem(KEYS.haptics) === "true";
}

export function saveSoundOn(value: boolean): void {
  storage()?.setItem(KEYS.sound, String(value));
}

export function saveHapticsOn(value: boolean): void {
  storage()?.setItem(KEYS.haptics, String(value));
}
