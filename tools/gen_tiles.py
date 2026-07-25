#!/usr/bin/env python3
"""Generate the Flip10 tile SVG set with path-baked digit numbers.

The numeric value is composed from digit paths defined inline, so the SVG
is fully self-contained and renders identically across all platforms (no
font fallback issues). Each digit is a small path; numbers 10-12 compose
two digits side by side.
"""

from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "svg" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

IVORY_TOP = "#FBEFCB"
IVORY_MID = "#F4E3BD"
IVORY_BOTTOM = "#D5BD8A"
BRASS_TOP = "#F4D271"
BRASS_MID = "#D7A941"
BRASS_DARK = "#7E5A12"
INK = "#201610"

# Hand-drawn digit paths inside a 24x32 viewBox, origin at top-left.
# Designed in a chunky slab-serif style with rounded terminals.
DIGITS = {
    0: "M 7 2 C 3 2 2 5 2 9 L 2 23 C 2 27 3 30 7 30 L 17 30 C 21 30 22 27 22 23 L 22 9 C 22 5 21 2 17 2 Z M 7 6 L 17 6 C 18 6 18 7 18 9 L 18 23 C 18 25 18 26 17 26 L 7 26 C 6 26 6 25 6 23 L 6 9 C 6 7 6 6 7 6 Z",
    1: "M 8 6 L 14 4 L 14 28 L 18 28 L 18 30 L 8 30 L 8 28 L 12 28 L 12 8 L 9 9 Z",
    2: "M 6 8 C 6 5 8 2 12 2 C 16 2 19 4 19 8 C 19 11 17 13 14 15 L 8 22 C 7 23 7 25 7 26 L 19 26 L 19 23 L 21 23 L 21 30 L 4 30 L 4 27 C 4 25 5 23 7 21 L 14 14 C 16 12 17 11 17 8 C 17 6 15 6 12 6 C 9 6 8 8 8 10 L 8 11 L 6 11 Z",
    3: "M 5 8 C 5 4 8 2 12 2 C 16 2 19 4 19 7 C 19 10 17 12 14 13 C 17 13 20 15 20 19 C 20 24 17 30 12 30 C 7 30 4 27 4 23 L 4 22 L 7 22 L 7 23 C 7 26 9 26 12 26 C 15 26 16 23 16 20 C 16 17 15 15 11 15 L 9 15 L 9 12 L 11 12 C 14 12 15 10 15 8 C 15 6 14 5 12 5 C 9 5 8 7 8 9 L 8 10 L 5 10 Z",
    4: "M 14 2 L 17 2 L 17 22 L 21 22 L 21 25 L 17 25 L 17 30 L 14 30 L 14 25 L 3 25 L 3 22 Z M 14 9 L 7 22 L 14 22 Z",
    5: "M 4 2 L 19 2 L 19 8 L 16 8 L 16 5 L 8 5 L 8 13 C 9 12 11 12 12 12 C 17 12 20 15 20 21 C 20 26 17 30 12 30 C 7 30 4 27 4 23 L 4 22 L 7 22 L 7 23 C 7 26 9 27 12 27 C 15 27 16 24 16 21 C 16 18 15 15 12 15 C 9 15 7 16 7 18 L 4 18 Z",
    6: "M 19 4 L 16 7 C 15 5 13 4 11 4 C 7 4 4 8 4 14 L 4 18 C 5 14 8 13 12 13 C 17 13 20 16 20 21 C 20 26 17 30 11 30 C 5 30 2 25 2 16 L 2 14 C 2 6 5 1 11 1 C 14 1 17 2 19 4 Z M 7 18 C 7 23 8 27 11 27 C 14 27 16 25 16 21 C 16 17 14 16 11 16 C 8 16 7 17 7 18 Z",
    7: "M 4 2 L 21 2 L 21 6 L 13 30 L 9 30 L 17 5 L 4 5 Z",
    8: "M 12 1 C 7 1 4 4 4 8 C 4 11 6 13 8 14 C 5 15 3 17 3 21 C 3 26 7 30 12 30 C 17 30 21 26 21 21 C 21 17 19 15 16 14 C 18 13 20 11 20 8 C 20 4 17 1 12 1 Z M 12 4 C 15 4 16 6 16 8 C 16 11 14 12 12 12 C 10 12 8 11 8 8 C 8 6 9 4 12 4 Z M 12 16 C 15 16 17 18 17 21 C 17 24 15 27 12 27 C 9 27 7 24 7 21 C 7 18 9 16 12 16 Z",
    9: "M 5 28 L 8 25 C 9 27 11 28 13 28 C 17 28 20 24 20 18 L 20 14 C 19 18 16 19 12 19 C 7 19 4 16 4 11 C 4 6 7 2 13 2 C 19 2 22 7 22 16 L 22 18 C 22 26 19 31 13 31 C 10 31 7 30 5 28 Z M 17 14 C 17 9 16 5 13 5 C 10 5 8 7 8 11 C 8 15 10 16 13 16 C 16 16 17 15 17 14 Z",
}


