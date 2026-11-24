"""Bake the approved zombie silhouettes and arm rig into normal-zombie atlases.

Run from any directory with Pillow and NumPy installed. Each page holds five
appearances. New outfits use garment-only colors, leaving faces and hands intact.
"""
from pathlib import Path
import math

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets/reclaim/zombies"
CELL = 160
FRAME = 72
PIVOT = np.array([80.0, 86.0])
PAGE_SIZE = 5
APPEARANCE_COUNT = 50
SOURCES = ["male", "female", "office", "hoodie", "worker", "police", "soldier", "elderly"]
COLORS = [(128, 86, 86), (99, 123, 82), (84, 115, 149),
          (153, 118, 70), (122, 94, 140), (80, 137, 132)]
SHOULDERS = [[(62,85),(98,85)],[(62,87),(98,87)],[(60,87),(102,87)],
             [(59,87),(103,87)],[(62,82),(98,82)],[(61,86),(101,86)],
             [(61,88),(102,88)],[(0,0),(103,87)]]
ELBOWS = [[(56,103),(104,103)],[(55,104),(105,103)],[(54,106),(108,106)],
          [(54,106),(108,106)],[(55,102),(104,102)],[(54,105),(109,105)],
          [(53,105),(109,105)],[(0,0),(111,108)]]
# Each pose is keyed as a pair of sleeve/forearm angles from vertical.
# Negative angles point right. Body pitch and knee bend are independent of the arms.
FRONT_POSES = [
    ((24, -24), (-24, 24), 0, .99),
    ((43, 147), (-43, -147), -2, 1),
    ((149, 179), (-149, -179), -4, 1),
    ((34, -26), (-34, 26), 7, .91),
    ((49, -18), (-49, 18), 5, .94),
    ((19, -8), (-19, 8), 2, .98),
]
SIDE_POSES = [
    ((-18, -58), (-35, -74), 0, .99),
    ((-43, -119), (-69, -144), -2, 1),
    ((-139, -170), (-155, -177), -5, 1),
    ((-36, -62), (-51, -23), 9, .91),
    ((-42, -62), (-55, -33), 6, .94),
    ((-18, -16), (-23, -29), 3, .98),
]
DIRECTIONS = [(0, 1), (-1, 0), (1, 0), (0, -1)]
IDLE = [0, 2]
WALK = [4, 6, 8, 10]
DEATH = [22, 23, 24, 25, 26]
COLUMNS = len(IDLE) + len(WALK) + len(DEATH) + 4 + len(DIRECTIONS) * len(FRONT_POSES) + 16


def cell(image, column, row):
    return image.crop((column*CELL, row*CELL, (column+1)*CELL, (row+1)*CELL))


def jacket(sprite, palette, death=False, arm=False):
    if palette is None:
        return sprite.copy()
    rgba = np.array(sprite)
    rgb = rgba[:, :, :3].astype(float)
    y, x = np.indices(rgba.shape[:2])
    skin = (rgb[:,:,0] > 112) & (rgb[:,:,1] > 104) & (rgb[:,:,2] < rgb[:,:,1] * 0.84)
    # Hand pixels remain the original skin color even when the sleeve is bent.
    eligible = (rgba[:,:,3] > 0) & ~skin & (rgb.max(axis=2) > 47)
    if arm:
        eligible &= (y >= 82) & (y <= 106)
    elif death:
        eligible &= (y >= 75)
    else:
        eligible &= (y >= 82) & (y < 112)
    luminosity = rgb @ np.array([.28, .58, .14])
    dye = np.array(palette)
    replacement = rgb * .32 + (dye + (luminosity[:,:,None]-110)*.73) * .68
    rgba[eligible,:3] = np.clip(replacement[eligible], 0, 255).astype("uint8")
    if not death:
        # Simple garment construction details anchored to the source shoulders:
        # chest stripe, split jacket, reflective work stripe, shoulder panel.
        style = COLORS.index(palette)
        panel = [(y >= 95) & (y <= 99), x < 79, (y >= 100) & (y <= 103),
                 (y <= 90), (abs(x-80) <= 4), (y >= 105) & (y <= 108)][style]
        panel &= eligible
        rgba[panel,:3] = np.clip(rgba[panel,:3].astype(float) * (1.30 if style % 2 == 0 else .72), 0, 255)
    return Image.fromarray(rgba)


def rotation(angle):
    c, s = math.cos(angle), math.sin(angle)
    return np.array([[c,-s],[s,c]])


def transformed(sprite, matrix, translation):
    inv = np.linalg.inv(matrix)
    v = -inv @ translation
    coefficients = (inv[0,0], inv[0,1], v[0], inv[1,0], inv[1,1], v[1])
    return sprite.transform((CELL,CELL), Image.Transform.AFFINE, coefficients,
                            Image.Resampling.NEAREST)


