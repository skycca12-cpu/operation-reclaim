"""Bake pixel-aligned movement and damage atlases from the Jeju base poses."""
from math import pi, sin
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1] / "assets/reclaim/zombies/jeju"
FRAMES = 8
HEIGHT = 110
FOOT = 99
AIRBORNE = {"S13", "S14", "S15"}
CRABS = {"S02", "S05", "S07", "S20"}


def damaged(sprite, seed, tier):
    result = sprite.copy()
    alpha = sprite.getchannel("A")
    interior = alpha.filter(ImageFilter.MinFilter(5))
    rng = Random(seed)
    marks = Image.new("RGBA", sprite.size)
    brush = ImageDraw.Draw(marks)
    for index in range(7 if tier == 2 else 3):
        for attempt in range(60):
            x, y = rng.randrange(sprite.width), rng.randrange(15, 75)
            if interior.getpixel((x, y)):
                break
        else:
            continue
        length = rng.randrange(5, 14)
        points = [(x, y), (x + length // 2, y + 4), (x + length, y + 2)]
        brush.line(points, fill=(38, 23, 25, 255), width=3)
        brush.line([(a, b + 2) for a, b in points], fill=(150, 88, 63, 230))
        if index >= 3:
            brush.polygon([(x, y), (x - 3, y + 6), (x + 3, y + 10), (x + 5, y + 4)],
                          fill=(53, 30, 34, 255))
    result.alpha_composite(marks)
    result.putalpha(alpha)
    return result


def pose(sprite, kind, stride, width):
    frame = Image.new("RGBA", (width, HEIGHT))
    x = (width - sprite.width) // 2
    y = FOOT - sprite.height
    if kind in AIRBORNE:
        for column in range(sprite.width):
            distance = abs(2 * column / sprite.width - 1)
            offset = round(stride * (2 + 8 * distance ** 2))
            frame.alpha_composite(sprite.crop((column, 0, column + 1, sprite.height)), (x + column, y + offset))
    else:
        leg_start = 60 if kind in CRABS else 64
        for row in range(sprite.height):
            movement = max(0.0, (row - leg_start) / (sprite.height - leg_start))
            count = 4 if kind in CRABS else 2
            for pair in range(count):
                a, b = sprite.width * pair // count, sprite.width * (pair + 1) // count
                step = stride * (-1 if pair % 2 else 1)
                dx = round(step * movement * 4)
                dy = round(-max(0.0, step) * movement * 8)
                frame.alpha_composite(sprite.crop((a, row, b, row + 1)), (x + a + dx, y + row + dy))
    return frame


def main():
    output = ROOT / "motion"
    output.mkdir(exist_ok=True)
    for path in sorted(ROOT.glob("*.png")):
        if path.stem == "S11":
            # The siege enemy uses individually drawn poses.
            continue
        sprite = Image.open(path).convert("RGBA")
        width = sprite.width + 20
        atlas = Image.new("RGBA", (width * FRAMES, HEIGHT * 3))
        for tier in range(3):
            skin = damaged(sprite, sum(map(ord, path.stem)), tier) if tier else sprite
            for frame in range(FRAMES):
                stride = sin(frame * 2 * pi / FRAMES)
                atlas.alpha_composite(pose(skin, path.stem, stride, width), (frame * width, tier * HEIGHT))
        atlas.save(output / path.name, optimize=True)


if __name__ == "__main__":
    main()