def _digit_path(digit: int, x: float, y: float, scale: float = 1.0) -> str:
    """Place a digit path at (x, y) with the given scale."""
    return (
        f'<g transform="translate({x} {y}) scale({scale})" fill="{INK}">'
        f'<path d="{DIGITS[digit]}"/>'
        f'</g>'
    )


def _number_paths(number: int) -> str:
    """Compose a multi-digit number centered in a 48x68 area (between the
    brass nameplate at the top and the bottom of the tile)."""
    digits = [int(c) for c in str(number)]
    digit_w = 24  # digit viewBox width
    digit_h = 32  # digit viewBox height
    total_w = digit_w * len(digits) - 4 * (len(digits) - 1)  # small gap
    # The tile is 60x100; nameplate ends at y=12; bottom is y=100.
    # Center the number in the remaining body (y=14 to y=96, so 82px tall).
    # Scale digit to fit nicely.
    available_w = 48
    available_h = 56
    target_h = available_h - 4  # some padding
    scale = min(target_h / digit_h, available_w / total_w)
    rendered_w = total_w * scale
    # Tile inner area: x=3 to x=57 (width 54), y=12 to y=97 (height 85)
    # Center horizontally around x=30
    start_x = 30 - rendered_w / 2
    start_y = 14 + (available_h - digit_h * scale) / 2
    parts = []
    cursor = start_x
    for d in digits:
        parts.append(_digit_path(d, cursor, start_y, scale))
        cursor += digit_w * scale
    return "\n  ".join(parts)


def write_ivory(number: int) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 100" role="presentation">
  <defs>
    <linearGradient id="iv-{number}-face" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{IVORY_TOP}"/>
      <stop offset="0.5" stop-color="{IVORY_MID}"/>
      <stop offset="1" stop-color="{IVORY_BOTTOM}"/>
    </linearGradient>
    <linearGradient id="iv-{number}-strip" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{BRASS_TOP}"/>
      <stop offset="1" stop-color="{BRASS_DARK}"/>
    </linearGradient>
  </defs>
  <rect x="3" y="3" width="54" height="94" rx="6" fill="url(#iv-{number}-face)" stroke="#7B5A26" stroke-width="1.4"/>
  <rect x="6" y="6" width="48" height="6" rx="2" fill="url(#iv-{number}-strip)" stroke="{BRASS_DARK}" stroke-width="0.6"/>
  <rect x="9" y="9" width="42" height="82" rx="3" fill="none" stroke="{BRASS_DARK}" stroke-width="0.8" opacity="0.45"/>
  <rect x="14" y="14" width="32" height="2" fill="#FFFFFF" opacity="0.5"/>
  <circle cx="10" cy="9" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="50" cy="9" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="10" cy="91" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="50" cy="91" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  {_number_paths(number)}
</svg>
"""


def write_closed() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 100" role="presentation">
  <defs>
    <linearGradient id="cl-face" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4A2E15"/>
      <stop offset="1" stop-color="#1A0F06"/>
    </linearGradient>
  </defs>
  <rect x="3" y="3" width="54" height="94" rx="6" fill="url(#cl-face)" stroke="#0A0502" stroke-width="1.4"/>
  <rect x="9" y="9" width="42" height="82" rx="3" fill="none" stroke="{BRASS_DARK}" stroke-width="0.6" opacity="0.4"/>
  <rect x="6" y="6" width="48" height="6" rx="2" fill="#0A0502" opacity="0.85"/>
  <rect x="6" y="88" width="48" height="6" rx="2" fill="#0A0502" opacity="0.85"/>
  <line x1="14" y1="22" x2="46" y2="22" stroke="{BRASS_DARK}" stroke-width="0.6" opacity="0.4"/>
  <line x1="14" y1="78" x2="46" y2="78" stroke="{BRASS_DARK}" stroke-width="0.6" opacity="0.4"/>
  <rect x="20" y="36" width="20" height="28" rx="2" fill="none" stroke="{BRASS_DARK}" stroke-width="0.6" opacity="0.25"/>
  <rect x="24" y="42" width="12" height="2" fill="{BRASS_DARK}" opacity="0.3"/>
  <rect x="24" y="48" width="12" height="2" fill="{BRASS_DARK}" opacity="0.3"/>
  <rect x="24" y="54" width="12" height="2" fill="{BRASS_DARK}" opacity="0.3"/>
</svg>
"""


