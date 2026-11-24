"""Pack the original zombie attack artwork into articulated body and sleeve layers."""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

CELL = 160
ROOT = Path(__file__).resolve().parents[1] / "assets/reclaim/zombies"
RIGHT = [
    [(97, 82), (108, 83), (119, 124), (97, 130), (97, 107), (94, 94)],
    [(97, 83), (103, 83), (107, 93), (106, 103), (115, 110), (109, 124), (100, 126), (99, 111), (95, 99)],
    [(100, 84), (108, 83), (117, 123), (101, 129), (101, 113), (97, 98)],
    [(101, 84), (110, 85), (117, 122), (102, 126), (103, 111), (96, 96)],
    [(96, 78), (105, 82), (118, 125), (98, 129), (98, 107), (94, 95)],
    [(99, 81), (111, 84), (117, 124), (98, 128), (99, 108), (96, 98)],
    [(99, 84), (109, 87), (116, 124), (98, 128), (99, 113), (96, 100)],
    [(100, 84), (112, 83), (124, 126), (100, 130), (100, 112), (97, 99)],
]
LEFT = [
    [(62, 82), (53, 83), (43, 122), (63, 128), (63, 107), (66, 93)],
    [(62, 84), (55, 86), (48, 109), (44, 123), (55, 127), (63, 113), (66, 97)],
    [(60, 84), (53, 84), (44, 123), (62, 128), (62, 112), (65, 95)],
    [(59, 84), (52, 85), (43, 121), (60, 126), (60, 110), (65, 96)],
    [(63, 79), (56, 82), (43, 124), (62, 129), (62, 107), (66, 95)],
    [(61, 81), (51, 84), (42, 123), (60, 127), (62, 108), (66, 97)],
    [(61, 84), (51, 87), (42, 126), (62, 129), (62, 111), (66, 95)],
    [],  # Stays with the body so the elderly zombie keeps its cane planted.
]
# Match the elbows used to anchor forearm rotation in zombie_visual.gd.
ELBOW_Y = [(103, 103), (104, 103), (106, 106), (106, 106), (102, 102), (105, 105), (105, 105), (105, 108)]


def layer(frame, mask):
    result = frame.copy()
    result.putalpha(ImageChops.multiply(frame.getchannel("A"), mask))
    return result


def pack():
    paths = sorted(ROOT.glob("zombie_0*.png"))
    atlas = Image.new("RGBA", (len(paths) * CELL, CELL * 5))
    for index, path in enumerate(paths):
        frame = Image.open(path).convert("RGBA").crop((12 * CELL, 0, 13 * CELL, CELL))
        removed = Image.new("L", frame.size)
        for arm, polygon in enumerate((LEFT[index], RIGHT[index])):
            if not polygon:
                continue
            mask = Image.new("L", frame.size)
            ImageDraw.Draw(mask).polygon(polygon, fill=255)
            removed = ImageChops.lighter(removed, mask)
            elbow_y = ELBOW_Y[index][arm]
            for part in range(2):
                section = Image.new("L", frame.size)
                bounds = (0, 0, CELL - 1, elbow_y + 2) if part == 0 else (0, elbow_y, CELL - 1, CELL - 1)
                ImageDraw.Draw(section).rectangle(bounds, fill=255)
                atlas.paste(layer(frame, ImageChops.multiply(mask, section)), (index * CELL, (1 + arm * 2 + part) * CELL))
        atlas.paste(layer(frame, ImageChops.invert(removed)), (index * CELL, 0))
    atlas.save(ROOT / "attack_parts.png")


if __name__ == "__main__":
    pack()
