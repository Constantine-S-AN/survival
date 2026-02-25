#!/usr/bin/env python3
from __future__ import annotations

import random
from pathlib import Path
from typing import Iterable, Tuple

from PIL import Image, ImageDraw, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SRC_DUNGEON = ROOT / "assets" / "source" / "pixel_packs" / "dungeon" / "2D Pixel Dungeon Asset Pack" / "character and tileset" / "Dungeon_Tileset.png"
SRC_BUILDINGS = ROOT / "assets" / "source" / "pixel_packs" / "tiny_swords" / "Tiny Swords (Free Pack)" / "Buildings" / "Blue Buildings"
SRC_TILEMAP = ROOT / "assets" / "source" / "pixel_packs" / "tiny_swords" / "Tiny Swords (Free Pack)" / "Terrain" / "Tileset" / "Tilemap_color5.png"
OUT_MAP_DIR = ROOT / "assets" / "textures" / "pixel" / "maps"
OUT_PROP_DIR = OUT_MAP_DIR / "props"

TILE = 16
TARGET_TILE = 32


def _ensure_dirs() -> None:
    OUT_MAP_DIR.mkdir(parents=True, exist_ok=True)
    OUT_PROP_DIR.mkdir(parents=True, exist_ok=True)


def _crop_tile(sheet: Image.Image, x: int, y: int) -> Image.Image:
    return sheet.crop((x * TILE, y * TILE, (x + 1) * TILE, (y + 1) * TILE)).convert("RGBA")


def _crop_32(sheet: Image.Image, x: int, y: int) -> Image.Image:
    return sheet.crop((x * 32, y * 32, (x + 1) * 32, (y + 1) * 32)).convert("RGBA")


def _up2(tile: Image.Image) -> Image.Image:
    return tile.resize((TARGET_TILE, TARGET_TILE), Image.NEAREST)


def _grade(img: Image.Image, mul: Tuple[float, float, float], add: Tuple[int, int, int]) -> Image.Image:
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src = img.convert("RGBA")
    px = src.load()
    out_px = out.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            nr = max(0, min(255, int(r * mul[0] + add[0])))
            ng = max(0, min(255, int(g * mul[1] + add[1])))
            nb = max(0, min(255, int(b * mul[2] + add[2])))
            out_px[x, y] = (nr, ng, nb, a)
    return out


def _tile_floor(sheet: Image.Image, coords: Iterable[Tuple[int, int]], accent_coords: Iterable[Tuple[int, int]], size: Tuple[int, int], seed: int, grade_mul, grade_add) -> Image.Image:
    rng = random.Random(seed)
    coords_list = list(coords)
    accent_list = list(accent_coords)
    w, h = size
    cols = w // 32
    rows = h // 32
    canvas = Image.new("RGBA", (w, h), (9, 14, 28, 255))

    center_x = cols // 2
    center_y = rows // 2
    for gy in range(rows):
        for gx in range(cols):
            use_accent = False
            dx = abs(gx - center_x)
            dy = abs(gy - center_y)
            if (dx < 7 and 3 < dy < 9) or (dy < 6 and 8 < dx < 14):
                use_accent = rng.random() < 0.62
            elif rng.random() < 0.08:
                use_accent = True
            cx, cy = rng.choice(accent_list if use_accent else coords_list)
            tile = _crop_32(sheet, cx, cy)
            if rng.random() < 0.35:
                tile = ImageOps.mirror(tile)
            tile = _grade(tile, grade_mul, grade_add)
            canvas.alpha_composite(tile, (gx * 32, gy * 32))

    draw = ImageDraw.Draw(canvas)

    for x in range(0, w, 96):
        draw.rectangle((x, 0, x + 2, h), fill=(15, 25, 48, 44))
    for y in range(0, h, 96):
        draw.rectangle((0, y, w, y + 2), fill=(15, 25, 48, 44))

    for _ in range(240):
        px = rng.randint(0, w - 10)
        py = rng.randint(0, h - 10)
        color = (55 + rng.randint(0, 18), 102 + rng.randint(0, 24), 164 + rng.randint(0, 42), 36)
        draw.rectangle((px, py, px + rng.randint(2, 7), py + rng.randint(1, 3)), fill=color)

    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    border = 240
    vd.rectangle((0, 0, w, h), fill=(0, 0, 0, 0))
    vd.rectangle((0, 0, w, border), fill=(0, 0, 0, 72))
    vd.rectangle((0, h - border, w, h), fill=(0, 0, 0, 84))
    vd.rectangle((0, 0, border, h), fill=(0, 0, 0, 68))
    vd.rectangle((w - border, 0, w, h), fill=(0, 0, 0, 82))
    canvas.alpha_composite(vignette)
    return canvas


