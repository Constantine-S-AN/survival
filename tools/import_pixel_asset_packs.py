#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Iterable, Tuple

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_CHAR_DIR = ROOT / "assets" / "textures" / "pixel" / "characters"
OUT_ENEMY_DIR = ROOT / "assets" / "textures" / "pixel" / "enemies"
OUT_WEAPON_DIR = ROOT / "assets" / "textures" / "pixel" / "weapons"

SRC = ROOT / "assets" / "source" / "pixel_packs"
SRC_PIPOYA = SRC / "pipoya" / "PIPOYA FREE RPG Character Sprites 32x32"
SRC_TINY_RPG = SRC / "tiny_rpg" / "Tiny RPG Character Asset Pack v1.03 -Free Soldier&Orc"
SRC_TINY_SWORDS = SRC / "tiny_swords" / "Tiny Swords (Free Pack)"
SRC_DUNGEON = SRC / "dungeon" / "2D Pixel Dungeon Asset Pack"

TARGET_SIZE = 48


def _load_json_dict(path: Path) -> Dict:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"Expected dict JSON in {path}")
    return data


def _ensure_dirs(paths: Iterable[Path]) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def _open_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _alpha_non_zero_count(img: Image.Image) -> int:
    alpha = img.getchannel("A")
    hist = alpha.histogram()
    if not hist:
        return 0
    total = sum(hist)
    return total - hist[0]


def _best_tile_from_sheet(sheet: Image.Image, tile_w: int, tile_h: int) -> Image.Image:
    best: Image.Image | None = None
    best_score = -1
    cols = max(1, sheet.width // tile_w)
    rows = max(1, sheet.height // tile_h)
    for row in range(rows):
        for col in range(cols):
            x = col * tile_w
            y = row * tile_h
            tile = sheet.crop((x, y, x + tile_w, y + tile_h))
            score = _alpha_non_zero_count(tile)
            if score > best_score:
                best_score = score
                best = tile
    if best is None:
        return sheet.copy()
    return best


def _trim_alpha(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    return img.crop(bbox)


def _compose_sticker(src: Image.Image, fit: int = 26, add_shadow: bool = True) -> Image.Image:
    trimmed = _trim_alpha(src)
    if trimmed.width <= 0 or trimmed.height <= 0:
        return Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))
    scale = min(float(fit) / float(trimmed.width), float(fit) / float(trimmed.height))
    out_w = max(1, int(round(trimmed.width * scale)))
    out_h = max(1, int(round(trimmed.height * scale)))
    resized = trimmed.resize((out_w, out_h), Image.NEAREST)
    canvas = Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))
    x = (TARGET_SIZE - out_w) // 2
    y = TARGET_SIZE - out_h - 2
    if add_shadow:
        shadow = Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(shadow)
        draw.rounded_rectangle(
            (x - 1, y + out_h - 2, x + out_w + 1, y + out_h + 1),
            radius=2,
            fill=(0, 0, 0, 72),
        )
        canvas.alpha_composite(shadow)
    canvas.paste(resized, (x, y), resized)
    return canvas


def _save_sticker(img: Image.Image, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def _tile_from_path(path: Path, tile_w: int, tile_h: int) -> Image.Image:
    sheet = _open_rgba(path)
    return _best_tile_from_sheet(sheet, tile_w, tile_h)


def _tiny_swords_unit(rel: str) -> Image.Image:
    return _tile_from_path(SRC_TINY_SWORDS / rel, 64, 64)


def _tiny_rpg_char(rel: str) -> Image.Image:
    return _tile_from_path(SRC_TINY_RPG / rel, 100, 100)


def _pipoya_enemy(filename: str) -> Image.Image:
    return _tile_from_path(SRC_PIPOYA / "Enemy" / filename, 32, 32)


def _pipoya_character(group: str, filename: str) -> Image.Image:
    return _tile_from_path(SRC_PIPOYA / group / filename, 32, 32)


def _dungeon_enemy(rel: str) -> Image.Image:
    return _open_rgba(SRC_DUNGEON / rel)


def _sword_tile(row: int, col: int) -> Image.Image:
    sheet = _open_rgba(SRC_TINY_SWORDS / "UI Elements" / "UI Elements" / "Swords" / "Swords.png")
    tile_size = 64
    x = col * tile_size
    y = row * tile_size
    return sheet.crop((x, y, x + tile_size, y + tile_size))


def _tiny_ui_icon(filename: str) -> Image.Image:
    return _open_rgba(SRC_TINY_SWORDS / "UI Elements" / "UI Elements" / "Icons" / filename)


def _new_px_canvas() -> Image.Image:
    return Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))


