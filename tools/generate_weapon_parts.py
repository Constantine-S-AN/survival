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
PREVIEW_PATH = ROOT / "tmp" / "logs" / "m6_weapon_parts_preview.png"

SIZE = 48


def _blank() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def _rect(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, color: Tuple[int, int, int, int]) -> None:
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def _outline(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, fill: Tuple[int, int, int, int], stroke: Tuple[int, int, int, int]) -> None:
    _rect(draw, x, y, w, h, stroke)
    if w > 2 and h > 2:
        _rect(draw, x + 1, y + 1, w - 2, h - 2, fill)


def _line(draw: ImageDraw.ImageDraw, x1: int, y1: int, x2: int, y2: int, color: Tuple[int, int, int, int]) -> None:
    draw.line((x1, y1, x2, y2), fill=color, width=1)


def _palette(seed: str) -> Dict[str, Tuple[int, int, int, int]]:
    table = {
        "needle_rifle": ((16, 20, 34, 255), (88, 102, 132, 255), (120, 138, 170, 255), (78, 118, 255, 255), (128, 212, 255, 255)),
        "burst_smg": ((15, 21, 34, 255), (84, 99, 128, 255), (114, 132, 160, 255), (66, 220, 110, 255), (156, 255, 188, 255)),
        "silence_dart": ((17, 21, 34, 255), (110, 122, 150, 255), (148, 166, 198, 255), (255, 127, 98, 255), (255, 215, 180, 255)),
        "shock_pulse": ((16, 18, 32, 255), (61, 72, 104, 255), (104, 124, 166, 255), (236, 88, 152, 255), (255, 182, 214, 255)),
        "abyss_mine": ((18, 18, 28, 255), (55, 62, 91, 255), (102, 114, 150, 255), (226, 196, 96, 255), (250, 229, 156, 255)),
        "tether_beam": ((16, 20, 32, 255), (82, 96, 126, 255), (121, 138, 166, 255), (88, 142, 255, 255), (162, 220, 255, 255)),
        "orbital_drone": ((14, 18, 30, 255), (64, 78, 106, 255), (106, 122, 156, 255), (106, 208, 255, 255), (190, 236, 255, 255)),
        "sonar_blade": ((17, 18, 28, 255), (100, 116, 142, 255), (152, 176, 208, 255), (255, 172, 122, 255), (212, 236, 255, 255)),
        "flare_lance": ((18, 20, 30, 255), (84, 95, 121, 255), (132, 147, 179, 255), (255, 141, 92, 255), (255, 214, 174, 255)),
        "night_carbine": ((17, 20, 34, 255), (80, 95, 124, 255), (118, 133, 164, 255), (124, 255, 112, 255), (198, 255, 195, 255)),
        "pulse_emitter": ((15, 18, 28, 255), (58, 69, 97, 255), (102, 121, 158, 255), (106, 214, 255, 255), (188, 241, 255, 255)),
        "ion_repeater": ((16, 20, 36, 255), (78, 96, 125, 255), (118, 139, 170, 255), (116, 162, 255, 255), (188, 217, 255, 255)),
        "ember_pike": ((16, 18, 27, 255), (88, 98, 120, 255), (136, 150, 178, 255), (255, 101, 84, 255), (255, 201, 169, 255)),
        "frost_shard": ((15, 19, 32, 255), (76, 96, 126, 255), (120, 146, 182, 255), (122, 204, 255, 255), (208, 245, 255, 255)),
        "grav_harpoon": ((16, 19, 31, 255), (88, 103, 130, 255), (130, 145, 175, 255), (198, 118, 255, 255), (230, 204, 255, 255)),
        "prism_caster": ((15, 18, 28, 255), (56, 68, 96, 255), (95, 113, 150, 255), (226, 86, 168, 255), (255, 182, 232, 255)),
        "venom_sprayer": ((14, 20, 24, 255), (67, 85, 102, 255), (102, 126, 148, 255), (92, 236, 128, 255), (188, 255, 194, 255)),
        "echo_revolver": ((16, 18, 30, 255), (84, 94, 122, 255), (126, 136, 166, 255), (255, 122, 104, 255), (255, 206, 190, 255)),
    }
    dark, mid, light, accent, core = table.get(seed, table["needle_rifle"])
    return {"outline": dark, "body": mid, "light": light, "accent": accent, "core": core}


