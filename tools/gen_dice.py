#!/usr/bin/env python3
"""Generate dice face SVGs without filters (flutter_svg warns on <filter/>)."""

from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "svg" / "dice"
OUT.mkdir(parents=True, exist_ok=True)

IVORY_TOP = "#FBEFCB"
IVORY_MID = "#F4E3BD"
IVORY_BOTTOM = "#D5BD8A"
INK = "#201610"


def face_svg(pip_positions: list[tuple[float, float]], shadow: bool = True) -> str:
    shadow_block = ""
    if shadow:
        shadow_block = (
            f'  <rect x="6" y="8" width="88" height="88" rx="14" '
            f'fill="#000" opacity="0.18"/>\n'
        )
    pips = "\n".join(
        f'    <circle cx="{x}" cy="{y}" r="7" fill="{INK}"/>'
        for x, y in pip_positions
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" role="presentation">
  <defs>
    <linearGradient id="face" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{IVORY_TOP}"/>
      <stop offset="0.5" stop-color="{IVORY_MID}"/>
      <stop offset="1" stop-color="{IVORY_BOTTOM}"/>
    </linearGradient>
  </defs>
{shadow_block}  <rect x="4" y="4" width="92" height="92" rx="14" fill="url(#face)" stroke="#7B5A26" stroke-width="1.6"/>
  <rect x="6" y="6" width="88" height="88" rx="12" fill="none" stroke="#FFFFFF" stroke-width="0.4" opacity="0.45"/>
  <g>
{pips}
  </g>
</svg>
"""


def blank_svg() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" role="presentation">
  <defs>
    <linearGradient id="blank" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#E0CD9C"/>
      <stop offset="1" stop-color="#B6956A"/>
    </linearGradient>
  </defs>
  <rect x="6" y="8" width="88" height="88" rx="14" fill="#000" opacity="0.18"/>
  <rect x="4" y="4" width="92" height="92" rx="14" fill="url(#blank)" stroke="#7B5A26" stroke-width="1.6"/>
  <line x1="30" y1="50" x2="70" y2="50" stroke="{INK}" stroke-width="3.5" stroke-linecap="round" opacity="0.35"/>
</svg>
"""


def tumble_svg(opacity: float = 0.55) -> str:
    return face_svg(
        [(28, 28), (72, 28), (28, 72), (72, 72)],
        shadow=True,
    ).replace('fill="{INK}"/>', f'fill="{INK}" opacity="{opacity}"/>')


def tumble_svg2(opacity: float = 0.55) -> str:
    return face_svg(
        [(28, 28), (50, 50), (72, 72)],
        shadow=True,
    ).replace('fill="{INK}"/>', f'fill="{INK}" opacity="{opacity}"/>')


# Position templates
PIP_LAYOUTS = {
    1: [(50, 50)],
    2: [(28, 28), (72, 72)],
    3: [(28, 28), (50, 50), (72, 72)],
    4: [(28, 28), (72, 28), (28, 72), (72, 72)],
    5: [(28, 28), (72, 28), (50, 50), (28, 72), (72, 72)],
    6: [(28, 22), (72, 22), (28, 50), (72, 50), (28, 78), (72, 78)],
}


def main() -> None:
    for n, positions in PIP_LAYOUTS.items():
        (OUT / f"face-{n}.svg").write_text(face_svg(positions))
    (OUT / "face-blank.svg").write_text(blank_svg())
    (OUT / "tumble-1.svg").write_text(tumble_svg())
    (OUT / "tumble-2.svg").write_text(tumble_svg2())
    print(f"Wrote dice SVGs to {OUT}")


if __name__ == "__main__":
    main()