def _px(img: Image.Image, x: int, y: int, color: Tuple[int, int, int, int]) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def _rect(img: Image.Image, x: int, y: int, w: int, h: int, color: Tuple[int, int, int, int]) -> None:
    d = ImageDraw.Draw(img)
    d.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def _outline_rect(
    img: Image.Image,
    x: int,
    y: int,
    w: int,
    h: int,
    fill: Tuple[int, int, int, int],
    outline: Tuple[int, int, int, int],
) -> None:
    _rect(img, x, y, w, h, outline)
    _rect(img, x + 1, y + 1, max(1, w - 2), max(1, h - 2), fill)


def _draw_weapon_pixel(weapon_id: str) -> Image.Image:
    c_outline = (8, 11, 21, 255)
    c_outline_soft = (22, 30, 50, 255)
    c_dark = (64, 74, 96, 255)
    c_mid = (102, 116, 145, 255)
    c_mid2 = (124, 140, 171, 255)
    c_hi = (188, 205, 232, 255)
    c_hi2 = (224, 235, 250, 255)
    c_wood = (112, 74, 40, 255)
    c_wood_hi = (150, 108, 66, 255)
    c_orange = (255, 129, 96, 255)
    c_blue = (82, 123, 255, 255)
    c_cyan = (108, 232, 255, 255)
    c_magenta = (223, 112, 255, 255)
    c_gold = (233, 193, 102, 255)
    c_red = (226, 83, 101, 255)
    c_green = (95, 233, 112, 255)

    img = _new_px_canvas()
    body_top = 19
    body_h = 11

    def gun_base(accent: Tuple[int, int, int, int], muzzle: Tuple[int, int, int, int], stock: Tuple[int, int, int, int], scope: bool, long_barrel: bool) -> None:
        barrel_len = 24 if not long_barrel else 27
        receiver_x = 7
        receiver_w = 22
        _outline_rect(img, receiver_x, body_top, receiver_w, body_h, c_mid, c_outline)
        _outline_rect(img, receiver_x + receiver_w - 1, body_top + 1, barrel_len - receiver_w + 1, body_h - 2, c_mid2, c_outline)
        _outline_rect(img, receiver_x + barrel_len - 1, body_top + 2, 5, body_h - 4, muzzle, c_outline)
        _outline_rect(img, receiver_x + 7, body_top + body_h, 4, 12, c_wood, c_outline)
        _rect(img, receiver_x + 8, body_top + body_h + 2, 2, 7, c_wood_hi)

        _rect(img, receiver_x + 2, body_top + 1, 10, 2, c_hi)
        _rect(img, receiver_x + 13, body_top + 2, 9, 2, c_hi)
        _rect(img, receiver_x + 16, body_top + 5, 7, 1, c_hi2)
        _rect(img, receiver_x + 2, body_top + 7, receiver_w - 3, 1, c_dark)
        _px(img, receiver_x + 5, body_top + 5, accent)
        _px(img, receiver_x + 6, body_top + 5, accent)
        _px(img, receiver_x + 18, body_top + 4, accent)

        _outline_rect(img, receiver_x + 2, body_top - 3, 9, 3, c_dark, c_outline)
        _rect(img, receiver_x + 4, body_top - 2, 5, 1, c_hi)
        if scope:
            _outline_rect(img, receiver_x + 12, body_top - 5, 8, 3, c_mid2, c_outline)
            _rect(img, receiver_x + 14, body_top - 4, 4, 1, c_hi)

        for x in range(receiver_x + 1, receiver_x + barrel_len - 1):
            if (x + 1) % 6 == 0:
                _px(img, x, body_top + body_h - 2, c_outline_soft)

        _outline_rect(img, receiver_x - 2, body_top + 2, 3, body_h - 4, stock, c_outline)
        _rect(img, receiver_x - 1, body_top + 3, 1, body_h - 6, c_wood_hi)

    def gadget_core(shell: Tuple[int, int, int, int], center: Tuple[int, int, int, int], spark: Tuple[int, int, int, int]) -> None:
        _outline_rect(img, 16, 14, 16, 16, shell, c_outline)
        _outline_rect(img, 20, 18, 8, 8, center, c_outline)
        for x, y in [(14, 20), (34, 20), (14, 25), (34, 25), (20, 12), (25, 12), (20, 32), (25, 32)]:
            _outline_rect(img, x, y, 2, 2, spark, c_outline)
        _px(img, 21, 19, c_hi2)
        _px(img, 26, 23, c_hi2)

    if weapon_id == "needle_rifle":
        gun_base(c_cyan, c_blue, (118, 76, 44, 255), scope=True, long_barrel=True)
    elif weapon_id == "burst_smg":
        gun_base(c_green, c_green, (122, 84, 48, 255), scope=True, long_barrel=False)
        _outline_rect(img, 28, body_top - 2, 4, 3, c_mid2, c_outline)
    elif weapon_id == "silence_dart":
        gun_base(c_orange, c_orange, (104, 68, 36, 255), scope=False, long_barrel=True)
        _outline_rect(img, 33, body_top + 1, 7, 8, (198, 209, 227, 255), c_outline)
        _rect(img, 34, body_top + 2, 3, 1, c_hi2)
    elif weapon_id == "tether_beam":
        gun_base(c_blue, c_blue, (116, 77, 45, 255), scope=True, long_barrel=False)
        _outline_rect(img, 32, body_top + 2, 7, 4, c_cyan, c_outline)
        _rect(img, 33, body_top + 3, 4, 1, c_hi2)
    elif weapon_id == "shock_pulse":
        gadget_core(c_dark, c_magenta, c_cyan)
        _outline_rect(img, 18, 17, 12, 12, (49, 61, 84, 255), c_outline_soft)
        _outline_rect(img, 20, 19, 8, 8, c_red, c_outline)
        _rect(img, 21, 20, 4, 1, c_hi2)
    elif weapon_id == "abyss_mine":
        gadget_core((42, 50, 71, 255), (215, 183, 89, 255), c_gold)
        _outline_rect(img, 18, 16, 12, 12, (58, 68, 93, 255), c_outline)
        _outline_rect(img, 22, 20, 4, 4, c_gold, c_outline)
    elif weapon_id == "orbital_drone":
        _outline_rect(img, 16, 15, 16, 14, c_dark, c_outline)
        _outline_rect(img, 20, 19, 8, 6, c_cyan, c_outline)
        _outline_rect(img, 12, 19, 4, 6, c_mid2, c_outline)
        _outline_rect(img, 32, 19, 4, 6, c_mid2, c_outline)
        _outline_rect(img, 20, 11, 8, 4, c_mid2, c_outline)
        _outline_rect(img, 20, 29, 8, 4, c_mid2, c_outline)
        _rect(img, 22, 20, 3, 1, c_hi2)
    elif weapon_id == "sonar_blade":
        _outline_rect(img, 7, 24, 10, 4, c_wood, c_outline)
        _outline_rect(img, 16, 23, 3, 6, c_mid, c_outline)
        _outline_rect(img, 19, 20, 19, 10, (170, 201, 238, 255), c_outline)
        _rect(img, 21, 21, 11, 1, c_hi2)
        _rect(img, 24, 27, 9, 1, (108, 173, 236, 255))
        _outline_rect(img, 36, 21, 4, 8, c_orange, c_outline)
    else:
        _outline_rect(img, 14, 14, 20, 20, c_mid, c_outline)

    for x in range(5, 43):
        if x % 5 == 0:
            _px(img, x, 13, (255, 255, 255, 24))
            _px(img, x, 34, (0, 0, 0, 42))
    return img