def _shape_by_weapon(weapon_id: str) -> str:
    mapping = {
        "needle_rifle": "rifle",
        "burst_smg": "smg",
        "silence_dart": "dart",
        "shock_pulse": "core",
        "abyss_mine": "mine",
        "tether_beam": "beam",
        "orbital_drone": "drone",
        "sonar_blade": "blade",
        "flare_lance": "lance",
        "night_carbine": "carbine",
        "pulse_emitter": "emitter",
        "ion_repeater": "repeater",
        "ember_pike": "pike",
        "frost_shard": "shard",
        "grav_harpoon": "harpoon",
        "prism_caster": "caster",
        "venom_sprayer": "sprayer",
        "echo_revolver": "revolver",
    }
    return mapping.get(weapon_id, "rifle")


def _draw_base(shape: str, pal: Dict[str, Tuple[int, int, int, int]]) -> Image.Image:
    img = _blank()
    d = ImageDraw.Draw(img)
    o = pal["outline"]
    body = pal["body"]
    hi = pal["light"]
    grip = (116, 80, 48, 255)
    grip_hi = (158, 116, 76, 255)

    if shape in {"rifle", "carbine", "smg", "dart", "lance", "repeater", "harpoon", "sprayer"}:
        length = 27 if shape in {"rifle", "lance", "harpoon"} else 24
        _outline(d, 7, 20, length, 10, body, o)
        _outline(d, 9, 31, 4, 12, grip, o)
        _rect(d, 10, 33, 2, 7, grip_hi)
        _outline(d, 10, 16, 8, 3, body, o)
        _rect(d, 11, 17, 5, 1, hi)
        _rect(d, 10, 22, 11, 2, hi)
        _rect(d, 20, 23, 8, 1, hi)
        if shape in {"carbine", "smg", "repeater", "sprayer"}:
            _outline(d, 18, 15, 8, 3, body, o)
            _rect(d, 20, 16, 4, 1, hi)
        if shape in {"harpoon", "lance"}:
            _outline(d, 4, 23, 3, 4, grip, o)
    elif shape in {"blade", "pike", "shard"}:
        _outline(d, 6, 26, 10, 4, grip, o)
        _outline(d, 15, 24, 4, 7, body, o)
        _outline(d, 19, 20, 18, 12, body, o)
        _rect(d, 21, 21, 11, 2, hi)
        _rect(d, 24, 27, 8, 2, pal["accent"])
        if shape == "pike":
            _line(d, 19, 26, 37, 22, hi)
        if shape == "shard":
            _rect(d, 35, 24, 2, 3, hi)
    elif shape in {"core", "mine", "drone", "emitter", "caster"}:
        _outline(d, 15, 14, 18, 18, body, o)
        _outline(d, 20, 19, 8, 8, hi, o)
        if shape == "mine":
            for p in [(22, 10), (22, 34), (11, 22), (33, 22)]:
                _outline(d, p[0], p[1], 3, 3, body, o)
        if shape == "drone":
            _outline(d, 10, 20, 5, 6, body, o)
            _outline(d, 33, 20, 5, 6, body, o)
            _outline(d, 20, 9, 8, 5, body, o)
            _outline(d, 20, 32, 8, 5, body, o)
    elif shape == "revolver":
        _outline(d, 9, 20, 19, 10, body, o)
        _outline(d, 20, 30, 4, 11, grip, o)
        _outline(d, 28, 22, 7, 5, body, o)
        _outline(d, 14, 16, 8, 3, body, o)
        _rect(d, 11, 22, 9, 2, hi)
    elif shape == "beam":
        _outline(d, 7, 20, 24, 10, body, o)
        _outline(d, 10, 31, 4, 12, grip, o)
        _outline(d, 31, 22, 8, 5, hi, o)
    else:
        _outline(d, 10, 18, 22, 12, body, o)

    return img


def _draw_muzzle(shape: str, pal: Dict[str, Tuple[int, int, int, int]]) -> Image.Image:
    img = _blank()
    d = ImageDraw.Draw(img)
    o = pal["outline"]
    acc = pal["accent"]
    core = pal["core"]

    if shape in {"rifle", "carbine", "smg", "repeater", "sprayer"}:
        _outline(d, 31, 22, 8, 6, acc, o)
        _rect(d, 33, 23, 4, 2, core)
    elif shape in {"dart", "lance", "harpoon"}:
        _outline(d, 33, 21, 8, 8, acc, o)
        _line(d, 38, 21, 42, 25, core)
        _line(d, 38, 29, 42, 25, core)
    elif shape in {"blade", "pike", "shard"}:
        _outline(d, 34, 22, 6, 8, acc, o)
    elif shape == "revolver":
        _outline(d, 33, 23, 6, 4, acc, o)
    elif shape == "beam":
        _outline(d, 36, 21, 6, 7, acc, o)
        _rect(d, 37, 23, 3, 2, core)
    elif shape in {"core", "mine", "drone", "emitter", "caster"}:
        for p in [(13, 21), (35, 21), (23, 12), (23, 34)]:
            _outline(d, p[0], p[1], 2, 2, acc, o)
    return img


