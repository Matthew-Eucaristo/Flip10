#!/usr/bin/env python3
"""Generate web PNG icons from assets/svg/misc/brand-mark.svg.

Outputs:
  - public/favicon.svg
  - public/favicon.png (32x32)
  - public/icons/Icon-192.png
  - public/icons/Icon-512.png
  - public/icons/Icon-maskable-192.png
  - public/icons/Icon-maskable-512.png

Requires: cairosvg, pillow (PIL).
"""

import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "assets" / "svg" / "misc" / "brand-mark.svg"
WEB = REPO / "public"
ICONS = WEB / "icons"


def check_deps() -> None:
    try:
        import cairosvg  # noqa: F401
        from PIL import Image  # noqa: F401
    except Exception as e:  # pragma: no cover
        print(f"Missing dependency: {e}")
        print("Install with: pip install cairosvg pillow")
        sys.exit(1)


def render_png(svg_path: Path, png_path: Path, size: int) -> None:
    import cairosvg
    png_path.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(svg_path),
        write_to=str(png_path),
        output_width=size,
        output_height=size,
    )
    print(f"  -> {png_path.relative_to(REPO)}  ({size}x{size})")


def render_maskable(src_svg: Path, dst_png: Path, size: int) -> None:
    """Maskable icon: brand mark centered on a felt background with 40% safe area."""
    import cairosvg
    from PIL import Image
    import io

    bg_color = (11, 107, 71, 255)  # #0B6B47 (slightly darker than felt for contrast)
    canvas = Image.new("RGBA", (size, size), bg_color)
    inner_size = int(size * 0.6)
    inner = Image.open(io.BytesIO(cairosvg.svg2png(url=str(src_svg), output_width=inner_size, output_height=inner_size)))
    offset = (size - inner_size) // 2
    canvas.paste(inner, (offset, offset), inner)
    canvas.save(dst_png)
    print(f"  -> {dst_png.relative_to(REPO)}  (maskable {size}x{size})")


def main() -> None:
    if not SRC.exists():
        print(f"Source SVG not found: {SRC}")
        sys.exit(1)
    check_deps()

    # web/favicon.svg: copy of the master mark
    shutil.copy2(SRC, WEB / "favicon.svg")
    print("  -> public/favicon.svg")

    # PNG fallbacks
    render_png(SRC, WEB / "favicon.png", 32)
    render_png(SRC, ICONS / "Icon-192.png", 192)
    render_png(SRC, ICONS / "Icon-512.png", 512)
    render_maskable(SRC, ICONS / "Icon-maskable-192.png", 192)
    render_maskable(SRC, ICONS / "Icon-maskable-512.png", 512)
    print("done.")


if __name__ == "__main__":
    main()