def write_selected(number: int) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 100" role="presentation">
  <defs>
    <linearGradient id="sel-{number}-face" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{IVORY_TOP}"/>
      <stop offset="0.5" stop-color="{IVORY_MID}"/>
      <stop offset="1" stop-color="{IVORY_BOTTOM}"/>
    </linearGradient>
    <linearGradient id="sel-{number}-strip" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFE6A2"/>
      <stop offset="1" stop-color="{BRASS_DARK}"/>
    </linearGradient>
  </defs>
  <rect x="3" y="3" width="54" height="94" rx="6" fill="url(#sel-{number}-face)" stroke="#7B5A26" stroke-width="1.4"/>
  <rect x="6" y="6" width="48" height="6" rx="2" fill="url(#sel-{number}-strip)" stroke="{BRASS_DARK}" stroke-width="0.6"/>
  <rect x="9" y="9" width="42" height="82" rx="3" fill="none" stroke="{BRASS_MID}" stroke-width="1.4"/>
  <rect x="14" y="14" width="32" height="2" fill="#FFFFFF" opacity="0.6"/>
  <circle cx="10" cy="9" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="50" cy="9" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="10" cy="91" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="50" cy="91" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  {_number_paths(number)}
</svg>
"""


def write_hinted(number: int) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 100" role="presentation">
  <defs>
    <linearGradient id="hi-{number}-face" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{IVORY_TOP}"/>
      <stop offset="0.5" stop-color="{IVORY_MID}"/>
      <stop offset="1" stop-color="{IVORY_BOTTOM}"/>
    </linearGradient>
    <linearGradient id="hi-{number}-strip" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#C8F5D8"/>
      <stop offset="1" stop-color="#0A2A1B"/>
    </linearGradient>
  </defs>
  <rect x="3" y="3" width="54" height="94" rx="6" fill="url(#hi-{number}-face)" stroke="#7B5A26" stroke-width="1.4"/>
  <rect x="6" y="6" width="48" height="6" rx="2" fill="url(#hi-{number}-strip)" stroke="#0A2A1B" stroke-width="0.6"/>
  <rect x="9" y="9" width="42" height="82" rx="3" fill="none" stroke="#76D7A6" stroke-width="1.4"/>
  <rect x="14" y="14" width="32" height="2" fill="#FFFFFF" opacity="0.6"/>
  <circle cx="10" cy="9" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="50" cy="9" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="10" cy="91" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  <circle cx="50" cy="91" r="1.2" fill="{BRASS_DARK}" opacity="0.7"/>
  {_number_paths(number)}
</svg>
"""


def write_mini_ivory() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 15 18" role="presentation">
  <rect x="1" y="1" width="13" height="16" rx="2" fill="{IVORY_MID}" stroke="#7B5A26" stroke-width="0.6"/>
  <rect x="2.5" y="2.5" width="10" height="13" rx="1" fill="none" stroke="{BRASS_DARK}" stroke-width="0.4" opacity="0.4"/>
</svg>
"""


def write_mini_closed() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 15 18" role="presentation">
  <rect x="1" y="1" width="13" height="16" rx="2" fill="#302820" stroke="#0A0502" stroke-width="0.6"/>
  <line x1="3" y1="3" x2="12" y2="3" stroke="{BRASS_DARK}" stroke-width="0.3" opacity="0.3"/>
  <line x1="3" y1="15" x2="12" y2="15" stroke="{BRASS_DARK}" stroke-width="0.3" opacity="0.3"/>
</svg>
"""


def main() -> None:
    for n in range(1, 13):
        (OUT / f"tile-ivory-{n}.svg").write_text(write_ivory(n))
        (OUT / f"tile-selected-{n}.svg").write_text(write_selected(n))
        (OUT / f"tile-hinted-{n}.svg").write_text(write_hinted(n))
    (OUT / "tile-closed.svg").write_text(write_closed())
    (OUT / "tile-mini-ivory.svg").write_text(write_mini_ivory())
    (OUT / "tile-mini-closed.svg").write_text(write_mini_closed())
    # Remove the generic non-numbered tile files; we now have per-number variants.
    for f in ["tile-ivory.svg", "tile-selected.svg", "tile-hinted.svg"]:
        old = OUT / f
        if old.exists():
            old.unlink()
    print(f"Wrote per-number tile SVGs to {OUT}")


if __name__ == "__main__":
    main()
