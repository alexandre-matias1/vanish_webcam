"""Draw UI text with accents (Portuguese) on OpenCV images.

cv2.putText only supports ASCII, so "Mãos" or "ação" would render as "???".
put_text() keeps cv2.putText's coordinates (org = left end of the baseline)
and its Hershey-like scale, but draws with Pillow and the bundled DejaVu font.
Without Pillow or the font it falls back to cv2.putText with accents removed.
"""

from __future__ import annotations

import unicodedata
from functools import lru_cache
from pathlib import Path

import cv2
import numpy as np

FONT_DIR = Path(__file__).resolve().parent / "assets" / "fonts"
REGULAR_FONT = FONT_DIR / "DejaVuSans.ttf"
BOLD_FONT = FONT_DIR / "DejaVuSans-Bold.ttf"
# Pixel size per Hershey SIMPLEX scale unit, so existing layouts keep their size.
PIXELS_PER_SCALE = 30.0

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - Pillow ships with mediapipe/matplotlib.
    Image = ImageDraw = ImageFont = None


@lru_cache(maxsize=64)
def _font(size: int, bold: bool):
    if ImageFont is None:
        return None
    path = BOLD_FONT if bold else REGULAR_FONT
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return None


def _ascii(text: str) -> str:
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")


def _font_for(scale: float, thickness: int):
    return _font(max(6, round(scale * PIXELS_PER_SCALE)), thickness >= 2)


def text_size(text: str, scale: float, thickness: int = 1) -> tuple[int, int]:
    """Width and cap height, like the first value of cv2.getTextSize."""
    font = _font_for(scale, thickness)
    if font is None:
        (width, height), _ = cv2.getTextSize(_ascii(text), cv2.FONT_HERSHEY_SIMPLEX,
                                             scale, thickness)
        return width, height
    left, _, right, _ = font.getbbox(text, anchor="ls")
    _, top, _, _ = font.getbbox("H", anchor="ls")
    return right - left, -top


def put_text(image: np.ndarray, text: str, org: tuple[int, int], scale: float,
             color: tuple[int, int, int], thickness: int = 1,
             outline: tuple[int, int, int] | None = None, outline_width: int = 0) -> None:
    """Draw text in place; color is BGR, as everywhere else in OpenCV."""
    font = _font_for(scale, thickness)
    if font is None:
        safe = _ascii(text)
        if outline is not None and outline_width:
            cv2.putText(image, safe, org, cv2.FONT_HERSHEY_SIMPLEX, scale, outline,
                        thickness + 2 * outline_width, cv2.LINE_AA)
        cv2.putText(image, safe, org, cv2.FONT_HERSHEY_SIMPLEX, scale, color,
                    thickness, cv2.LINE_AA)
        return

    stroke = outline_width if outline is not None else 0
    left, top, right, bottom = font.getbbox(text, anchor="ls", stroke_width=stroke)
    x1, y1 = org[0] + left, org[1] + top
    x2, y2 = org[0] + right, org[1] + bottom
    cx1, cy1 = max(0, x1), max(0, y1)
    cx2, cy2 = min(image.shape[1], x2), min(image.shape[0], y2)
    if cx1 >= cx2 or cy1 >= cy2:
        return

    # Render white-on-black masks for the fill and the outline, then blend
    # only that small region, so the cost is independent of the frame size.
    size = (x2 - x1, y2 - y1)
    position = (-left, -top)
    fill = Image.new("L", size, 0)
    ImageDraw.Draw(fill).text(position, text, font=font, fill=255, anchor="ls")
    region = image[cy1:cy2, cx1:cx2]
    crop = (slice(cy1 - y1, cy2 - y1), slice(cx1 - x1, cx2 - x1))
    layers = []
    if stroke:
        edge = Image.new("L", size, 0)
        ImageDraw.Draw(edge).text(position, text, font=font, fill=255, anchor="ls",
                                  stroke_width=stroke, stroke_fill=255)
        layers.append((np.asarray(edge)[crop], outline))
    layers.append((np.asarray(fill)[crop], color))

    blended = region.astype(np.float32)
    for mask, bgr in layers:
        alpha = (mask.astype(np.float32) / 255.0)[:, :, None]
        blended = np.asarray(bgr, np.float32) * alpha + blended * (1.0 - alpha)
    region[:] = np.clip(blended, 0, 255).astype(np.uint8)
