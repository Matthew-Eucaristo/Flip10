# Flip10

A focused offline Shut the Box dice game. One player, ten tiles, two dice,
unlimited rounds. The board uses the original hand-drawn SVG art and
procedural audio. Records, sound, and haptics stay in the browser.

## Gameplay

- Roll two dice, then close any combination of open tiles whose digits sum to
  the roll.
- If no legal combination exists, the round is blocked and the sum of the
  remaining open tiles is added to the running total.
- Close every tile in one round to shut the box. That round scores zero.
- Once per round, **REROLL** throws fresh dice, including on a dead roll.
- **Play again** starts the next round and keeps the total. **New game**
  resets it.

## Stack

- Next.js App Router, statically exported so Cloudflare Pages can publish the
  `out` directory
- React 19 client UI
- Pure TypeScript rules in `lib/game`, covered by Vitest
- `localStorage` for lifetime stats and settings
- Web Audio via `HTMLAudioElement`, and `navigator.vibrate` for haptics
- Installable PWA (`public/manifest.webmanifest` and `public/sw.js`)

There is no server. A push to `main` can build this with:

| Cloudflare Pages field | Value |
| --- | --- |
| Root directory | `/` |
| Build command | `npm run build` |
| Build output directory | `out` |

## Commands

```sh
npm install
npm test
npm run dev
npm run build
```

## Art pipeline

`assets/svg` and `assets/audio` are the source art. The site serves copies
from `public/assets`. Regenerate icons into `public/` with:

```sh
python3 -m venv .venv
.venv/bin/pip install cairosvg pillow
.venv/bin/python tools/gen_tiles.py
.venv/bin/python tools/gen_dice.py
.venv/bin/python tools/gen_audio.py
.venv/bin/python tools/gen_icons.py
```

After regenerating tiles, dice, or audio, copy `assets/` to `public/assets/`.
