"use client";

import { useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import { GameController } from "@/lib/game/controller";
import {
  type GameSnapshot,
  TILE_COUNT,
  activePlayer,
  canReroll,
  isSelectionValid,
  remainingTotal,
  rollTotal,
  selectedTotal,
} from "@/lib/game/models";
import { validMoves } from "@/lib/game/rules";
import {
  type GameStats,
  loadHapticsOn,
  loadSoundOn,
  loadStats,
  recordRound,
  saveHapticsOn,
  saveSoundOn,
  saveStats,
} from "@/lib/stats";

type Sfx = "roll" | "flip" | "select" | "deny" | "success" | "blocked";

const AUDIO: Record<Sfx, string> = {
  roll: "/assets/audio/roll.wav",
  flip: "/assets/audio/flip.wav",
  select: "/assets/audio/select.wav",
  deny: "/assets/audio/deny.wav",
  success: "/assets/audio/success.wav",
  blocked: "/assets/audio/blocked.wav",
};

function playCue(cue: Sfx) {
  const audio = new Audio(AUDIO[cue]);
  audio.play().catch(() => undefined);
}

function vibrate(pattern: number | number[]) {
  navigator.vibrate?.(pattern);
}

function promptCopy(snapshot: GameSnapshot): { title: string; detail: string } {
  const player = activePlayer(snapshot);
  const open = remainingTotal(player);
  switch (snapshot.phase) {
    case "waitingForRoll":
      return { title: "Roll dice", detail: `You have ${open} points open.` };
    case "choosingTiles": {
      const target = snapshot.currentRoll ? rollTotal(snapshot.currentRoll) : 0;
      const selected = selectedTotal(snapshot);
      const remaining = target - selected;
      const detail =
        remaining === 0
          ? "Close the selected tiles."
          : selected === 0
            ? `Pick open tiles totaling ${target}.`
            : `${selected} selected. Need ${remaining} more.`;
      return { title: `Choose ${target}`, detail };
    }
    case "blocked":
      return {
        title: "No legal move",
        detail: canReroll(snapshot)
          ? `Score ${open} — or reroll for a fresh throw.`
          : `Score ${open} to end the round.`,
      };
    case "complete":
      return snapshot.players[snapshot.activePlayerIndex]?.openTiles.size === 0
        ? { title: "Round complete", detail: "Shut the box! Zero points." }
        : { title: "Round complete", detail: `Scored ${open}.` };
  }
}

function phaseArt(snapshot: GameSnapshot): string {
  if (snapshot.phase === "waitingForRoll") return "/assets/svg/misc/phase-dice.svg";
  if (snapshot.phase === "choosingTiles") return "/assets/svg/misc/phase-hand.svg";
  if (snapshot.phase === "blocked") return "/assets/svg/misc/phase-warning.svg";
  const score = remainingTotal(activePlayer(snapshot));
  if (score === 0) return "/assets/svg/misc/medal-gold.svg";
  if (score <= 10) return "/assets/svg/misc/medal-silver.svg";
  if (score <= 20) return "/assets/svg/misc/medal-bronze.svg";
  return "/assets/svg/misc/phase-trophy.svg";
}

function tileArt(number: number, state: "open" | "closed" | "selected" | "hinted"): string {
  if (state === "closed") return "/assets/svg/tiles/tile-closed.svg";
  return `/assets/svg/tiles/tile-${state === "open" ? "ivory" : state}-${number}.svg`;
}

export function GameScreen() {
  const controller = useMemo(() => new GameController(), []);
  const snapshot = useSyncExternalStore(
    (listener) => controller.subscribe(listener),
    () => controller.getSnapshot(),
    () => controller.getSnapshot(),
  );
  const [rolling, setRolling] = useState(false);
  const [tumble, setTumble] = useState(0);
  const [reject, setReject] = useState<{ tile: number; nonce: number } | null>(null);
  const [bursts, setBursts] = useState<number[]>([]);
  const [announce, setAnnounce] = useState("");
  const [menuOpen, setMenuOpen] = useState(false);
  const [stats, setStats] = useState<GameStats>(() => loadStats());
  const [soundOn, setSoundOn] = useState(true);
  const [hapticsOn, setHapticsOn] = useState(true);
  const [isNewBest, setIsNewBest] = useState(false);
  const [preview, setPreview] = useState<number[]>([]);
  const [shakeBoard, setShakeBoard] = useState(0);
  const [installPrompt, setInstallPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [installHidden, setInstallHidden] = useState(false);
  const rollToken = useRef(0);
  const recorded = useRef(false);

  useEffect(() => {
    setSoundOn(loadSoundOn());
    setHapticsOn(loadHapticsOn());
    setStats(loadStats());
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/sw.js").catch(() => undefined);
    }
    const onPrompt = (event: Event) => {
      event.preventDefault();
      setInstallPrompt(event as BeforeInstallPromptEvent);
    };
    window.addEventListener("beforeinstallprompt", onPrompt);
    return () => window.removeEventListener("beforeinstallprompt", onPrompt);
  }, []);

  useEffect(() => {
    if (!rolling) return;
    const timer = window.setInterval(() => setTumble((value) => value + 1), 120);
    return () => window.clearInterval(timer);
  }, [rolling]);

  const cue = (name: Sfx) => {
    if (soundOn) playCue(name);
  };
  const buzz = (pattern: number | number[]) => {
    if (hapticsOn) vibrate(pattern);
  };

  const finishRoll = (isReroll: boolean, token: number) => {
    window.setTimeout(() => {
      if (token !== rollToken.current) return;
      if (isReroll) controller.reroll();
      else controller.roll();
      setRolling(false);
      const next = controller.getSnapshot();
      if (next.phase === "blocked") setShakeBoard((value) => value + 1);
      const copy = promptCopy(next);
      setAnnounce(`${copy.title}. ${copy.detail}`);
    }, 480);
  };

  const performRoll = (isReroll: boolean) => {
    if (rolling) return;
    if (isReroll) {
      if (!canReroll(snapshot)) return;
    } else if (snapshot.phase !== "waitingForRoll") {
      return;
    }
    const token = ++rollToken.current;
    setRolling(true);
    setPreview([]);
    buzz(12);
    cue("roll");
    finishRoll(isReroll, token);
  };

  const recordIfComplete = () => {
    const next = controller.getSnapshot();
    if (next.phase !== "complete" || recorded.current) return;
    recorded.current = true;
    const shut = activePlayer(next).openTiles.size === 0;
    const score = shut ? 0 : remainingTotal(activePlayer(next));
    const record = recordRound(stats, score, shut);
    setStats(record.stats);
    setIsNewBest(record.isNewBest);
    saveStats(record.stats);
  };

  const onTile = (tile: number) => {
    const accepted = controller.toggleTile(tile);
    if (!accepted) {
      setReject((current) => ({ tile, nonce: (current?.nonce ?? 0) + 1 }));
      buzz(18);
      cue("deny");
      setAnnounce(`Cannot use ${tile} for this roll.`);
      return;
    }
    buzz(8);
    cue("select");
    setAnnounce(promptCopy(controller.getSnapshot()).detail);
  };

  const onMove = (move: number[]) => {
    controller.selectMove(move);
    buzz(8);
    cue("select");
    setAnnounce(`Selected ${move.join(" plus ")}. ${promptCopy(controller.getSnapshot()).detail}`);
  };

  const onClose = () => {
    const shut =
      activePlayer(snapshot).openTiles.size === snapshot.selectedTiles.size &&
      snapshot.selectedTiles.size > 0;
    controller.closeSelection();
    buzz(shut ? [12, 30, 20] : 16);
    cue("flip");
    if (shut) {
      cue("success");
      setBursts((current) => [...current, Date.now()]);
    }
    const next = controller.getSnapshot();
    setAnnounce(`${promptCopy(next).title}. ${promptCopy(next).detail}`);
    recordIfComplete();
  };

  const onScore = () => {
    const score = remainingTotal(activePlayer(snapshot));
    controller.scoreBlockedTurn();
    buzz(20);
    cue("blocked");
    setAnnounce(`Scored ${score}. ${promptCopy(controller.getSnapshot()).title}.`);
    recordIfComplete();
  };

  const onPlayAgain = () => {
    recorded.current = false;
    setIsNewBest(false);
    setPreview([]);
    controller.nextRound();
    setAnnounce(promptCopy(controller.getSnapshot()).title);
  };

  const onNewGame = () => {
    rollToken.current += 1;
    setRolling(false);
    recorded.current = false;
    setIsNewBest(false);
    setPreview([]);
    controller.newGame();
    buzz(8);
    setAnnounce("New game. Roll dice.");
  };

  const copy = promptCopy(snapshot);
  const moves =
    snapshot.phase === "choosingTiles" && snapshot.currentRoll
      ? validMoves(activePlayer(snapshot).openTiles, rollTotal(snapshot.currentRoll))
      : [];
  const usableReroll = canReroll(snapshot) && !rolling;

  return (
    <main className="shell">
      <p className="live" aria-live="polite">
        {announce}
      </p>
      <div className="stage">
        <header className="brand">
          <img src="/assets/svg/misc/brand-mark.svg" alt="" width={42} height={42} />
          <div>
            <h1>Flip10</h1>
            <p>Shut the box</p>
          </div>
        </header>

        <section className={`board ${shakeBoard ? "shake" : ""}`} key={shakeBoard || "board"}>
          <img className="wood" src="/assets/svg/board/wood-frame.svg" alt="" />
          <div className="felt">
            <img className="felt-art" src="/assets/svg/board/felt.svg" alt="" />
            <div className="felt-content">
              <div className="band">
                <span className="player-mark" />
                <strong>Player {snapshot.activePlayerIndex + 1}</strong>
                <ScoreReadout snapshot={snapshot} />
                <button type="button" className="icon-btn" aria-label="Settings and stats" onClick={() => setMenuOpen(true)}>
                  <GearIcon />
                </button>
                <button type="button" className="icon-btn" aria-label="New game" onClick={onNewGame}>
                  <RefreshIcon />
                </button>
              </div>

              <div className="dice-row">
                <Dice roll={snapshot.currentRoll} rolling={rolling} tumble={tumble} />
                <button
                  type="button"
                  className={`reroll ${usableReroll ? "ready" : ""}`}
                  disabled={!usableReroll}
                  onClick={() => performRoll(true)}
                  aria-label={snapshot.rerollsLeft > 0 ? `Reroll dice, ${snapshot.rerollsLeft} left` : "No rerolls left"}
                >
                  REROLL ×{snapshot.rerollsLeft}
                </button>
              </div>

              <div className="prompt">
                <img src={phaseArt(snapshot)} alt="" width={42} height={42} />
                <div>
                  <h2>
                    {copy.title}
                    {isNewBest && snapshot.phase === "complete" ? <span className="best">NEW BEST</span> : null}
                  </h2>
                  <p>{copy.detail}</p>
                </div>
              </div>

              <div className="rack" role="group" aria-label="Number tiles">
                {Array.from({ length: TILE_COUNT }, (_, index) => index + 1).map((number) => {
                  const open = activePlayer(snapshot).openTiles.has(number);
                  const selected = snapshot.selectedTiles.has(number);
                  const hinted = preview.includes(number);
                  const state = !open ? "closed" : selected ? "selected" : hinted ? "hinted" : "open";
                  const rejected = reject?.tile === number ? reject.nonce : 0;
                  return (
                    <button
                      key={`${number}-${rejected}`}
                      type="button"
                      className={`tile ${state} ${rejected ? "deny" : ""}`}
                      style={{ animationDelay: `${(number - 1) * 40}ms`, transitionDelay: `${(number - 1) * 40}ms` }}
                      data-reject={rejected}
                      aria-pressed={selected}
                      aria-label={`Tile ${number}${open ? "" : ", closed"}`}
                      onClick={() => onTile(number)}
                    >
                      <img src={tileArt(number, state)} alt="" />
                    </button>
                  );
                })}
              </div>

              {moves.length > 0 ? (
                <div className="hints">
                  <p>{moves.length === 1 ? "1 possible move" : `${moves.length} possible moves`}</p>
                  <div className="hint-row">
                    {moves.map((move) => (
                      <button
                        key={move.join("-")}
                        type="button"
                        className="hint"
                        aria-label={`Select move ${move.join(" plus ")}`}
                        onMouseEnter={() => setPreview(move)}
                        onMouseLeave={() => setPreview([])}
                        onFocus={() => setPreview(move)}
                        onBlur={() => setPreview([])}
                        onClick={() => onMove(move)}
                      >
                        {move.join(" + ")}
                      </button>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="hint-spacer" />
              )}
            </div>
            {["tl", "tr", "bl", "br"].map((corner) => (
              <img key={corner} className={`corner ${corner}`} src="/assets/svg/board/corner.svg" alt="" />
            ))}
            {bursts.map((id) => (
              <Burst key={id} onDone={() => setBursts((current) => current.filter((item) => item !== id))} />
            ))}
          </div>
        </section>

        <Actions
          snapshot={snapshot}
          rolling={rolling}
          onRoll={() => performRoll(false)}
          onClose={onClose}
          onScore={onScore}
          onPlayAgain={onPlayAgain}
        />
      </div>

      {menuOpen ? (
        <Menu
          stats={stats}
          soundOn={soundOn}
          hapticsOn={hapticsOn}
          onSound={(value) => {
            setSoundOn(value);
            saveSoundOn(value);
          }}
          onHaptics={(value) => {
            setHapticsOn(value);
            saveHapticsOn(value);
          }}
          onClose={() => setMenuOpen(false)}
        />
      ) : null}

      {installPrompt && !installHidden ? (
        <aside className="install">
          <div>
            <strong>Install Flip10</strong>
            <p>Add to your home screen for offline play.</p>
          </div>
          <button
            type="button"
            onClick={() => {
              void installPrompt.prompt();
              setInstallHidden(true);
            }}
          >
            Install
          </button>
          <button type="button" aria-label="Dismiss" onClick={() => setInstallHidden(true)}>
            ×
          </button>
        </aside>
      ) : null}
    </main>
  );
}

function ScoreReadout({ snapshot }: { snapshot: GameSnapshot }) {
  const complete = snapshot.phase === "complete";
  const value = complete ? snapshot.totalScore : remainingTotal(activePlayer(snapshot));
  const previous = useRef(value);
  const [fly, setFly] = useState<number | null>(null);
  useEffect(() => {
    const delta = value - previous.current;
    previous.current = value;
    if (delta > 0) {
      setFly(delta);
      const timer = window.setTimeout(() => setFly(null), 900);
      return () => window.clearTimeout(timer);
    }
    return undefined;
  }, [value]);
  return (
    <div className="score">
      <span>{complete ? "TOTAL" : "OPEN"}</span>
      <strong>{value}</strong>
      {fly ? <em className="fly">+{fly}</em> : null}
    </div>
  );
}

function Dice({
  roll,
  rolling,
  tumble,
}: {
  roll: GameSnapshot["currentRoll"];
  rolling: boolean;
  tumble: number;
}) {
  const faces = rolling
    ? [tumble % 2 === 0 ? "tumble-1" : "tumble-2", tumble % 2 === 0 ? "tumble-2" : "tumble-1"]
    : roll
      ? [`face-${roll.first}`, `face-${roll.second}`]
      : ["face-blank", "face-blank"];
  const label = rolling ? "Rolling dice" : roll ? `Rolled ${rollTotal(roll)}` : "Dice not rolled";
  return (
    <div className="dice" aria-label={label}>
      {faces.map((face, index) => (
        <img key={`${index}-${face}`} src={`/assets/svg/dice/${face}.svg`} alt="" />
      ))}
      {roll && !rolling ? <strong>{rollTotal(roll)}</strong> : null}
    </div>
  );
}

function Actions({
  snapshot,
  rolling,
  onRoll,
  onClose,
  onScore,
  onPlayAgain,
}: {
  snapshot: GameSnapshot;
  rolling: boolean;
  onRoll: () => void;
  onClose: () => void;
  onScore: () => void;
  onPlayAgain: () => void;
}) {
  const selected = selectedTotal(snapshot);
  const target = snapshot.currentRoll ? rollTotal(snapshot.currentRoll) : 0;
  const remaining = target - selected;
  const canClose = snapshot.phase === "choosingTiles" && isSelectionValid(snapshot);
  if (snapshot.phase === "choosingTiles") {
    return (
      <div className="actions two">
        <button type="button" className="btn brass" disabled>
          {rolling ? "Rolling..." : "Roll dice"}
        </button>
        <button type="button" className={`btn ${canClose ? "accent" : "ghost"}`} disabled={!canClose} onClick={onClose}>
          {canClose ? `Close ${selected}` : selected === 0 ? "Select tiles" : `Need ${remaining}`}
        </button>
      </div>
    );
  }
  if (snapshot.phase === "blocked") {
    return (
      <div className="actions">
        <button type="button" className="btn warn" onClick={onScore}>
          Score {remainingTotal(activePlayer(snapshot))}
        </button>
      </div>
    );
  }
  if (snapshot.phase === "complete") {
    return (
      <div className="actions">
        <button type="button" className="btn brass" onClick={onPlayAgain}>
          Play again
        </button>
      </div>
    );
  }
  return (
    <div className="actions">
      <button type="button" className="btn brass" disabled={rolling} onClick={onRoll}>
        {rolling ? "Rolling..." : "Roll dice"}
      </button>
    </div>
  );
}

function Menu({
  stats,
  soundOn,
  hapticsOn,
  onSound,
  onHaptics,
  onClose,
}: {
  stats: GameStats;
  soundOn: boolean;
  hapticsOn: boolean;
  onSound: (value: boolean) => void;
  onHaptics: (value: boolean) => void;
  onClose: () => void;
}) {
  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <section className="sheet" role="dialog" aria-label="Records and settings" onClick={(event) => event.stopPropagation()}>
        <h2>Records</h2>
        <div className="stats">
          <Stat label="BEST ROUND" value={stats.bestRound === null ? "—" : String(stats.bestRound)} />
          <Stat label="SHUT BOXES" value={String(stats.shutBoxes)} />
          <Stat label="SHUT STREAK" value={String(stats.currentStreak)} />
          <Stat label="ROUNDS" value={String(stats.rounds)} />
        </div>
        <h2>Settings</h2>
        <label className="toggle">
          <span>Sound effects</span>
          <input type="checkbox" checked={soundOn} onChange={(event) => onSound(event.target.checked)} />
        </label>
        <label className="toggle">
          <span>Haptics</span>
          <input type="checkbox" checked={hapticsOn} onChange={(event) => onHaptics(event.target.checked)} />
        </label>
        <h2>How to play</h2>
        <ul>
          <li>Roll the dice, then close any open tiles whose numbers sum to the roll — one tile or a combo.</li>
          <li>No legal move? The remaining open tiles are added to your total. Low score wins.</li>
          <li>Close all 10 tiles in one round to shut the box: zero points.</li>
          <li>Stuck? Once per round, REROLL throws fresh dice — even on a dead roll.</li>
        </ul>
        <button type="button" className="btn brass" onClick={onClose}>
          Close
        </button>
      </section>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="stat">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function Burst({ onDone }: { onDone: () => void }) {
  useEffect(() => {
    const timer = window.setTimeout(onDone, 1200);
    return () => window.clearTimeout(timer);
  }, [onDone]);
  const bits = useMemo(
    () =>
      Array.from({ length: 24 }, (_, index) => ({
        left: 8 + ((index * 37) % 84),
        delay: (index % 6) * 0.04,
        color: ["#d7a941", "#f4e3bd", "#76d7a6", "#e56e4f", "#4fa3ff"][index % 5],
      })),
    [],
  );
  return (
    <div className="burst" aria-hidden="true">
      {bits.map((bit, index) => (
        <i key={index} style={{ left: `${bit.left}%`, animationDelay: `${bit.delay}s`, background: bit.color }} />
      ))}
    </div>
  );
}

function GearIcon() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
      <path
        fill="currentColor"
        d="M19.4 13a7.8 7.8 0 0 0 .1-1 7.8 7.8 0 0 0-.1-1l2.1-1.6a.5.5 0 0 0 .1-.6l-2-3.4a.5.5 0 0 0-.6-.2l-2.5 1a7.3 7.3 0 0 0-1.7-1l-.4-2.6a.5.5 0 0 0-.5-.4h-4a.5.5 0 0 0-.5.4l-.4 2.6a7.3 7.3 0 0 0-1.7 1l-2.5-1a.5.5 0 0 0-.6.2l-2 3.4a.5.5 0 0 0 .1.6L4.6 11a7.8 7.8 0 0 0 0 2l-2.1 1.6a.5.5 0 0 0-.1.6l2 3.4a.5.5 0 0 0 .6.2l2.5-1a7.3 7.3 0 0 0 1.7 1l.4 2.6a.5.5 0 0 0 .5.4h4a.5.5 0 0 0 .5-.4l.4-2.6a7.3 7.3 0 0 0 1.7-1l2.5 1a.5.5 0 0 0 .6-.2l2-3.4a.5.5 0 0 0-.1-.6L19.4 13zM12 15.5A3.5 3.5 0 1 1 12 8.5a3.5 3.5 0 0 1 0 7z"
      />
    </svg>
  );
}

function RefreshIcon() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
      <path
        fill="currentColor"
        d="M17.6 6.4A8 8 0 1 0 20 12h-2a6 6 0 1 1-1.8-4.2L13 11h7V4l-2.4 2.4z"
      />
    </svg>
  );
}

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
};