def attack(parts, base, palette, row, beat, walk_source):
    left, right, pitch, knee_bend = (SIDE_POSES if row in (1, 2) else FRONT_POSES)[beat]
    body = rotation(math.radians(pitch if row in (1, 2) else 0)) @ np.diag([1.0, knee_bend])
    mirror = np.diag([-1.0 if row == 1 else 1.0, 1.0])
    foot = np.array([49.0 if base == 7 else 80.0, 148.0])
    body_origin = PIVOT + mirror @ (foot + body @ (PIVOT - foot) - PIVOT)
    torso = jacket(parts[base][0], palette)
    if row != 0:
        # Keep the outfit and use the matching walking head for the attack direction.
        facing = 2 if row in (1, 2) else 3
        head_height = min(p[1] for p in SHOULDERS[base] if p[1] > 0) - 2
        head = cell(walk_source, 0, facing).crop((0, 0, CELL, head_height))
        torso.paste(head, (0, 0))
    torso = transformed(torso, mirror @ body,
                        body_origin - mirror @ body @ PIVOT)
    result = Image.new("RGBA", (CELL, CELL))
    if row != 3:
        result.alpha_composite(torso)
    for arm, angles in enumerate((left, right)):
        if base == 7 and arm == 0:
            continue
        shoulder = np.array(SHOULDERS[base][arm])
        elbow = np.array(ELBOWS[base][arm])
        sleeve_angle = math.atan2(-(elbow - shoulder)[0], (elbow - shoulder)[1])
        upper = mirror @ rotation(math.radians(angles[0]) - sleeve_angle)
        lower = mirror @ rotation(math.radians(angles[1]))
        joint = body_origin + mirror @ body @ (shoulder - PIVOT)
        for piece, transform, anchor, destination in (
            (1, upper, shoulder, joint),
            (2, lower, elbow, joint + upper @ (elbow - shoulder)),
        ):
            sprite = jacket(parts[base][piece + arm * 2], palette, arm=True)
            result.alpha_composite(transformed(sprite, transform, destination - transform @ anchor))
    if row == 3:
        # Keep the raised hands visible around the silhouette during the wind-up.
        result.alpha_composite(torso)
    return result


def elderly_walk(sprite, cane, column, row):
    # Use the original cane art, composited behind the gripping hand.
    hand_x, hand_y = [
        [(57,113),(58,108),(59,112),(58,108)],
        [(72,112),(72,108),(71,105),(73,110)],
        [(84,111),(90,110),(82,107),(89,110)],
        [(106,111),(106,103),(108,111),(105,106)],
    ][row][column]
    planted = cane.resize((cane.width, 150-hand_y), Image.Resampling.NEAREST)
    result = Image.new("RGBA", sprite.size)
    result.alpha_composite(planted, (hand_x-planted.width//2, hand_y))
    result.alpha_composite(sprite)
    return result


def reaction(sprite, phase, elderly=False):
    # Baked silhouettes: recoil, buckled knees, tense recovery, return.
    skew, squash, shift = [(0.06,.99,0),(-.08,.96,0),(.04,.98,0),(0,1,0)][phase]
    foot = np.array([80,145])
    if elderly:
        # Brace on the cane: keep its tip planted while the body recoils.
        foot = np.array([49,149])
        skew, squash, shift = [(0.10,.98,0),(-.12,.94,0),(.05,.98,0),(0,1,0)][phase]
    matrix = np.array([[1,skew],[0,squash]])
    return transformed(sprite,matrix,foot-matrix@foot+np.array([shift,0]))


def main():
    source = [Image.open(ROOT / f"zombie_{i:02}_{n}.png").convert("RGBA")
              for i,n in enumerate(SOURCES,1)]
    walk_sources = [Image.open(ROOT / "walk" / f"{name}.png").convert("RGBA") for name in SOURCES]
    cane = cell(source[7], 0, 0).crop((43, 116, 58, 150))
    rig = Image.open(ROOT / "attack_parts.png").convert("RGBA")
    parts = [[cell(rig,b,j) for j in range(5)] for b in range(len(source))]
    (ROOT/"population").mkdir(exist_ok=True)
    for page in range(APPEARANCE_COUNT//PAGE_SIZE):
        atlas = Image.new("RGBA",(FRAME*COLUMNS,FRAME*PAGE_SIZE))
        for line in range(PAGE_SIZE):
            appearance = page*PAGE_SIZE+line
            base = appearance%len(source)
            color = COLORS[appearance//len(source)-1] if appearance>=len(source) else None
            frames = [jacket(cell(source[base], c, 0),color)
                      for c in IDLE+WALK]
            frames += [jacket(cell(source[base],c,0),color,death=True) for c in DEATH]
            frames += [reaction(frames[0], i, elderly=base == 7) for i in range(4)]
            frames += [attack(parts,base,color,row,beat,walk_sources[base])
                       for row in range(4) for beat in range(len(FRONT_POSES))]
            for row in range(4):
                for column in range(4):
                    walk = jacket(cell(walk_sources[base], column, row), color)
                    frames.append(elderly_walk(walk, cane, column, row) if base == 7 else walk)
            for column,sprite in enumerate(frames):
                atlas.paste(sprite.resize((FRAME,FRAME),Image.Resampling.NEAREST),
                            (column*FRAME,line*FRAME))
        atlas.save(ROOT/"population"/f"page_{page}.png",optimize=True)


if __name__ == "__main__":
    main()