def _draw_core(shape: str, pal: Dict[str, Tuple[int, int, int, int]]) -> Image.Image:
    img = _blank()
    d = ImageDraw.Draw(img)
    o = pal["outline"]
    core = pal["core"]
    acc = pal["accent"]

    if shape in {"rifle", "carbine", "smg", "dart", "lance", "repeater", "sprayer", "harpoon", "beam", "revolver"}:
        _outline(d, 19, 24, 5, 3, core, o)
        _rect(d, 20, 24, 2, 1, acc)
    elif shape in {"blade", "pike", "shard"}:
        _outline(d, 27, 24, 5, 3, core, o)
    elif shape in {"core", "mine", "drone", "emitter", "caster"}:
        _outline(d, 20, 19, 8, 8, core, o)
        _rect(d, 22, 20, 4, 2, acc)
    return img


def _weapon_ids_from_data() -> list[str]:
    with WEAPON_DATA.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return [str(k).strip() for k in data.keys() if str(k).strip()]


def _save_layers(weapon_id: str) -> None:
    pal = _palette(weapon_id)
    shape = _shape_by_weapon(weapon_id)
    base = _draw_base(shape, pal)
    muzzle = _draw_muzzle(shape, pal)
    core = _draw_core(shape, pal)
    full = _blank()
    full.alpha_composite(base)
    full.alpha_composite(muzzle)
    full.alpha_composite(core)
    full.save(WEAPON_DIR / f"{weapon_id}.png")
    base.save(PARTS_DIR / f"{weapon_id}_base.png")
    muzzle.save(PARTS_DIR / f"{weapon_id}_muzzle.png")
    core.save(PARTS_DIR / f"{weapon_id}_core.png")


def _build_preview(weapon_ids: list[str]) -> None:
    cols = 6
    rows = max(1, (len(weapon_ids) + cols - 1) // cols)
    tile_w = 220
    tile_h = 108
    out = Image.new("RGBA", (tile_w * cols + 24, tile_h * rows + 54), (6, 12, 28, 255))
    d = ImageDraw.Draw(out)
    d.text((12, 12), "Weapon Parts Preview (base+muzzle+core)", fill=(208, 228, 255, 255))
    for i, weapon_id in enumerate(weapon_ids):
        col = i % cols
        row = i // cols
        x = 12 + col * tile_w
        y = 40 + row * tile_h
        d.rectangle((x, y, x + tile_w - 8, y + tile_h - 8), outline=(52, 92, 150, 190), width=1, fill=(10, 18, 40, 255))
        full = Image.open(WEAPON_DIR / f"{weapon_id}.png").convert("RGBA").resize((80, 80), Image.NEAREST)
        base = Image.open(PARTS_DIR / f"{weapon_id}_base.png").convert("RGBA").resize((28, 28), Image.NEAREST)
        muzzle = Image.open(PARTS_DIR / f"{weapon_id}_muzzle.png").convert("RGBA").resize((28, 28), Image.NEAREST)
        core = Image.open(PARTS_DIR / f"{weapon_id}_core.png").convert("RGBA").resize((28, 28), Image.NEAREST)
        out.alpha_composite(full, (x + 14, y + 10))
        out.alpha_composite(base, (x + 106, y + 14))
        out.alpha_composite(muzzle, (x + 138, y + 14))
        out.alpha_composite(core, (x + 170, y + 14))
        d.text((x + 104, y + 46), "B M C", fill=(174, 208, 244, 255))
        d.text((x + 104, y + 70), weapon_id, fill=(218, 236, 255, 255))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    out.save(PREVIEW_PATH)


def main() -> None:
    WEAPON_DIR.mkdir(parents=True, exist_ok=True)
    PARTS_DIR.mkdir(parents=True, exist_ok=True)
    weapon_ids = _weapon_ids_from_data()
    for weapon_id in weapon_ids:
        _save_layers(weapon_id)
    _build_preview(weapon_ids)
    print(f"Generated weapon layers for {len(weapon_ids)} weapons.")
    print(PREVIEW_PATH)


if __name__ == "__main__":
    main()
