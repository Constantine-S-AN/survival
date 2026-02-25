#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Tuple

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
WEAPON_DATA = ROOT / "data" / "weapons.json"
WEAPON_DIR = ROOT / "assets" / "textures" / "pixel" / "weapons"
PARTS_DIR = WEAPON_DIR / "parts"
PREVIEW_PATH = ROOT / "tmp" / "preview" / "weapons_pixel_preview_36.png"

SIZE = 48
NEW_WEAPONS = [
    "catacomb_longbow",
    "rune_blunderbuss",
    "candle_mortar",
    "crypt_disc",
    "grave_bell",
    "ash_scythe",
    "wick_thrower",
    "reliquary_beam",
    "gargoyle_drone",
    "chain_spike",
    "dusk_censer",
    "tombbreaker_maul",
    "spectral_lantern",
    "hex_nailer",
    "idol_railgun",
    "briar_whip",
    "oath_pistol",
    "mirror_shard",
]

PALETTES: Dict[str, Tuple[Tuple[int, int, int, int], ...]] = {
    "catacomb_longbow": ((14, 14, 22, 255), (72, 68, 58, 255), (114, 102, 86, 255), (151, 210, 255, 255), (224, 240, 255, 255)),
    "rune_blunderbuss": ((12, 16, 25, 255), (80, 94, 118, 255), (126, 143, 171, 255), (255, 173, 114, 255), (255, 232, 180, 255)),
    "candle_mortar": ((14, 14, 20, 255), (64, 70, 92, 255), (112, 122, 150, 255), (255, 198, 120, 255), (255, 236, 189, 255)),
    "crypt_disc": ((13, 16, 27, 255), (65, 84, 114, 255), (108, 130, 164, 255), (120, 224, 255, 255), (219, 246, 255, 255)),
    "grave_bell": ((16, 16, 23, 255), (84, 73, 52, 255), (132, 114, 84, 255), (255, 210, 130, 255), (255, 243, 198, 255)),
    "ash_scythe": ((12, 13, 22, 255), (74, 84, 102, 255), (136, 153, 178, 255), (255, 147, 114, 255), (255, 222, 204, 255)),
    "wick_thrower": ((12, 16, 23, 255), (72, 83, 108, 255), (118, 133, 161, 255), (255, 126, 86, 255), (255, 221, 184, 255)),
    "reliquary_beam": ((12, 14, 24, 255), (78, 92, 124, 255), (126, 146, 182, 255), (144, 176, 255, 255), (225, 235, 255, 255)),
    "gargoyle_drone": ((12, 15, 24, 255), (74, 84, 102, 255), (116, 132, 156, 255), (132, 238, 255, 255), (222, 249, 255, 255)),
    "chain_spike": ((14, 13, 24, 255), (84, 92, 114, 255), (130, 144, 171, 255), (194, 142, 255, 255), (231, 216, 255, 255)),
    "dusk_censer": ((12, 16, 20, 255), (74, 88, 90, 255), (116, 142, 144, 255), (118, 255, 204, 255), (217, 255, 236, 255)),
    "tombbreaker_maul": ((14, 13, 20, 255), (84, 84, 98, 255), (139, 140, 164, 255), (255, 185, 146, 255), (255, 232, 213, 255)),
    "spectral_lantern": ((12, 16, 23, 255), (62, 84, 94, 255), (102, 132, 146, 255), (124, 255, 226, 255), (221, 255, 248, 255)),
    "hex_nailer": ((13, 13, 25, 255), (86, 86, 120, 255), (133, 132, 177, 255), (218, 146, 255, 255), (239, 221, 255, 255)),
    "idol_railgun": ((14, 15, 24, 255), (90, 92, 110, 255), (142, 146, 170, 255), (255, 217, 138, 255), (255, 243, 206, 255)),
    "briar_whip": ((12, 16, 20, 255), (64, 88, 66, 255), (107, 146, 98, 255), (162, 255, 154, 255), (229, 255, 214, 255)),
    "oath_pistol": ((12, 15, 23, 255), (84, 92, 114, 255), (130, 145, 169, 255), (255, 176, 150, 255), (255, 227, 210, 255)),
    "mirror_shard": ((12, 14, 26, 255), (72, 88, 124, 255), (113, 138, 176, 255), (134, 210, 255, 255), (224, 245, 255, 255)),
}


