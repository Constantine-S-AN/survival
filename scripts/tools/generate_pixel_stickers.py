#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
CHAR_DIR = ROOT / "assets" / "textures" / "pixel" / "characters"
ENEMY_DIR = ROOT / "assets" / "textures" / "pixel" / "enemies"
WEAPON_DIR = ROOT / "assets" / "textures" / "pixel" / "weapons"

CHAR_IDS = ["diver", "arc_tech", "lancer", "drone_handler", "scavenger"]
ENEMY_IDS = [
    "drifter",
    "sprinter",
    "shooter",
    "shielded",
    "splitter",
    "splitter_shard",
    "bloater",
    "summoner",
    "lurker",
    "leech",
    "magnetoid",
    "pursuer_stalker",
    "drone_scout",
    "ink_mite",
    "rusher_eel",
]
WEAPON_IDS = [
    "needle_rifle",
    "burst_smg",
    "silence_dart",
    "shock_pulse",
    "abyss_mine",
    "tether_beam",
    "orbital_drone",
    "sonar_blade",
]


def ensure_dirs(paths: Iterable[Path]) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def fill_rect(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def save_character(character_id: str, idx: int) -> None:
    palettes = [
        ((28, 34, 64, 255), (66, 206, 255, 255), (167, 247, 255, 255)),
        ((34, 26, 62, 255), (174, 125, 255, 255), (233, 205, 255, 255)),
        ((38, 28, 48, 255), (255, 138, 85, 255), (255, 215, 182, 255)),
        ((22, 48, 52, 255), (84, 233, 174, 255), (183, 255, 226, 255)),
        ((52, 36, 22, 255), (255, 189, 80, 255), (255, 234, 172, 255)),
    ]
    bg, main, hi = palettes[idx % len(palettes)]
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    fill_rect(draw, 7, 7, 18, 18, bg)
    fill_rect(draw, 10, 6, 12, 2, hi)
    fill_rect(draw, 14, 2, 4, 4, hi)
    fill_rect(draw, 9, 10, 14, 14, main)
    fill_rect(draw, 13, 12, 6, 8, hi)
    fill_rect(draw, 11, 23, 3, 5, main)
    fill_rect(draw, 18, 23, 3, 5, main)
    fill_rect(draw, 8, 15, 2, 6, main)
    fill_rect(draw, 22, 15, 2, 6, main)
    img.save(CHAR_DIR / f"{character_id}.png")


def save_enemy(enemy_id: str, idx: int) -> None:
    base_palette = [
        ((36, 22, 30, 255), (255, 92, 125, 255), (255, 191, 210, 255)),
        ((20, 32, 50, 255), (90, 160, 255, 255), (182, 216, 255, 255)),
        ((34, 20, 22, 255), (255, 132, 91, 255), (255, 207, 179, 255)),
        ((24, 38, 26, 255), (90, 222, 132, 255), (188, 255, 212, 255)),
        ((42, 36, 20, 255), (255, 204, 86, 255), (255, 242, 186, 255)),
    ]
    bg, main, hi = base_palette[idx % len(base_palette)]
    img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    fill_rect(draw, 6, 5, 16, 3, bg)
    fill_rect(draw, 4, 8, 20, 14, bg)
    fill_rect(draw, 7, 10, 14, 10, main)
    fill_rect(draw, 10, 11, 3, 3, hi)
    fill_rect(draw, 15, 11, 3, 3, hi)
    fill_rect(draw, 12, 16, 4, 3, hi)
    if enemy_id in {"shielded", "pursuer_stalker", "drone_scout"}:
        draw.rectangle([2, 6, 25, 21], outline=(146, 229, 255, 255), width=1)
    if enemy_id in {"bloater", "splitter", "splitter_shard"}:
        fill_rect(draw, 3, 21, 22, 3, main)
    if enemy_id in {"lurker", "leech"}:
        fill_rect(draw, 9, 14, 10, 5, (16, 16, 26, 180))
    img.save(ENEMY_DIR / f"{enemy_id}.png")


def save_weapon(weapon_id: str) -> None:
    palettes = {
        "needle_rifle": ((28, 43, 61, 255), (117, 212, 255, 255), (219, 248, 255, 255)),
        "burst_smg": ((40, 30, 40, 255), (215, 142, 255, 255), (244, 219, 255, 255)),
        "silence_dart": ((24, 52, 46, 255), (104, 236, 193, 255), (200, 255, 236, 255)),
        "shock_pulse": ((52, 38, 20, 255), (255, 212, 92, 255), (255, 243, 192, 255)),
        "abyss_mine": ((54, 30, 26, 255), (255, 131, 108, 255), (255, 210, 193, 255)),
        "tether_beam": ((25, 38, 56, 255), (122, 171, 255, 255), (214, 231, 255, 255)),
        "orbital_drone": ((30, 36, 38, 255), (144, 220, 242, 255), (229, 249, 255, 255)),
        "sonar_blade": ((30, 30, 48, 255), (161, 178, 255, 255), (225, 233, 255, 255)),
    }
    bg, main, hi = palettes[weapon_id]
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    fill_rect(draw, 2, 2, 20, 20, bg)

    if weapon_id == "needle_rifle":
        fill_rect(draw, 4, 11, 14, 3, main)
        fill_rect(draw, 15, 10, 6, 2, hi)
        fill_rect(draw, 7, 14, 4, 4, main)
    elif weapon_id == "burst_smg":
        fill_rect(draw, 4, 10, 11, 4, main)
        fill_rect(draw, 12, 8, 5, 4, hi)
        fill_rect(draw, 7, 14, 4, 5, main)
        fill_rect(draw, 16, 10, 4, 2, hi)
    elif weapon_id == "silence_dart":
        fill_rect(draw, 4, 11, 13, 2, main)
        fill_rect(draw, 17, 10, 4, 4, hi)
        fill_rect(draw, 2, 10, 2, 4, hi)
    elif weapon_id == "shock_pulse":
        draw.ellipse([5, 5, 18, 18], outline=main, width=2)
        draw.ellipse([8, 8, 15, 15], outline=hi, width=1)
    elif weapon_id == "abyss_mine":
        draw.ellipse([6, 6, 17, 17], fill=main)
        fill_rect(draw, 11, 2, 2, 4, hi)
        fill_rect(draw, 2, 11, 4, 2, hi)
        fill_rect(draw, 18, 11, 4, 2, hi)
        fill_rect(draw, 11, 18, 2, 4, hi)
    elif weapon_id == "tether_beam":
        fill_rect(draw, 3, 10, 6, 4, main)
        fill_rect(draw, 9, 11, 12, 2, hi)
        fill_rect(draw, 17, 8, 2, 8, main)
    elif weapon_id == "orbital_drone":
        fill_rect(draw, 8, 8, 8, 8, main)
        fill_rect(draw, 4, 10, 4, 4, hi)
        fill_rect(draw, 16, 10, 4, 4, hi)
        fill_rect(draw, 10, 4, 4, 4, hi)
        fill_rect(draw, 10, 16, 4, 4, hi)
    elif weapon_id == "sonar_blade":
        fill_rect(draw, 11, 4, 2, 12, hi)
        fill_rect(draw, 8, 12, 8, 4, main)
        fill_rect(draw, 9, 16, 6, 3, main)

    draw.rectangle([2, 2, 21, 21], outline=(255, 255, 255, 20), width=1)
    img.save(WEAPON_DIR / f"{weapon_id}.png")


def main() -> None:
    ensure_dirs([CHAR_DIR, ENEMY_DIR, WEAPON_DIR])
    for idx, character_id in enumerate(CHAR_IDS):
        save_character(character_id, idx)
    for idx, enemy_id in enumerate(ENEMY_IDS):
        save_enemy(enemy_id, idx)
    for weapon_id in WEAPON_IDS:
        save_weapon(weapon_id)
    print("Pixel stickers generated.")


if __name__ == "__main__":
    main()