def _build_character_textures(character_ids: Iterable[str]) -> None:
	source_map = {
		"diver": _tiny_rpg_char("Characters(100x100)/Soldier/Soldier/Soldier-Idle.png"),
		"arc_tech": _pipoya_character("Male", "Male 07-1.png"),
		"lancer": _pipoya_character("Soldier", "Soldier 02-1.png"),
		"drone_handler": _pipoya_character("Soldier", "Soldier 05-1.png"),
		"scavenger": _tiny_rpg_char("Characters(100x100)/Orc/Orc/Orc-Idle.png"),
	}
	fallback = _pipoya_character("Male", "Male 01-1.png")
	for character_id in character_ids:
		src = source_map.get(character_id, fallback)
		sticker = _compose_sticker(src, fit=44, add_shadow=True)
		_save_sticker(sticker, OUT_CHAR_DIR / f"{character_id}.png")


def _build_enemy_textures(enemy_ids: Iterable[str]) -> None:
    source_map = {
        "drifter": _pipoya_enemy("Enemy 01-1.png"),
        "sprinter": _pipoya_enemy("Enemy 03-1.png"),
        "shooter": _pipoya_enemy("Enemy 04-1.png"),
        "shielded": _tiny_swords_unit("Units/Yellow Units/Lancer/Lancer_Idle.png"),
        "splitter": _pipoya_enemy("Enemy 05-1.png"),
        "splitter_shard": _pipoya_enemy("Enemy 10-1.png"),
        "bloater": _pipoya_enemy("Enemy 18.png"),
        "summoner": _pipoya_enemy("Enemy 21.png"),
        "lurker": _pipoya_enemy("Enemy 14-1.png"),
        "leech": _pipoya_enemy("Enemy 06-1.png"),
        "magnetoid": _pipoya_enemy("Enemy 22.png"),
        "pursuer_stalker": _tiny_rpg_char("Characters(100x100)/Orc/Orc/Orc-Idle.png"),
        "drone_scout": _pipoya_enemy("Enemy 02-1.png"),
        "ink_mite": _pipoya_enemy("Enemy 11-1.png"),
        "rusher_eel": _pipoya_enemy("Enemy 20.png"),
    }
    fallback = _dungeon_enemy("Character_animation/monsters_idle/skull/v1/skull_v1_1.png")
    for enemy_id in enemy_ids:
        src = source_map.get(enemy_id, fallback)
        sticker = _compose_sticker(src, fit=40, add_shadow=True)
        _save_sticker(sticker, OUT_ENEMY_DIR / f"{enemy_id}.png")