def blank() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def rect(d: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, c: Tuple[int, int, int, int]) -> None:
    d.rectangle((x, y, x + w - 1, y + h - 1), fill=c)


def outline(d: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, fill: Tuple[int, int, int, int], stroke: Tuple[int, int, int, int]) -> None:
    rect(d, x, y, w, h, stroke)
    if w > 2 and h > 2:
        rect(d, x + 1, y + 1, w - 2, h - 2, fill)


def px(img: Image.Image, x: int, y: int, c: Tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        img.putpixel((x, y), c)


def draw_weapon_parts(wid: str) -> tuple[Image.Image, Image.Image, Image.Image]:
    o, b, hi, acc, core = PALETTES[wid]
    wood = (118, 84, 52, 255)
    wood_hi = (160, 122, 76, 255)

    base = blank()
    mz = blank()
    c = blank()
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(mz)
    dc = ImageDraw.Draw(c)

    if wid == "catacomb_longbow":
        outline(db, 8, 10, 4, 28, b, o)
        outline(db, 31, 10, 4, 28, b, o)
        for y in range(12, 36):
            px(base, 12 + ((y - 12) // 6), y, hi)
            px(base, 30 - ((y - 12) // 6), y, hi)
        rect(db, 13, 23, 18, 2, wood)
        rect(db, 14, 24, 16, 1, wood_hi)
        rect(dm, 30, 22, 10, 4, acc)
        rect(dm, 33, 23, 5, 2, core)
        outline(dc, 21, 21, 6, 6, core, o)
        rect(dc, 22, 22, 2, 1, acc)

    elif wid == "rune_blunderbuss":
        outline(db, 7, 19, 22, 12, b, o)
        outline(db, 26, 21, 9, 8, hi, o)
        outline(db, 11, 31, 5, 11, wood, o)
        rect(db, 12, 34, 2, 6, wood_hi)
        outline(db, 10, 15, 10, 4, b, o)
        rect(db, 12, 16, 5, 1, hi)
        rect(dm, 34, 22, 8, 6, acc)
        rect(dm, 36, 23, 4, 2, core)
        for x in (31, 32, 33):
            px(mz, x, 24, acc)
        outline(dc, 19, 22, 6, 5, core, o)
        rect(dc, 20, 23, 3, 1, acc)

    elif wid == "candle_mortar":
        outline(db, 8, 26, 20, 8, b, o)
        outline(db, 16, 14, 10, 13, hi, o)
        outline(db, 19, 10, 4, 5, b, o)
        rect(db, 20, 11, 2, 2, acc)
        rect(dm, 19, 9, 4, 4, acc)
        outline(dm, 30, 22, 4, 6, acc, o)
        outline(dc, 19, 19, 4, 5, core, o)
        rect(dc, 20, 20, 2, 1, acc)

    elif wid == "crypt_disc":
        outline(db, 12, 12, 24, 24, b, o)
        outline(db, 16, 16, 16, 16, hi, o)
        for i in range(14, 34, 3):
            px(base, i, 24, acc)
            px(base, 24, i, acc)
        outline(dm, 34, 22, 7, 4, acc, o)
        rect(dm, 36, 23, 3, 1, core)
        outline(dc, 20, 20, 8, 8, core, o)
        rect(dc, 22, 21, 4, 1, acc)

    elif wid == "grave_bell":
        outline(db, 14, 11, 20, 19, b, o)
        outline(db, 18, 8, 12, 4, hi, o)
        rect(db, 24, 30, 2, 6, wood)
        rect(db, 24, 31, 1, 4, wood_hi)
        rect(dm, 20, 26, 8, 5, acc)
        rect(dm, 22, 27, 4, 2, core)
        outline(dc, 22, 18, 4, 5, core, o)
        rect(dc, 23, 19, 2, 1, acc)

    elif wid == "ash_scythe":
        outline(db, 9, 8, 4, 34, wood, o)
        rect(db, 10, 10, 2, 27, wood_hi)
        outline(db, 13, 11, 22, 10, hi, o)
        for x in range(16, 34):
            px(base, x, 12 + ((x - 16) // 3), acc)
        rect(dm, 30, 15, 9, 4, acc)
        rect(dm, 32, 16, 4, 1, core)
        outline(dc, 22, 14, 6, 4, core, o)

    elif wid == "wick_thrower":
        outline(db, 8, 19, 20, 11, b, o)
        outline(db, 13, 15, 8, 4, hi, o)
        outline(db, 11, 30, 5, 11, wood, o)
        rect(db, 12, 33, 2, 6, wood_hi)
        outline(db, 29, 18, 8, 13, hi, o)
        rect(dm, 35, 20, 7, 8, acc)
        rect(dm, 37, 22, 3, 2, core)
        outline(dc, 19, 22, 6, 5, core, o)

    elif wid == "reliquary_beam":
        outline(db, 7, 20, 25, 11, b, o)
        outline(db, 11, 16, 9, 4, hi, o)
        outline(db, 10, 31, 4, 12, wood, o)
        rect(db, 11, 34, 2, 7, wood_hi)
        outline(db, 19, 14, 8, 3, b, o)
        outline(dm, 32, 21, 10, 8, acc, o)
        rect(dm, 35, 23, 5, 3, core)
        outline(dc, 22, 22, 6, 6, core, o)
        rect(dc, 23, 23, 2, 1, acc)

    elif wid == "gargoyle_drone":
        outline(db, 15, 15, 18, 15, b, o)
        outline(db, 20, 19, 8, 7, hi, o)
        outline(db, 11, 19, 4, 6, b, o)
        outline(db, 33, 19, 4, 6, b, o)
        outline(db, 19, 11, 10, 4, b, o)
        outline(db, 19, 30, 10, 4, b, o)
        rect(dm, 13, 18, 2, 2, acc)
        rect(dm, 35, 18, 2, 2, acc)
        rect(dm, 21, 10, 2, 2, acc)
        rect(dm, 25, 10, 2, 2, acc)
        outline(dc, 21, 20, 6, 5, core, o)

    elif wid == "chain_spike":
        outline(db, 7, 21, 21, 10, b, o)
        outline(db, 11, 17, 9, 4, hi, o)
        outline(db, 11, 31, 4, 11, wood, o)
        rect(db, 12, 34, 2, 6, wood_hi)
        for x in range(28, 38, 2):
            rect(db, x, 24, 2, 2, hi)
        rect(dm, 38, 22, 5, 8, acc)
        px(mz, 42, 25, core)
        outline(dc, 20, 23, 5, 4, core, o)

    elif wid == "dusk_censer":
        outline(db, 17, 13, 14, 14, b, o)
        outline(db, 20, 16, 8, 8, hi, o)
        rect(db, 23, 27, 2, 11, wood)
        rect(db, 23, 28, 1, 8, wood_hi)
        rect(dm, 16, 26, 16, 2, acc)
        rect(dm, 20, 11, 2, 2, acc)
        rect(dm, 26, 11, 2, 2, acc)
        outline(dc, 22, 19, 4, 4, core, o)

    elif wid == "tombbreaker_maul":
        outline(db, 9, 9, 4, 33, wood, o)
        rect(db, 10, 11, 2, 26, wood_hi)
        outline(db, 13, 13, 23, 13, b, o)
        outline(db, 17, 16, 15, 7, hi, o)
        rect(dm, 31, 17, 8, 4, acc)
        rect(dm, 17, 24, 6, 2, acc)
        outline(dc, 22, 18, 5, 5, core, o)

    elif wid == "spectral_lantern":
        outline(db, 16, 12, 16, 18, b, o)
        outline(db, 20, 16, 8, 10, hi, o)
        outline(db, 19, 8, 10, 4, b, o)
        rect(db, 23, 30, 2, 9, wood)
        rect(dm, 18, 27, 12, 3, acc)
        rect(dm, 20, 10, 2, 2, acc)
        rect(dm, 26, 10, 2, 2, acc)
        outline(dc, 22, 20, 4, 4, core, o)

    elif wid == "hex_nailer":
        outline(db, 8, 20, 21, 10, b, o)
        outline(db, 13, 16, 8, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 34, 2, 6, wood_hi)
        rect(db, 29, 22, 8, 2, hi)
        rect(db, 30, 25, 7, 2, hi)
        rect(dm, 37, 22, 6, 5, acc)
        rect(dm, 39, 23, 3, 2, core)
        outline(dc, 19, 22, 6, 5, core, o)

    elif wid == "idol_railgun":
        outline(db, 6, 19, 27, 11, b, o)
        outline(db, 10, 15, 10, 4, hi, o)
        outline(db, 9, 30, 4, 13, wood, o)
        rect(db, 10, 34, 2, 7, wood_hi)
        outline(db, 27, 17, 10, 5, hi, o)
        rect(dm, 36, 20, 9, 8, acc)
        rect(dm, 38, 22, 5, 3, core)
        outline(dc, 21, 22, 7, 5, core, o)

    elif wid == "briar_whip":
        outline(db, 10, 26, 10, 4, wood, o)
        outline(db, 18, 24, 4, 7, b, o)
        for i in range(0, 16):
            x = 22 + i
            y = 24 - (i // 3)
            if i % 2 == 0:
                px(base, x, y, hi)
            else:
                px(base, x, y + 1, hi)
        rect(dm, 34, 18, 8, 4, acc)
        rect(dm, 36, 19, 4, 2, core)
        outline(dc, 26, 20, 5, 4, core, o)

    elif wid == "oath_pistol":
        outline(db, 11, 20, 16, 10, b, o)
        outline(db, 24, 22, 8, 6, hi, o)
        outline(db, 18, 30, 4, 10, wood, o)
        rect(db, 19, 33, 2, 5, wood_hi)
        outline(db, 14, 16, 8, 4, b, o)
        rect(dm, 31, 23, 7, 4, acc)
        rect(dm, 33, 24, 3, 2, core)
        outline(dc, 18, 22, 5, 4, core, o)

    elif wid == "mirror_shard":
        outline(db, 12, 16, 12, 16, b, o)
        outline(db, 21, 13, 12, 20, hi, o)
        outline(db, 28, 18, 10, 12, hi, o)
        rect(db, 15, 20, 6, 2, acc)
        rect(dm, 35, 21, 7, 7, acc)
        rect(dm, 37, 23, 3, 3, core)
        outline(dc, 22, 20, 6, 6, core, o)

    # add subtle shimmer details
    for x in range(8, 41):
        if x % 6 == 0:
            px(base, x, 18, (255, 255, 255, 26))
            px(base, x, 31, (0, 0, 0, 44))

    return base, mz, c


def save_weapon(wid: str) -> None:
    base, mz, core = draw_weapon_parts(wid)
    full = blank()
    full.alpha_composite(base)
    full.alpha_composite(mz)
    full.alpha_composite(core)
    WEAPON_DIR.mkdir(parents=True, exist_ok=True)
    PARTS_DIR.mkdir(parents=True, exist_ok=True)
    full.save(WEAPON_DIR / f"{wid}.png")
    base.save(PARTS_DIR / f"{wid}_base.png")
    mz.save(PARTS_DIR / f"{wid}_muzzle.png")
    core.save(PARTS_DIR / f"{wid}_core.png")


def build_preview() -> None:
    with WEAPON_DATA.open("r", encoding="utf-8") as f:
        data = json.load(f)
    weapon_ids = [str(k).strip() for k in data.keys() if str(k).strip()]
    cols = 6
    rows = max(1, (len(weapon_ids) + cols - 1) // cols)
    tile_w = 220
    tile_h = 108
    out = Image.new("RGBA", (tile_w * cols + 24, tile_h * rows + 54), (9, 12, 18, 255))
    d = ImageDraw.Draw(out)
    d.text((14, 12), "Weapon Pixel Preview (36 unique)", fill=(227, 233, 245, 255))
    for i, wid in enumerate(weapon_ids):
        col = i % cols
        row = i // cols
        x = 12 + col * tile_w
        y = 40 + row * tile_h
        d.rectangle((x, y, x + tile_w - 8, y + tile_h - 8), outline=(58, 64, 76, 220), width=1, fill=(7, 10, 16, 255))
        img_path = WEAPON_DIR / f"{wid}.png"
        if img_path.exists():
            img = Image.open(img_path).convert("RGBA").resize((80, 80), Image.NEAREST)
            out.alpha_composite(img, (x + 14, y + 8))
        d.text((x + 102, y + 44), wid, fill=(226, 232, 244, 255))

    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    out.save(PREVIEW_PATH)


def main() -> None:
    for wid in NEW_WEAPONS:
        save_weapon(wid)
    build_preview()
    print(f"generated {len(NEW_WEAPONS)} new weapon textures")
    print(PREVIEW_PATH)


if __name__ == "__main__":
    main()
