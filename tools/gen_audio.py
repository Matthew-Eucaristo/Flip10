#!/usr/bin/env python3
"""Generate short procedural audio cues for Flip10.

Outputs 16-bit mono PCM WAVs into assets/audio/:
  - roll.wav    : 0.45s  tumbling dice (filtered noise + low thumps)
  - flip.wav    : 0.10s  wood click (short tonal pop)
  - select.wav  : 0.06s  felt tick (soft high blip for picking a tile)
  - deny.wav    : 0.14s  dull buzz (illegal pick rejection)
  - success.wav : 0.65s  brass chime (additive sine harmonics with decay)
  - blocked.wav : 0.30s  soft thud (low sine with quick decay)

The WAVs are intentionally tiny (<100KB total) so the web bundle stays small.
Re-run this script only when the audio palette changes.
"""

import math
import random
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)

SR = 44100


def write_wav(name: str, samples: list[float]) -> None:
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        peak = max(abs(s) for s in samples) or 1.0
        gain = 0.9 / peak
        data = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s * gain))
            data.extend(struct.pack("<h", int(v * 32767)))
        w.writeframes(bytes(data))
    print(f"  -> {path.name}  ({len(samples) / SR:.2f}s)")


def envelope(t: float, total: float, attack: float, release: float) -> float:
    if t < 0:
        return 0.0
    if t < attack:
        return t / attack
    if t > total - release:
        return max(0.0, (total - t) / release)
    return 1.0


def gen_roll() -> None:
    print("roll.wav")
    rng = random.Random(7)
    total = 0.45
    n = int(SR * total)
    samples = [0.0] * n
    for i in range(n):
        t = i / SR
        env = envelope(t, total, 0.01, 0.18) * 0.9
        noise = (rng.random() * 2 - 1) * 0.4
        # thumps
        thump_freq = 80 + 10 * math.sin(2 * math.pi * 6 * t)
        thump = math.sin(2 * math.pi * thump_freq * t) * 0.5
        wobble = math.sin(2 * math.pi * (220 + 30 * math.sin(2 * math.pi * 14 * t)) * t) * 0.18
        samples[i] = (noise * 0.55 + thump * 0.6 + wobble) * env
    write_wav("roll.wav", samples)


def gen_flip() -> None:
    print("flip.wav")
    total = 0.10
    n = int(SR * total)
    samples = []
    for i in range(n):
        t = i / SR
        env = envelope(t, total, 0.002, 0.04) * 0.9
        body = math.sin(2 * math.pi * 520 * t) * math.exp(-40 * t)
        click = math.sin(2 * math.pi * 1800 * t) * math.exp(-180 * t) * 0.4
        samples.append((body + click) * env)
    write_wav("flip.wav", samples)


def gen_select() -> None:
    print("select.wav")
    total = 0.06
    n = int(SR * total)
    samples = []
    for i in range(n):
        t = i / SR
        env = envelope(t, total, 0.001, 0.03) * 0.75
        body = math.sin(2 * math.pi * 880 * t) * math.exp(-55 * t)
        tick = math.sin(2 * math.pi * 2600 * t) * math.exp(-260 * t) * 0.35
        samples.append((body + tick) * env)
    write_wav("select.wav", samples)


def gen_deny() -> None:
    print("deny.wav")
    total = 0.14
    n = int(SR * total)
    samples = []
    for i in range(n):
        t = i / SR
        env = envelope(t, total, 0.004, 0.06) * 0.8
        # detuned low pair reads as a flat "nope" without being harsh
        body = math.sin(2 * math.pi * 140 * t) * math.exp(-16 * t)
        rub = math.sin(2 * math.pi * 148 * t) * math.exp(-16 * t)
        samples.append((body + rub) * 0.5 * env)
    write_wav("deny.wav", samples)


def gen_success() -> None:
    print("success.wav")
    notes = [(523.25, 0.0), (659.25, 0.08), (783.99, 0.16), (1046.5, 0.24)]
    total = 0.65
    n = int(SR * total)
    samples = [0.0] * n
    for i in range(n):
        t = i / SR
        v = 0.0
        for freq, start in notes:
            local = t - start
            if local < 0:
                continue
            env = math.exp(-3.2 * local) * (1 - math.exp(-120 * local))
            v += (
                math.sin(2 * math.pi * freq * local) * 0.5
                + math.sin(2 * math.pi * freq * 2 * local) * 0.18
                + math.sin(2 * math.pi * freq * 3 * local) * 0.08
            ) * env
        samples[i] = v
    write_wav("success.wav", samples)


def gen_blocked() -> None:
    print("blocked.wav")
    total = 0.30
    n = int(SR * total)
    samples = []
    for i in range(n):
        t = i / SR
        env = envelope(t, total, 0.005, 0.18) * 0.9
        body = math.sin(2 * math.pi * 110 * t) * math.exp(-9 * t)
        thud = math.sin(2 * math.pi * 60 * t) * math.exp(-14 * t) * 0.6
        samples.append((body * 0.5 + thud) * env)
    write_wav("blocked.wav", samples)


def main() -> None:
    print(f"Writing audio cues to {OUT}")
    gen_roll()
    gen_flip()
    gen_select()
    gen_deny()
    gen_success()
    gen_blocked()
    print("done.")


if __name__ == "__main__":
    main()