def _build_weapon_textures(weapon_ids: Iterable[str]) -> None:
    for weapon_id in weapon_ids:
        src = _draw_weapon_pixel(weapon_id)
        sticker = _compose_sticker(src, fit=42, add_shadow=False)
        _save_sticker(sticker, OUT_WEAPON_DIR / f"{weapon_id}.png")


def _build_preview(character_ids: Iterable[str], enemy_ids: Iterable[str], weapon_ids: Iterable[str]) -> None:
    ids = [*character_ids, *enemy_ids, *weapon_ids]
    out = Image.new("RGBA", (1200, 760), (7, 11, 24, 255))
    draw = ImageDraw.Draw(out)
    x = 24
    y = 30
    row_height = 120
    col_gap = 170
    draw.text((24, 8), "characters", fill=(190, 225, 255, 255))
    for idx, entry_id in enumerate(character_ids):
        path = OUT_CHAR_DIR / f"{entry_id}.png"
        img = _open_rgba(path).resize((64, 64), Image.NEAREST)
        out.paste(img, (x, y), img)
        draw.text((x + 74, y + 20), entry_id, fill=(220, 235, 255, 255))
        x += col_gap
    draw.text((24, y + row_height - 10), "enemies", fill=(190, 225, 255, 255))
    x = 24
    y += row_height
    for idx, entry_id in enumerate(enemy_ids):
        path = OUT_ENEMY_DIR / f"{entry_id}.png"
        img = _open_rgba(path).resize((64, 64), Image.NEAREST)
        out.paste(img, (x, y), img)
        draw.text((x + 74, y + 20), entry_id, fill=(220, 235, 255, 255))
        x += col_gap
        if (idx + 1) % 3 == 0:
            x = 24
            y += row_height
    draw.text((24, y + row_height - 10), "weapons", fill=(190, 225, 255, 255))
    x = 24
    y += row_height
    for entry_id in weapon_ids:
        path = OUT_WEAPON_DIR / f"{entry_id}.png"
        img = _open_rgba(path).resize((64, 64), Image.NEAREST)
        out.paste(img, (x, y), img)
        draw.text((x + 74, y + 20), entry_id, fill=(220, 235, 255, 255))
        x += col_gap
    preview_path = ROOT / "tmp" / "pixel_asset_import_preview.png"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(preview_path)
    print(f"Preview generated: {preview_path}")


def main() -> None:
    _ensure_dirs([OUT_CHAR_DIR, OUT_ENEMY_DIR, OUT_WEAPON_DIR])
    characters_data = _load_json_dict(ROOT / "data" / "characters.json")
    enemy_data = _load_json_dict(ROOT / "data" / "enemies.json")
    weapon_data = _load_json_dict(ROOT / "data" / "weapons.json")
    character_ids = [str(entry.get("id", "")).strip() for entry in characters_data.get("characters", []) if isinstance(entry, dict)]
    enemy_ids = [str(k).strip() for k in enemy_data.keys()]
    weapon_ids = [str(k).strip() for k in weapon_data.keys()]
    _build_character_textures(character_ids)
    _build_enemy_textures(enemy_ids)
    _build_weapon_textures(weapon_ids)
    _build_preview(character_ids, enemy_ids, weapon_ids)
    print("Pixel asset import complete.")


if __name__ == "__main__":
    main()
