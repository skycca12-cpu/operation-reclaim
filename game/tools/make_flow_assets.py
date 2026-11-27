"""Deterministic asset preparation for the boot -> menu -> character flow.

Only crops / background removal / small text erasure are applied to the approved
artwork; no repainting or redesign. Run from the project root:
    python3 tools/make_flow_assets.py
"""
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "references" / "approved-art"
OUT_UI = ROOT / "assets" / "reclaim" / "ui"
OUT_PORTRAIT = ROOT / "assets" / "reclaim" / "portraits"

# (source sheet, crop box in source pixels, output name)
# label boxes on the sheets (source pixels) painted with sheet bg before cut-out
LABELS = {"서하린_한유진_승인시안.png": [(0, 0, 192, 64), (0, 630, 196, 702)]}

PORTRAITS = [
    ("강태준_승인원본.png", (30, 175, 590, 1010), "tae_full.png"),
    ("윤시혁_승인원본.png", (60, 160, 592, 1190), "si_full.png"),
    ("서하린_한유진_승인시안.png", (60, 0, 420, 612), "harin_full.png"),
    ("서하린_한유진_승인시안.png", (70, 625, 450, 1240), "yujin_full.png"),
]


def remove_background(img: Image.Image, tol: float = 34.0) -> Image.Image:
    """Flood fill the flat lavender sheet background from the borders, then keep
    only large connected components (drops sheet labels / captions)."""
    rgba = np.asarray(img.convert("RGBA")).astype(np.int32)
    h, w = rgba.shape[:2]
    rgb = rgba[..., :3]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    close = np.sqrt(((rgb - bg) ** 2).sum(-1)) < tol
    visited = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if close[y, x] and not visited[y, x]:
                visited[y, x] = True; q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if close[y, x] and not visited[y, x]:
                visited[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and close[ny, nx]:
                visited[ny, nx] = True; q.append((ny, nx))
    fg = ~visited
    # connected components of the foreground
    labels = np.zeros((h, w), np.int32)
    sizes = [0]
    cur = 0
    for sy in range(h):
        for sx in range(w):
            if fg[sy, sx] and labels[sy, sx] == 0:
                cur += 1
                labels[sy, sx] = cur
                q.append((sy, sx)); n = 0
                while q:
                    y, x = q.popleft(); n += 1
                    for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                        if 0 <= ny < h and 0 <= nx < w and fg[ny, nx] and labels[ny, nx] == 0:
                            labels[ny, nx] = cur; q.append((ny, nx))
                sizes.append(n)
    biggest = max(sizes)
    keep = np.array([s >= biggest * 0.04 for s in sizes])
    keep[0] = False
    mask = keep[labels]
    out = rgba.copy().astype(np.uint8)
    out[..., 3] = np.where(mask, 255, 0).astype(np.uint8)
    res = Image.fromarray(out, "RGBA")
    return res.crop(res.getbbox())


def erase_region(img: Image.Image, box, bright: int = 150) -> Image.Image:
    """Erase baked UI text/bar pixels inside `box` by diffusing neighbouring
    background pixels into them (simple iterative inpaint)."""
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    x0, y0, x1, y1 = box
    region = a[y0:y1, x0:x1]
    r, g, b = region[..., 0], region[..., 1], region[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    red = (r > 150) & (r > g * 1.8)
    mask = (lum > bright) | red
    # grow mask a little to swallow anti-aliased edges
    for _ in range(3):
        m = mask.copy()
        m[1:] |= mask[:-1]; m[:-1] |= mask[1:]; m[:, 1:] |= mask[:, :-1]; m[:, :-1] |= mask[:, 1:]
        mask = m
    known = ~mask
    region = region.copy()
    region[mask] = 0
    for _ in range(400):
        if known.all():
            break
        acc = np.zeros_like(region); cnt = np.zeros(known.shape, np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sk = np.roll(known, (dy, dx), (0, 1)); sr = np.roll(region, (dy, dx), (0, 1))
            acc += sr * sk[..., None]; cnt += sk
        newly = (~known) & (cnt > 0)
        region[newly] = acc[newly] / cnt[newly][:, None]
        known = known | newly
    a[y0:y1, x0:x1] = region
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGB")


def main() -> None:
    OUT_UI.mkdir(parents=True, exist_ok=True)
    OUT_PORTRAIT.mkdir(parents=True, exist_ok=True)
    for src, box, name in PORTRAITS:
        sheet = Image.open(REF / src).convert("RGBA")
        for lb in LABELS.get(src, []):
            sheet.paste(sheet.getpixel((600, 2)), lb)
        cut = remove_background(sheet.crop(box))
        cut.save(OUT_PORTRAIT / name)
        print("portrait", name, cut.size)
    menu = Image.open(REF / "메인화면_승인참고.png").convert("RGB")
    menu.save(OUT_UI / "main_menu_art.png")
    load = Image.open(REF / "로딩화면_참고.png").convert("RGB")
    # baked "작전 준비 중...", progress bar and "78%" live in this rectangle
    load = erase_region(load, (1020, 792, 1652, 889))
    load.save(OUT_UI / "loading_art.png")
    print("ui ok")


if __name__ == "__main__":
    main()
