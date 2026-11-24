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
# Brace, raise arms, overhead wind-up, contact, follow-through, recovery.
POSES = [(0.28,0.38,0.4),(0.66,0.57,-0.5),(1,.32,-2),
         (.39,.45,4),(.47,.36,3),(.18,.18,1.5)]
DIRECTIONS = [(0, 1), (-1, 0), (1, 0), (0, -1)]
IDLE = [0, 2]
WALK = [4, 6, 8, 10]
DEATH = [22, 23, 24, 25, 26]
COLUMNS = len(IDLE) + len(WALK) + len(DEATH) + 4 + len(DIRECTIONS) * len(POSES)


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


def attack(parts, base, palette, row, pose):
    x, y = DIRECTIONS[row]
    reach, bend, lean = pose
    flip = -1 if row == 1 else 1
    body = rotation(x*lean*.012) @ np.diag([flip, 1-max(0,lean)*.018])
    root = PIVOT + np.array([x,y])*max(0,lean)*.65 + np.array([0,lean])
    layers = []
    for arm in range(2):
        if base == 7 and arm == 0:
            continue
        shoulder = np.array(SHOULDERS[base][arm])
        elbow = np.array(ELBOWS[base][arm])
        side = -1 if arm == 0 else 1
        aim = (math.atan2(y,x*flip) - math.pi*.5 + math.pi) % math.tau - math.pi
        t = min(1,max(0,(reach-.48)/(.94-.48)))
        lift = t*t*(3-2*t)
        angle = (aim*(1-lift) - side*(math.pi-.43)*lift)*min(1,reach*2.2)
        if abs(y)>abs(x):
            angle += side*bend*1.15*(1-lift)
        upper = body @ rotation(angle)
        lower = upper @ rotation(side*bend*.9*(1-lift)) * (1+max(0,lean)*.035)
        joint = root + body @ (shoulder-PIVOT)
        layers.append([
            transformed(jacket(parts[base][1+arm*2],palette,arm=True),upper,joint-upper@shoulder),
            transformed(jacket(parts[base][2+arm*2],palette,arm=True),lower,joint+upper@(elbow-shoulder)-lower@elbow),
        ])
    torso = transformed(jacket(parts[base][0],palette),body,root-body@PIVOT)
    result = Image.new("RGBA",(CELL,CELL))
    order = [*layers, [torso]] if row == 3 else [[torso], *layers]
    for pair in order:
        for layer in pair:
            result.alpha_composite(layer)
    return result


def reaction(sprite, phase):
    # Baked silhouettes: recoil, buckled knees, tense recovery, return.
    skew, squash, shift = [(0.16,.98,3),(-.20,.88,5),(.10,.95,2),(0,1,0)][phase]
    foot = np.array([80,145])
    matrix = np.array([[1,skew],[0,squash]])
    return transformed(sprite,matrix,foot-matrix@foot+np.array([shift,0]))


def main():
    source = [Image.open(ROOT / f"zombie_{i:02}_{n}.png").convert("RGBA")
              for i,n in enumerate(SOURCES,1)]
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
            frames += [reaction(frames[0], i) for i in range(4)]
            frames += [attack(parts,base,color,row,pose)
                       for row in range(4) for pose in POSES]
            for column,sprite in enumerate(frames):
                atlas.paste(sprite.resize((FRAME,FRAME),Image.Resampling.NEAREST),
                            (column*FRAME,line*FRAME))
        atlas.save(ROOT/"population"/f"page_{page}.png",optimize=True)


if __name__ == "__main__":
    main()