def _build_props(dungeon_sheet: Image.Image, terrain_sheet: Image.Image) -> None:
    house = Image.open(SRC_BUILDINGS / "House1.png").convert("RGBA")
    tower = Image.open(SRC_BUILDINGS / "Tower.png").convert("RGBA")
    barracks = Image.open(SRC_BUILDINGS / "Barracks.png").convert("RGBA")

    house = _grade(house, (0.56, 0.70, 1.22), (-14, -14, 10))
    tower = _grade(tower, (0.56, 0.70, 1.22), (-14, -14, 10))
    barracks = _grade(barracks, (0.54, 0.66, 1.16), (-16, -14, 8))

    house.save(OUT_PROP_DIR / "house_neon.png")
    tower.save(OUT_PROP_DIR / "tower_neon.png")
    barracks.save(OUT_PROP_DIR / "barracks_neon.png")

    crate = _crop_tile(dungeon_sheet, 0, 8).resize((64, 64), Image.NEAREST)
    crate = _grade(crate, (0.82, 0.9, 1.15), (-4, -2, 12))
    crate.save(OUT_PROP_DIR / "crate_metal.png")

    barrier = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    seg = _crop_tile(dungeon_sheet, 0, 5).resize((32, 32), Image.NEAREST)
    seg = _grade(seg, (0.62, 0.80, 1.24), (-14, -10, 16))
    for i in range(4):
        barrier.alpha_composite(seg, (i * 32, 0))
    draw_barrier = ImageDraw.Draw(barrier)
    draw_barrier.rectangle((0, 34, 127, 63), fill=(8, 13, 28, 196))
    barrier.save(OUT_PROP_DIR / "barrier_segment.png")

    hedge_chunk = terrain_sheet.crop((0, 0, 8 * 32, 6 * 32)).convert("RGBA")
    hedge_corner = terrain_sheet.crop((0, 8 * 32, 8 * 32, 12 * 32)).convert("RGBA")
    cliff_chunk = terrain_sheet.crop((10 * 32, 8 * 32, 18 * 32, 12 * 32)).convert("RGBA")
    hedge_strip = terrain_sheet.crop((0, 6 * 32, 8 * 32, 8 * 32)).convert("RGBA")
    cliff_strip = terrain_sheet.crop((10 * 32, 10 * 32, 18 * 32, 12 * 32)).convert("RGBA")

    hedge_chunk = _grade(hedge_chunk, (0.48, 0.65, 1.08), (-16, -14, 8))
    hedge_corner = _grade(hedge_corner, (0.48, 0.65, 1.08), (-16, -14, 8))
    hedge_strip = _grade(hedge_strip, (0.48, 0.65, 1.08), (-16, -14, 8))
    cliff_chunk = _grade(cliff_chunk, (0.56, 0.72, 1.10), (-12, -12, 8))
    cliff_strip = _grade(cliff_strip, (0.56, 0.72, 1.10), (-12, -12, 8))

    hedge_chunk.save(OUT_PROP_DIR / "terrain_hedge_chunk.png")
    hedge_corner.save(OUT_PROP_DIR / "terrain_hedge_corner.png")
    hedge_strip.save(OUT_PROP_DIR / "terrain_hedge_strip.png")
    cliff_chunk.save(OUT_PROP_DIR / "terrain_cliff_chunk.png")
    cliff_strip.save(OUT_PROP_DIR / "terrain_cliff_strip.png")


def main() -> None:
    _ensure_dirs()
    dungeon_sheet = Image.open(SRC_DUNGEON).convert("RGBA")
    terrain_sheet = Image.open(SRC_TILEMAP).convert("RGBA")

    floor_coords = [
        (10, 1), (11, 1), (12, 1), (13, 1), (14, 1), (15, 1), (16, 1), (17, 1),
        (10, 2), (11, 2), (12, 2), (13, 2), (14, 2), (15, 2), (16, 2), (17, 2),
        (10, 3), (11, 3), (12, 3), (13, 3), (14, 3), (15, 3), (16, 3), (17, 3),
        (10, 4), (11, 4), (12, 4), (13, 4), (14, 4), (15, 4), (16, 4), (17, 4),
        (10, 5), (11, 5), (12, 5), (13, 5), (14, 5), (15, 5), (16, 5), (17, 5),
        (10, 6), (11, 6), (12, 6), (13, 6), (14, 6), (15, 6), (16, 6), (17, 6),
        (10, 7), (11, 7), (12, 7), (13, 7), (14, 7), (15, 7), (16, 7), (17, 7),
    ]
    accent_coords = [
        (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
        (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
        (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
        (0, 5), (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
    ]

    trench = _tile_floor(
        terrain_sheet,
        floor_coords,
        accent_coords,
        (2048, 2048),
        3312,
        (0.46, 0.66, 1.12),
        (-18, -20, 4)
    )
    black_tide = _tile_floor(
        terrain_sheet,
        floor_coords,
        accent_coords,
        (2048, 2048),
        9187,
        (0.42, 0.60, 1.05),
        (-24, -24, 0)
    )

    trench = ImageEnhance.Contrast(trench).enhance(1.10)
    black_tide = ImageEnhance.Brightness(black_tide).enhance(0.86)
    black_tide = ImageEnhance.Contrast(black_tide).enhance(1.08)

    trench.save(OUT_MAP_DIR / "trench_floor.png")
    black_tide.save(OUT_MAP_DIR / "black_tide_floor.png")

    _build_props(dungeon_sheet, terrain_sheet)
    print("Generated map assets in", OUT_MAP_DIR)


if __name__ == "__main__":
    main()
