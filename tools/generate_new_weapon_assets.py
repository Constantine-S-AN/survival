#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Dict, Tuple

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
WEAPON_DATA = ROOT / "data" / "weapons.json"
WEAPON_DIR = ROOT / "assets" / "textures" / "pixel" / "weapons"
PARTS_DIR = WEAPON_DIR / "parts"
PREVIEW_PATH = ROOT / "tmp" / "preview" / "weapons_pixel_preview_48_epic.png"

SIZE = 48
NEW_WEAPONS = [
    "needle_rifle",
    "burst_smg",
    "silence_dart",
    "shock_pulse",
    "abyss_mine",
    "tether_beam",
    "orbital_drone",
    "sonar_blade",
    "flare_lance",
    "night_carbine",
    "pulse_emitter",
    "ion_repeater",
    "ember_pike",
    "frost_shard",
    "grav_harpoon",
    "prism_caster",
    "venom_sprayer",
    "echo_revolver",
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
    "sunforged_colossus",
    "eclipse_requiem",
    "chrono_lance",
    "leviathan_bombard",
    "seraphim_swarm",
    "eclipse_glaive",
    "mythic_hailstorm",
    "thunder_sigil",
    "oracle_splitter",
    "abyssal_monolith",
    "starfall_engine",
    "ragnarok_twinfang",
]

PALETTES: Dict[str, Tuple[Tuple[int, int, int, int], ...]] = {
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
    "sunforged_colossus": ((14, 13, 20, 255), (94, 98, 120, 255), (152, 161, 188, 255), (255, 184, 110, 255), (255, 236, 186, 255)),
    "eclipse_requiem": ((12, 12, 24, 255), (80, 76, 112, 255), (132, 126, 176, 255), (210, 148, 255, 255), (243, 226, 255, 255)),
    "chrono_lance": ((12, 15, 24, 255), (80, 96, 126, 255), (134, 152, 186, 255), (152, 204, 255, 255), (228, 246, 255, 255)),
    "leviathan_bombard": ((15, 14, 20, 255), (78, 84, 106, 255), (130, 138, 166, 255), (255, 194, 126, 255), (255, 240, 192, 255)),
    "seraphim_swarm": ((12, 15, 22, 255), (82, 92, 114, 255), (132, 150, 180, 255), (164, 242, 255, 255), (235, 252, 255, 255)),
    "eclipse_glaive": ((13, 13, 21, 255), (86, 88, 112, 255), (152, 158, 186, 255), (255, 164, 188, 255), (255, 226, 234, 255)),
    "mythic_hailstorm": ((12, 15, 24, 255), (80, 94, 122, 255), (132, 152, 184, 255), (138, 226, 255, 255), (230, 250, 255, 255)),
    "thunder_sigil": ((12, 13, 24, 255), (84, 86, 124, 255), (136, 138, 186, 255), (188, 154, 255, 255), (236, 222, 255, 255)),
    "oracle_splitter": ((13, 14, 22, 255), (90, 96, 120, 255), (144, 152, 182, 255), (255, 206, 146, 255), (255, 238, 198, 255)),
    "abyssal_monolith": ((12, 15, 25, 255), (78, 92, 130, 255), (132, 154, 196, 255), (150, 194, 255, 255), (230, 244, 255, 255)),
    "starfall_engine": ((14, 14, 22, 255), (94, 90, 122, 255), (152, 146, 184, 255), (255, 220, 150, 255), (255, 245, 204, 255)),
    "ragnarok_twinfang": ((13, 13, 20, 255), (92, 90, 112, 255), (154, 150, 182, 255), (255, 168, 200, 255), (255, 228, 238, 255)),
}

with WEAPON_DATA.open("r", encoding="utf-8") as _weapon_data_file:
    WEAPON_META: Dict[str, Dict] = json.load(_weapon_data_file)

EPIC_SERIES: Dict[str, str] = {
    "sunforged_colossus": "sacred_relic",
    "oracle_splitter": "sacred_relic",
    "ragnarok_twinfang": "sacred_relic",
    "eclipse_requiem": "ritual_vessel",
    "thunder_sigil": "ritual_vessel",
    "eclipse_glaive": "ritual_vessel",
    "chrono_lance": "forbidden_arts",
    "mythic_hailstorm": "forbidden_arts",
    "abyssal_monolith": "forbidden_arts",
    "leviathan_bombard": "mecha_divine",
    "seraphim_swarm": "mecha_divine",
    "starfall_engine": "mecha_divine",
}

EPIC_SERIES_LABEL: Dict[str, str] = {
    "sacred_relic": "圣遗物",
    "ritual_vessel": "祭器",
    "forbidden_arts": "禁术",
    "mecha_divine": "机械神兵",
}

EPIC_PALETTE_OVERRIDES: Dict[str, Tuple[Tuple[int, int, int, int], ...]] = {
    "sunforged_colossus": ((18, 12, 8, 255), (116, 76, 28, 255), (182, 138, 66, 255), (255, 112, 48, 255), (255, 226, 140, 255)),
    "oracle_splitter": ((9, 18, 22, 255), (40, 90, 95, 255), (98, 172, 176, 255), (220, 186, 90, 255), (226, 245, 210, 255)),
    "ragnarok_twinfang": ((22, 8, 12, 255), (98, 42, 52, 255), (162, 86, 98, 255), (238, 64, 84, 255), (255, 174, 196, 255)),
    "eclipse_requiem": ((14, 9, 26, 255), (62, 42, 104, 255), (112, 84, 166, 255), (198, 118, 255, 255), (244, 206, 255, 255)),
    "thunder_sigil": ((9, 12, 26, 255), (38, 56, 130, 255), (82, 114, 214, 255), (246, 198, 72, 255), (255, 244, 160, 255)),
    "eclipse_glaive": ((12, 12, 20, 255), (66, 72, 98, 255), (142, 152, 188, 255), (242, 156, 196, 255), (255, 228, 242, 255)),
    "chrono_lance": ((10, 18, 24, 255), (42, 86, 110, 255), (82, 152, 176, 255), (130, 250, 255, 255), (222, 252, 255, 255)),
    "mythic_hailstorm": ((10, 16, 28, 255), (54, 82, 132, 255), (112, 154, 220, 255), (144, 222, 255, 255), (234, 250, 255, 255)),
    "abyssal_monolith": ((8, 16, 18, 255), (30, 70, 68, 255), (66, 126, 118, 255), (84, 242, 174, 255), (198, 255, 220, 255)),
    "leviathan_bombard": ((12, 20, 16, 255), (38, 92, 74, 255), (82, 154, 126, 255), (220, 168, 96, 255), (255, 232, 178, 255)),
    "seraphim_swarm": ((10, 16, 28, 255), (70, 96, 142, 255), (136, 178, 238, 255), (186, 242, 255, 255), (255, 252, 214, 255)),
    "starfall_engine": ((20, 10, 28, 255), (86, 52, 118, 255), (146, 106, 180, 255), (255, 168, 96, 255), (255, 236, 162, 255)),
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


def _seed32(text: str) -> int:
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    return int(digest[:8], 16)


def _palette_for_weapon(wid: str) -> Tuple[Tuple[int, int, int, int], ...]:
    return EPIC_PALETTE_OVERRIDES.get(wid, PALETTES[wid])


def _weapon_profile(wid: str, meta: Dict) -> str:
    attack_model = str(meta.get("attack_model", "projectile")).strip().lower()
    projectile_count = int(meta.get("projectile_count", 1))
    spread = float(meta.get("projectile_spread_deg", 0.0))
    attack_rate = float(meta.get("attack_rate", 1.0))
    weapon_range = float(meta.get("range", 640.0))
    burst_count = int(meta.get("burst_count", 1))

    if attack_model == "melee":
        if "whip" in wid:
            return "whip"
        if "scythe" in wid:
            return "scythe"
        if "maul" in wid:
            return "maul"
        if "pike" in wid or "glaive" in wid or "blade" in wid:
            return "blade"
        return "blade"
    if attack_model == "beam":
        return "beam"
    if attack_model == "mine":
        if "mortar" in wid or "bombard" in wid or "engine" in wid:
            return "launcher"
        return "mine"
    if attack_model == "pulse":
        if "bell" in wid or "lantern" in wid or "censer" in wid:
            return "totem"
        return "focus"
    if attack_model == "drone":
        return "drone"

    if "bow" in wid:
        return "bow"
    if "pistol" in wid or "revolver" in wid:
        return "pistol"
    if projectile_count >= 5 or spread >= 13.5:
        return "shotgun"
    if weapon_range >= 860.0 and burst_count <= 1:
        return "sniper"
    if burst_count >= 3 or attack_rate >= 4.6:
        return "smg"
    return "rifle"


def _apply_signature_overlays(
    base: Image.Image,
    muzzle: Image.Image,
    core_layer: Image.Image,
    signature_mode: str,
    palette: Tuple[Tuple[int, int, int, int], ...],
) -> None:
    o, _, hi, acc, core = palette
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(muzzle)
    dc = ImageDraw.Draw(core_layer)

    if signature_mode == "execution":
        for i in range(4):
            px(muzzle, 40 + i, 21 + (i % 2), acc)
            px(muzzle, 40 + i, 26 - (i % 2), acc)
        rect(dc, 18, 20, 2, 2, acc)
        rect(dc, 28, 26, 2, 2, acc)
    elif signature_mode == "sniper":
        rect(db, 14, 14, 15, 2, hi)
        rect(dm, 43, 23, 2, 1, core)
    elif signature_mode == "vanguard":
        outline(db, 31, 20, 6, 10, hi, o)
    elif signature_mode == "noise_drive":
        for i in range(3):
            rect(db, 20 + i * 4, 30, 2, 2, acc)
            rect(db, 21 + i * 4, 18, 1, 1, acc)
    elif signature_mode == "silence_focus":
        rect(db, 12, 23, 20, 1, hi)
        rect(dm, 37, 22, 3, 1, hi)
    elif signature_mode == "reveal_hunter":
        outline(dc, 21, 20, 7, 7, core, o)
        rect(dc, 23, 22, 3, 2, acc)
    elif signature_mode == "shield_breaker":
        px(muzzle, 44, 24, core)
        px(muzzle, 45, 23, core)
        px(muzzle, 45, 25, core)
    elif signature_mode == "swarm_breaker":
        for p in ((18, 16), (29, 16), (17, 30), (30, 30), (13, 24), (34, 24)):
            rect(dm, p[0], p[1], 2, 2, acc)
    elif signature_mode == "mark_burst":
        rect(dc, 20, 24, 8, 1, acc)
        rect(dc, 23, 21, 1, 8, acc)
    elif signature_mode == "elite_bane":
        for p in ((20, 16), (23, 14), (26, 16)):
            rect(dm, p[0], p[1], 2, 2, acc)
    elif signature_mode == "crit_echo":
        outline(dm, 35, 20, 4, 8, hi, o)
        outline(dm, 40, 20, 4, 8, hi, o)
    elif signature_mode == "finisher_cycle":
        for i in range(4):
            rect(dc, 18 + i * 3, 18 + (i % 2), 1, 1, acc)
            rect(dc, 18 + i * 3, 29 - (i % 2), 1, 1, acc)
    elif signature_mode == "kill_reset":
        rect(dc, 22, 19, 1, 10, acc)
        rect(dc, 19, 23, 8, 1, acc)
    elif signature_mode == "xp_echo":
        for p in ((19, 19), (27, 19), (19, 27), (27, 27)):
            rect(dc, p[0], p[1], 2, 2, acc)
    elif signature_mode == "skill_cool":
        outline(dc, 20, 20, 8, 8, hi, o)
        rect(dc, 24, 20, 1, 4, acc)


def _apply_profile_overlays(
    base: Image.Image,
    muzzle: Image.Image,
    core_layer: Image.Image,
    profile: str,
    seed: int,
    palette: Tuple[Tuple[int, int, int, int], ...],
) -> None:
    o, b, hi, acc, core = palette
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(muzzle)
    dc = ImageDraw.Draw(core_layer)
    stock_shift = (seed >> 3) % 3
    top_shift = (seed >> 6) % 2

    if profile == "sniper":
        rect(db, 9, 15 + top_shift, 17, 2, hi)
        outline(db, 3, 22, 5 + stock_shift, 6, b, o)
        rect(dm, 42, 22, 5, 3, acc)
    elif profile == "shotgun":
        outline(db, 11, 30, 6, 4, b, o)
        rect(db, 30, 20, 8, 2, hi)
        for i in range(3):
            px(muzzle, 38 + i, 22 + i, core)
    elif profile == "smg":
        rect(db, 18, 14, 8, 2, hi)
        outline(db, 7, 23, 4, 5, b, o)
        rect(dm, 37, 20, 4, 2, acc)
    elif profile == "pistol":
        outline(db, 14, 29, 3, 6, b, o)
        rect(dm, 35, 22, 4, 3, acc)
    elif profile == "rifle":
        rect(db, 10, 16, 9, 2, hi)
        rect(db, 26, 29, 5, 1, hi)
    elif profile == "beam":
        outline(dm, 34, 19, 9, 10, hi, o)
        rect(dm, 37, 23, 4, 2, core)
    elif profile == "launcher":
        outline(db, 20, 10, 6, 5, hi, o)
        rect(dm, 20, 9, 4, 2, acc)
    elif profile == "mine":
        for p in ((12, 12), (35, 12), (12, 35), (35, 35)):
            rect(dm, p[0], p[1], 2, 2, acc)
    elif profile == "focus":
        outline(db, 15, 15, 18, 18, b, o)
        rect(dc, 23, 23, 2, 2, acc)
    elif profile == "totem":
        rect(db, 23, 32, 2, 10, (126, 95, 60, 255))
        rect(dm, 18, 10, 12, 2, acc)
    elif profile == "drone":
        outline(db, 9, 20, 4, 8, b, o)
        outline(db, 35, 20, 4, 8, b, o)
        rect(dm, 10, 22, 2, 2, acc)
        rect(dm, 36, 22, 2, 2, acc)
    elif profile == "bow":
        db.line((8, 12, 8, 36), fill=hi, width=1)
        db.line((35, 12, 35, 36), fill=hi, width=1)
        db.line((8, 12, 35, 36), fill=acc, width=1)
        db.line((8, 36, 35, 12), fill=acc, width=1)
    elif profile == "whip":
        for i in range(12):
            px(base, 20 + i, 24 - (i // 3), hi if i % 2 == 0 else acc)
    elif profile == "scythe":
        db.line((12, 10, 12, 38), fill=(126, 95, 60, 255), width=1)
        outline(dm, 25, 10, 10, 6, hi, o)
    elif profile == "maul":
        outline(db, 14, 12, 18, 10, hi, o)
    elif profile == "blade":
        db.line((18, 24, 37, 18), fill=hi, width=1)
        db.line((18, 25, 37, 21), fill=acc, width=1)


def _apply_serial_mark(
    base: Image.Image,
    core_layer: Image.Image,
    wid: str,
    palette: Tuple[Tuple[int, int, int, int], ...],
) -> None:
    _, _, _, acc, core = palette
    serial = _seed32(wid)
    for i in range(6):
        bit = (serial >> i) & 1
        x = 12 + i * 3
        y = 31 + ((serial >> (i + 9)) & 1)
        px(base, x, y, core if bit == 1 else (18, 20, 28, 180))
    for i in range(3):
        x = 14 + ((serial >> (i * 5)) & 0x1F) % 22
        y = 17 + ((serial >> (i * 7 + 3)) & 0x0F) % 12
        px(base, x, y, (255, 255, 255, 44))
    px(core_layer, 23, 23, acc)


def _apply_epic_series_overlays(
    base: Image.Image,
    muzzle: Image.Image,
    core_layer: Image.Image,
    wid: str,
    palette: Tuple[Tuple[int, int, int, int], ...],
    seed: int,
) -> None:
    series = EPIC_SERIES.get(wid, "")
    if not series:
        return

    o, b, hi, acc, core = palette
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(muzzle)
    dc = ImageDraw.Draw(core_layer)

    if series == "sacred_relic":
        # Crown + winged reliquary silhouette.
        outline(db, 18, 8, 12, 4, hi, o)
        outline(db, 8, 18, 6, 6, hi, o)
        outline(db, 34, 18, 6, 6, hi, o)
        rect(dm, 20, 6, 2, 2, acc)
        rect(dm, 26, 6, 2, 2, acc)
        rect(dc, 23, 15, 2, 2, core)
    elif series == "ritual_vessel":
        # Ritual spikes, hanging seals, and incense arcs.
        outline(db, 6, 20, 4, 7, b, o)
        outline(db, 38, 20, 4, 7, b, o)
        for i in range(3):
            rect(dm, 16 + i * 7, 9 + (i % 2), 2, 3, acc)
            px(muzzle, 17 + i * 7, 13 + (i % 2), core)
        rect(dc, 21, 29, 6, 1, acc)
    elif series == "forbidden_arts":
        # Asymmetric void shards and unstable glyph ring.
        outline(db, 7, 14, 5, 9, hi, o)
        outline(db, 35, 27, 6, 8, hi, o)
        for p in ((13, 12), (33, 12), (12, 34), (34, 34), (23, 9), (23, 37)):
            rect(dm, p[0], p[1], 2, 2, acc)
        rect(dc, 20, 19, 8, 1, core)
    elif series == "mecha_divine":
        # Heavy armored shell, turbine vents, and hardpoint fins.
        outline(db, 5, 19, 7, 12, hi, o)
        outline(db, 34, 17, 9, 14, hi, o)
        rect(db, 14, 31, 18, 2, hi)
        rect(dm, 33, 22, 11, 2, acc)
        rect(dm, 33, 26, 11, 2, acc)
        rect(dc, 20, 21, 8, 6, core)

    jitter = (seed >> 5) & 1
    if jitter == 1:
        rect(dm, 10, 24, 2, 1, acc)
    else:
        rect(dm, 36, 24, 2, 1, acc)


def _apply_epic_unique_overrides(
    base: Image.Image,
    muzzle: Image.Image,
    core_layer: Image.Image,
    wid: str,
    palette: Tuple[Tuple[int, int, int, int], ...],
) -> None:
    if wid not in EPIC_SERIES:
        return

    o, b, hi, acc, core = palette
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(muzzle)
    dc = ImageDraw.Draw(core_layer)

    if wid == "sunforged_colossus":
        outline(db, 28, 16, 13, 14, hi, o)
        rect(dm, 40, 20, 7, 8, acc)
        rect(dm, 42, 22, 4, 4, core)
    elif wid == "eclipse_requiem":
        outline(db, 10, 8, 28, 28, b, o)
        outline(db, 14, 12, 20, 20, hi, o)
        rect(dc, 20, 20, 8, 8, core)
    elif wid == "chrono_lance":
        for x in range(34, 46):
            px(base, x, 24, hi if x < 42 else acc)
        px(base, 46, 23, core)
        px(base, 46, 25, core)
        rect(dm, 42, 20, 5, 8, acc)
    elif wid == "leviathan_bombard":
        outline(db, 6, 31, 20, 8, b, o)
        rect(db, 8, 33, 16, 2, hi)
        outline(dm, 30, 20, 16, 10, acc, o)
    elif wid == "seraphim_swarm":
        outline(db, 7, 16, 10, 16, hi, o)
        outline(db, 31, 16, 10, 16, hi, o)
        outline(db, 19, 8, 10, 8, hi, o)
        rect(dm, 8, 22, 3, 3, acc)
        rect(dm, 37, 22, 3, 3, acc)
    elif wid == "eclipse_glaive":
        db.line((10, 10, 10, 39), fill=(126, 95, 60, 255), width=1)
        outline(dm, 22, 8, 16, 8, hi, o)
        rect(dm, 30, 10, 7, 3, acc)
    elif wid == "mythic_hailstorm":
        for y in (18, 21, 24, 27, 30):
            rect(db, 30, y, 8, 1, hi)
        rect(dm, 37, 18, 9, 13, acc)
    elif wid == "thunder_sigil":
        outline(db, 9, 9, 30, 30, b, o)
        rect(dm, 14, 24, 20, 1, acc)
        rect(dm, 24, 14, 1, 20, acc)
        rect(dc, 21, 21, 6, 6, core)
    elif wid == "oracle_splitter":
        for p in ((38, 18), (38, 28), (43, 23)):
            rect(dm, p[0], p[1], 3, 3, acc)
        outline(db, 31, 18, 8, 12, hi, o)
    elif wid == "abyssal_monolith":
        outline(db, 18, 6, 12, 34, hi, o)
        outline(dm, 33, 19, 12, 10, acc, o)
        rect(dc, 21, 19, 6, 10, core)
    elif wid == "starfall_engine":
        outline(db, 8, 31, 24, 9, hi, o)
        rect(dm, 33, 20, 13, 9, acc)
        rect(dm, 38, 22, 6, 5, core)
    elif wid == "ragnarok_twinfang":
        outline(db, 30, 18, 10, 5, hi, o)
        outline(db, 30, 25, 10, 5, hi, o)
        rect(dm, 39, 20, 8, 9, acc)
        rect(dm, 42, 22, 4, 4, core)


def _draw_epic_masterpiece(
    wid: str,
    palette: Tuple[Tuple[int, int, int, int], ...],
) -> tuple[Image.Image, Image.Image, Image.Image]:
    o, b, hi, acc, core = palette
    wood = (120, 88, 54, 255)
    wood_hi = (166, 126, 80, 255)

    base = blank()
    mz = blank()
    c = blank()
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(mz)
    dc = ImageDraw.Draw(c)

    if wid == "sunforged_colossus":
        outline(db, 4, 20, 20, 12, b, o)
        outline(db, 20, 16, 19, 19, hi, o)
        outline(db, 29, 9, 10, 6, hi, o)
        rect(db, 8, 32, 4, 12, wood)
        rect(db, 9, 35, 2, 7, wood_hi)
        rect(dm, 39, 21, 8, 10, acc)
        rect(dm, 41, 24, 5, 4, core)
        rect(dm, 32, 7, 2, 2, acc)
        rect(dm, 35, 7, 2, 2, acc)
        outline(dc, 24, 22, 6, 7, core, o)
    elif wid == "oracle_splitter":
        outline(db, 8, 21, 15, 8, b, o)
        outline(db, 20, 17, 8, 16, hi, o)
        outline(db, 28, 19, 9, 5, hi, o)
        outline(db, 28, 26, 9, 5, hi, o)
        rect(db, 12, 29, 3, 12, wood)
        rect(db, 13, 32, 1, 7, wood_hi)
        for p in ((36, 21), (40, 23), (36, 27), (40, 25)):
            rect(dm, p[0], p[1], 3, 3, acc)
        rect(dm, 44, 24, 3, 2, core)
        outline(dc, 23, 22, 4, 6, core, o)
    elif wid == "ragnarok_twinfang":
        outline(db, 8, 20, 13, 10, b, o)
        rect(db, 10, 30, 4, 12, wood)
        rect(db, 11, 33, 2, 7, wood_hi)
        for i in range(10):
            px(base, 21 + i, 21 + (i // 2), hi)
            px(base, 21 + i, 28 - (i // 2), hi)
        for p in ((32, 21), (36, 18), (37, 29), (40, 24)):
            rect(dm, p[0], p[1], 3, 3, acc)
        rect(dm, 42, 23, 4, 3, core)
        outline(dc, 19, 22, 4, 5, core, o)
    elif wid == "eclipse_requiem":
        outline(db, 9, 8, 30, 30, b, o)
        outline(db, 14, 13, 20, 20, hi, o)
        outline(db, 20, 20, 8, 8, b, o)
        rect(db, 23, 38, 2, 7, wood)
        rect(db, 24, 40, 1, 4, wood_hi)
        for p in ((11, 23), (37, 23), (23, 11), (23, 37)):
            rect(dm, p[0], p[1], 2, 2, acc)
        rect(dm, 18, 18, 2, 2, acc)
        rect(dm, 29, 29, 2, 2, acc)
        outline(dc, 21, 21, 6, 6, core, o)
    elif wid == "thunder_sigil":
        outline(db, 10, 10, 28, 28, b, o)
        outline(db, 15, 15, 18, 18, hi, o)
        for p in ((24, 10), (24, 37), (10, 24), (37, 24)):
            rect(db, p[0], p[1], 2, 2, hi)
        rect(dm, 17, 23, 14, 2, acc)
        rect(dm, 23, 17, 2, 14, acc)
        rect(dm, 29, 14, 2, 6, acc)
        rect(dm, 16, 29, 2, 6, acc)
        outline(dc, 21, 21, 6, 6, core, o)
        rect(dc, 23, 20, 2, 1, acc)
    elif wid == "eclipse_glaive":
        outline(db, 8, 6, 4, 36, wood, o)
        rect(db, 9, 9, 2, 30, wood_hi)
        outline(db, 12, 8, 25, 9, hi, o)
        outline(db, 30, 16, 8, 12, hi, o)
        rect(db, 18, 19, 8, 2, b)
        for x in range(15, 37):
            if x % 2 == 0:
                px(base, x, 10 + ((x - 15) // 3), acc)
        rect(dm, 34, 12, 10, 6, acc)
        rect(dm, 37, 14, 4, 2, core)
        outline(dc, 23, 11, 5, 4, core, o)
    elif wid == "chrono_lance":
        outline(db, 6, 22, 19, 6, b, o)
        rect(db, 9, 28, 4, 12, wood)
        rect(db, 10, 31, 2, 7, wood_hi)
        outline(db, 22, 18, 8, 14, hi, o)
        for x in range(30, 44):
            px(base, x, 24, hi if x < 38 else acc)
        px(base, 44, 23, core)
        px(base, 44, 25, core)
        outline(dm, 20, 16, 12, 12, acc, o)
        rect(dm, 42, 22, 5, 5, acc)
        rect(dm, 43, 23, 3, 2, core)
        outline(dc, 24, 22, 4, 4, core, o)
    elif wid == "mythic_hailstorm":
        outline(db, 5, 13, 5, 22, b, o)
        outline(db, 38, 13, 5, 22, b, o)
        db.line((10, 14, 42, 34), fill=hi, width=1)
        db.line((10, 34, 42, 14), fill=hi, width=1)
        rect(db, 13, 23, 26, 2, wood)
        rect(db, 15, 24, 22, 1, wood_hi)
        for p in ((20, 17), (25, 15), (30, 17), (20, 29), (25, 31), (30, 29)):
            rect(dm, p[0], p[1], 3, 3, acc)
        rect(dm, 36, 22, 10, 4, acc)
        rect(dm, 39, 23, 4, 2, core)
        outline(dc, 22, 21, 6, 6, core, o)
    elif wid == "abyssal_monolith":
        outline(db, 15, 6, 18, 36, b, o)
        outline(db, 19, 10, 10, 28, hi, o)
        rect(db, 21, 40, 6, 2, b)
        for p in ((17, 8), (30, 8), (17, 37), (30, 37)):
            rect(dm, p[0], p[1], 2, 2, acc)
        outline(dm, 33, 19, 12, 11, acc, o)
        rect(dm, 37, 22, 6, 4, core)
        outline(dc, 22, 20, 4, 8, core, o)
    elif wid == "leviathan_bombard":
        outline(db, 5, 23, 24, 11, b, o)
        outline(db, 17, 13, 11, 11, hi, o)
        rect(db, 8, 34, 4, 10, wood)
        rect(db, 9, 37, 2, 5, wood_hi)
        outline(db, 27, 18, 8, 7, hi, o)
        rect(db, 26, 27, 9, 2, hi)
        outline(dm, 33, 20, 14, 12, acc, o)
        rect(dm, 37, 23, 7, 5, core)
        rect(dm, 19, 10, 4, 3, acc)
        outline(dc, 20, 18, 4, 6, core, o)
    elif wid == "seraphim_swarm":
        outline(db, 18, 18, 12, 12, b, o)
        outline(db, 8, 18, 8, 12, hi, o)
        outline(db, 32, 18, 8, 12, hi, o)
        outline(db, 19, 8, 10, 8, hi, o)
        outline(db, 19, 32, 10, 8, hi, o)
        rect(db, 23, 30, 2, 10, wood)
        rect(db, 24, 33, 1, 6, wood_hi)
        for p in ((11, 20), (35, 20), (22, 11), (25, 11), (22, 35), (25, 35)):
            rect(dm, p[0], p[1], 3, 3, acc)
        outline(dc, 22, 22, 4, 4, core, o)
    elif wid == "starfall_engine":
        outline(db, 9, 24, 24, 10, b, o)
        outline(db, 16, 12, 12, 12, hi, o)
        outline(db, 12, 8, 20, 4, hi, o)
        rect(db, 12, 34, 4, 10, wood)
        rect(db, 13, 37, 2, 5, wood_hi)
        rect(db, 33, 22, 6, 14, hi)
        rect(dm, 32, 20, 15, 12, acc)
        rect(dm, 37, 23, 8, 5, core)
        rect(dm, 20, 7, 4, 3, acc)
        outline(dc, 20, 17, 5, 7, core, o)

    return base, mz, c


def _enhance_weapon_parts(
    wid: str,
    base: Image.Image,
    muzzle: Image.Image,
    core_layer: Image.Image,
    palette: Tuple[Tuple[int, int, int, int], ...],
) -> None:
    meta = WEAPON_META.get(wid, {})
    signature_mode = str(meta.get("signature_mode", "")).strip().lower()
    profile = _weapon_profile(wid, meta)
    seed = _seed32(wid)
    if wid not in EPIC_SERIES:
        _apply_profile_overlays(base, muzzle, core_layer, profile, seed, palette)
    _apply_signature_overlays(base, muzzle, core_layer, signature_mode, palette)
    _apply_epic_series_overlays(base, muzzle, core_layer, wid, palette, seed)
    _apply_epic_unique_overrides(base, muzzle, core_layer, wid, palette)
    _apply_serial_mark(base, core_layer, wid, palette)


def draw_weapon_parts(wid: str) -> tuple[Image.Image, Image.Image, Image.Image]:
    o, b, hi, acc, core = _palette_for_weapon(wid)
    wood = (118, 84, 52, 255)
    wood_hi = (160, 122, 76, 255)

    base = blank()
    mz = blank()
    c = blank()
    db = ImageDraw.Draw(base)
    dm = ImageDraw.Draw(mz)
    dc = ImageDraw.Draw(c)

    if wid in EPIC_SERIES:
        base, mz, c = _draw_epic_masterpiece(wid, (o, b, hi, acc, core))
        _enhance_weapon_parts(wid, base, mz, c, (o, b, hi, acc, core))
        for x in range(8, 41):
            if x % 6 == 0:
                px(base, x, 18, (255, 255, 255, 26))
                px(base, x, 31, (0, 0, 0, 44))
        return base, mz, c

    if wid == "needle_rifle":
        outline(db, 6, 20, 25, 10, b, o)
        outline(db, 10, 16, 9, 4, hi, o)
        outline(db, 9, 30, 4, 12, wood, o)
        rect(db, 10, 33, 2, 7, wood_hi)
        outline(db, 29, 21, 9, 6, hi, o)
        rect(db, 31, 22, 5, 1, acc)
        rect(dm, 37, 22, 9, 5, acc)
        rect(dm, 40, 23, 4, 2, core)
        outline(dc, 20, 22, 6, 4, core, o)
        rect(dc, 22, 23, 2, 1, acc)

    elif wid == "burst_smg":
        outline(db, 8, 19, 18, 11, b, o)
        outline(db, 12, 15, 8, 4, hi, o)
        outline(db, 10, 30, 5, 11, wood, o)
        rect(db, 11, 33, 2, 6, wood_hi)
        outline(db, 24, 18, 8, 6, hi, o)
        rect(db, 25, 25, 5, 2, hi)
        rect(dm, 31, 21, 8, 6, acc)
        rect(dm, 34, 22, 4, 2, core)
        rect(dm, 36, 19, 4, 2, acc)
        outline(dc, 18, 22, 5, 4, core, o)

    elif wid == "silence_dart":
        outline(db, 7, 22, 15, 5, b, o)
        outline(db, 5, 20, 4, 9, hi, o)
        rect(db, 9, 23, 12, 1, hi)
        for x in range(22, 38):
            px(base, x, 24, hi if x < 33 else acc)
        px(base, 38, 24, core)
        px(base, 39, 23, core)
        px(base, 39, 25, core)
        rect(dm, 33, 21, 7, 7, acc)
        rect(dm, 36, 23, 3, 2, core)
        outline(dc, 15, 22, 4, 4, core, o)

    elif wid == "shock_pulse":
        outline(db, 11, 11, 26, 26, b, o)
        outline(db, 15, 15, 18, 18, hi, o)
        outline(db, 18, 18, 12, 12, b, o)
        for x in range(9, 40, 3):
            px(base, x, 24, acc)
        for y in range(9, 40, 3):
            px(base, 24, y, acc)
        rect(dm, 10, 10, 2, 2, acc)
        rect(dm, 36, 10, 2, 2, acc)
        rect(dm, 10, 36, 2, 2, acc)
        rect(dm, 36, 36, 2, 2, acc)
        outline(dc, 20, 20, 8, 8, core, o)
        rect(dc, 22, 21, 4, 1, acc)

    elif wid == "abyss_mine":
        outline(db, 14, 14, 20, 20, b, o)
        outline(db, 18, 18, 12, 12, hi, o)
        for p in ((22, 8), (22, 36), (8, 22), (36, 22), (29, 10), (10, 29)):
            outline(db, p[0], p[1], 3, 3, b, o)
        rect(dm, 16, 11, 2, 2, acc)
        rect(dm, 32, 18, 2, 2, acc)
        rect(dm, 14, 33, 2, 2, acc)
        rect(dm, 29, 36, 2, 2, acc)
        outline(dc, 21, 21, 6, 6, core, o)
        rect(dc, 23, 22, 2, 1, acc)

    elif wid == "tether_beam":
        outline(db, 6, 20, 24, 10, b, o)
        outline(db, 10, 16, 9, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 33, 2, 7, wood_hi)
        outline(db, 25, 17, 11, 6, hi, o)
        rect(db, 28, 18, 5, 1, acc)
        rect(dm, 35, 20, 11, 9, acc)
        rect(dm, 39, 23, 5, 3, core)
        px(mz, 34, 24, core)
        px(mz, 33, 23, core)
        px(mz, 33, 25, core)
        outline(dc, 21, 22, 6, 5, core, o)

    elif wid == "orbital_drone":
        outline(db, 14, 14, 20, 20, b, o)
        outline(db, 19, 19, 10, 10, hi, o)
        outline(db, 10, 20, 4, 8, b, o)
        outline(db, 34, 20, 4, 8, b, o)
        outline(db, 20, 10, 8, 4, b, o)
        outline(db, 20, 34, 8, 4, b, o)
        rect(dm, 11, 22, 2, 2, acc)
        rect(dm, 35, 22, 2, 2, acc)
        rect(dm, 22, 11, 2, 2, acc)
        rect(dm, 25, 11, 2, 2, acc)
        rect(dm, 22, 35, 2, 2, acc)
        rect(dm, 25, 35, 2, 2, acc)
        outline(dc, 21, 21, 6, 6, core, o)

    elif wid == "sonar_blade":
        outline(db, 8, 26, 10, 4, wood, o)
        outline(db, 16, 24, 4, 7, b, o)
        outline(db, 20, 19, 18, 13, hi, o)
        rect(db, 23, 20, 10, 2, acc)
        rect(db, 25, 27, 8, 2, acc)
        rect(dm, 35, 23, 8, 7, acc)
        rect(dm, 38, 24, 3, 2, core)
        outline(dc, 27, 24, 5, 4, core, o)

    elif wid == "flare_lance":
        outline(db, 6, 22, 18, 6, b, o)
        outline(db, 23, 20, 12, 10, hi, o)
        outline(db, 10, 28, 4, 11, wood, o)
        rect(db, 11, 31, 2, 6, wood_hi)
        for x in range(34, 43):
            px(base, x, 24, hi if x < 39 else acc)
        px(base, 43, 24, core)
        rect(dm, 39, 22, 8, 5, acc)
        rect(dm, 42, 23, 3, 2, core)
        outline(dc, 19, 22, 5, 4, core, o)

    elif wid == "night_carbine":
        outline(db, 7, 20, 23, 10, b, o)
        outline(db, 11, 16, 8, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 33, 2, 7, wood_hi)
        outline(db, 26, 18, 9, 6, hi, o)
        rect(db, 27, 25, 6, 1, hi)
        rect(dm, 34, 21, 9, 6, acc)
        rect(dm, 37, 22, 4, 2, core)
        rect(dm, 39, 19, 3, 2, acc)
        outline(dc, 20, 22, 6, 4, core, o)

    elif wid == "pulse_emitter":
        outline(db, 13, 13, 22, 22, b, o)
        outline(db, 17, 17, 14, 14, hi, o)
        outline(db, 20, 20, 8, 8, b, o)
        rect(dm, 12, 23, 2, 2, acc)
        rect(dm, 34, 23, 2, 2, acc)
        rect(dm, 23, 12, 2, 2, acc)
        rect(dm, 23, 34, 2, 2, acc)
        rect(dm, 29, 16, 2, 2, acc)
        rect(dm, 17, 30, 2, 2, acc)
        outline(dc, 21, 21, 6, 6, core, o)
        rect(dc, 23, 22, 2, 1, acc)

    elif wid == "ion_repeater":
        outline(db, 7, 20, 24, 10, b, o)
        outline(db, 11, 16, 9, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 33, 2, 7, wood_hi)
        outline(db, 25, 17, 9, 6, hi, o)
        rect(db, 26, 24, 7, 1, hi)
        rect(dm, 34, 21, 10, 7, acc)
        rect(dm, 38, 23, 4, 2, core)
        px(mz, 32, 23, acc)
        px(mz, 32, 25, acc)
        outline(dc, 21, 22, 6, 4, core, o)

    elif wid == "ember_pike":
        outline(db, 6, 24, 14, 4, wood, o)
        outline(db, 18, 22, 4, 8, b, o)
        for x in range(22, 40):
            px(base, x, 25 - ((x - 22) // 5), hi if x < 34 else acc)
        px(base, 40, 21, core)
        px(base, 41, 22, core)
        px(base, 41, 20, core)
        rect(dm, 36, 19, 8, 4, acc)
        rect(dm, 39, 20, 3, 2, core)
        outline(dc, 24, 22, 5, 4, core, o)

    elif wid == "frost_shard":
        outline(db, 8, 20, 19, 10, b, o)
        outline(db, 12, 16, 8, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 33, 2, 7, wood_hi)
        for p in ((29, 19), (33, 17), (34, 24), (31, 28), (37, 22)):
            rect(db, p[0], p[1], 4, 4, hi)
        rect(dm, 36, 20, 8, 8, acc)
        rect(dm, 39, 23, 3, 2, core)
        outline(dc, 20, 22, 6, 5, core, o)

    elif wid == "grav_harpoon":
        outline(db, 7, 20, 22, 10, b, o)
        outline(db, 11, 16, 8, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 33, 2, 7, wood_hi)
        outline(db, 28, 21, 6, 6, hi, o)
        for x in range(34, 41):
            px(base, x, 24, hi if x < 38 else acc)
        px(base, 41, 24, core)
        px(base, 42, 23, core)
        px(base, 42, 25, core)
        rect(dm, 37, 21, 8, 6, acc)
        rect(dm, 40, 23, 3, 2, core)
        outline(dc, 20, 22, 6, 4, core, o)

    elif wid == "prism_caster":
        outline(db, 10, 24, 10, 4, wood, o)
        outline(db, 18, 12, 4, 20, b, o)
        outline(db, 22, 16, 14, 14, hi, o)
        rect(db, 25, 19, 8, 2, acc)
        rect(db, 25, 25, 8, 2, acc)
        rect(dm, 34, 20, 8, 6, acc)
        rect(dm, 37, 22, 4, 2, core)
        rect(dm, 22, 14, 2, 2, acc)
        rect(dm, 34, 14, 2, 2, acc)
        outline(dc, 25, 20, 6, 6, core, o)

    elif wid == "venom_sprayer":
        outline(db, 8, 19, 20, 11, b, o)
        outline(db, 13, 15, 8, 4, hi, o)
        outline(db, 11, 30, 5, 11, wood, o)
        rect(db, 12, 33, 2, 6, wood_hi)
        outline(db, 28, 19, 8, 11, hi, o)
        rect(db, 30, 21, 5, 2, acc)
        rect(dm, 35, 20, 8, 8, acc)
        rect(dm, 38, 23, 3, 2, core)
        px(mz, 43, 23, acc)
        px(mz, 44, 22, acc)
        px(mz, 44, 24, acc)
        outline(dc, 19, 22, 6, 5, core, o)

    elif wid == "echo_revolver":
        outline(db, 10, 20, 18, 10, b, o)
        outline(db, 14, 16, 8, 4, hi, o)
        outline(db, 19, 30, 4, 11, wood, o)
        rect(db, 20, 33, 2, 6, wood_hi)
        outline(db, 28, 22, 8, 6, hi, o)
        rect(db, 30, 24, 4, 1, acc)
        rect(dm, 35, 22, 8, 5, acc)
        rect(dm, 37, 23, 4, 2, core)
        rect(dm, 40, 20, 3, 2, acc)
        outline(dc, 20, 22, 5, 4, core, o)

    elif wid == "catacomb_longbow":
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

    elif wid == "sunforged_colossus":
        outline(db, 6, 18, 24, 13, b, o)
        outline(db, 10, 14, 10, 4, hi, o)
        outline(db, 10, 31, 5, 13, wood, o)
        rect(db, 11, 35, 2, 7, wood_hi)
        outline(db, 29, 19, 11, 11, hi, o)
        rect(db, 31, 21, 7, 2, acc)
        rect(db, 31, 25, 7, 2, acc)
        rect(dm, 39, 21, 8, 7, acc)
        rect(dm, 41, 23, 4, 3, core)
        outline(dc, 21, 21, 7, 6, core, o)

    elif wid == "eclipse_requiem":
        outline(db, 13, 11, 22, 21, b, o)
        outline(db, 18, 16, 12, 11, hi, o)
        outline(db, 18, 8, 12, 4, b, o)
        rect(db, 24, 32, 2, 7, wood)
        rect(db, 24, 33, 1, 5, wood_hi)
        for x in (14, 16, 33, 35):
            rect(dm, x, 20, 2, 2, acc)
        for y in (12, 30):
            rect(dm, 23, y, 2, 2, acc)
            rect(dm, 26, y, 2, 2, acc)
        outline(dc, 22, 19, 6, 6, core, o)
        rect(dc, 23, 20, 3, 1, acc)

    elif wid == "chrono_lance":
        outline(db, 7, 20, 24, 10, b, o)
        outline(db, 11, 16, 9, 4, hi, o)
        outline(db, 10, 30, 4, 13, wood, o)
        rect(db, 11, 34, 2, 8, wood_hi)
        outline(db, 28, 19, 10, 5, hi, o)
        rect(db, 29, 21, 7, 2, acc)
        rect(dm, 37, 21, 10, 4, acc)
        rect(dm, 41, 22, 4, 2, core)
        for x in (35, 36, 37):
            px(mz, x, 23, core)
        outline(dc, 21, 22, 6, 4, core, o)

    elif wid == "leviathan_bombard":
        outline(db, 8, 24, 22, 10, b, o)
        outline(db, 15, 13, 12, 12, hi, o)
        outline(db, 19, 9, 4, 4, b, o)
        rect(db, 20, 10, 2, 2, acc)
        outline(db, 11, 34, 5, 10, wood, o)
        rect(db, 12, 37, 2, 5, wood_hi)
        rect(dm, 30, 23, 8, 7, acc)
        rect(dm, 32, 25, 4, 2, core)
        rect(dm, 19, 8, 4, 3, acc)
        outline(dc, 19, 17, 4, 6, core, o)

    elif wid == "seraphim_swarm":
        outline(db, 14, 14, 20, 17, b, o)
        outline(db, 20, 19, 8, 7, hi, o)
        outline(db, 9, 19, 5, 6, b, o)
        outline(db, 34, 19, 5, 6, b, o)
        outline(db, 20, 9, 8, 5, b, o)
        outline(db, 20, 31, 8, 5, b, o)
        rect(dm, 10, 20, 3, 2, acc)
        rect(dm, 35, 20, 3, 2, acc)
        rect(dm, 22, 10, 2, 2, acc)
        rect(dm, 25, 10, 2, 2, acc)
        rect(dm, 22, 34, 2, 2, acc)
        rect(dm, 25, 34, 2, 2, acc)
        outline(dc, 21, 20, 6, 6, core, o)

    elif wid == "eclipse_glaive":
        outline(db, 9, 8, 4, 34, wood, o)
        rect(db, 10, 11, 2, 27, wood_hi)
        outline(db, 13, 10, 24, 11, hi, o)
        for x in range(16, 36):
            px(base, x, 11 + ((x - 16) // 3), acc)
        rect(db, 20, 22, 9, 2, b)
        rect(dm, 33, 15, 10, 4, acc)
        rect(dm, 35, 16, 5, 2, core)
        outline(dc, 23, 14, 6, 4, core, o)

    elif wid == "mythic_hailstorm":
        outline(db, 7, 20, 21, 10, b, o)
        outline(db, 11, 16, 8, 4, hi, o)
        outline(db, 10, 30, 4, 12, wood, o)
        rect(db, 11, 34, 2, 6, wood_hi)
        for y in (21, 24, 27):
            rect(db, 29, y, 8, 1, hi)
        rect(dm, 36, 21, 10, 8, acc)
        rect(dm, 39, 23, 5, 3, core)
        outline(dc, 19, 22, 6, 5, core, o)

    elif wid == "thunder_sigil":
        outline(db, 12, 12, 24, 24, b, o)
        outline(db, 17, 17, 14, 14, hi, o)
        for p in ((12, 23), (35, 23), (23, 12), (23, 35), (28, 12), (28, 35)):
            rect(dm, p[0], p[1], 2, 2, acc)
        rect(dm, 18, 17, 2, 2, acc)
        rect(dm, 30, 29, 2, 2, acc)
        outline(dc, 22, 22, 6, 6, core, o)
        rect(dc, 23, 23, 3, 1, acc)

    elif wid == "oracle_splitter":
        outline(db, 7, 19, 23, 11, b, o)
        outline(db, 11, 15, 9, 4, hi, o)
        outline(db, 10, 30, 4, 13, wood, o)
        rect(db, 11, 34, 2, 8, wood_hi)
        outline(db, 28, 20, 9, 8, hi, o)
        rect(db, 30, 21, 6, 1, acc)
        rect(db, 30, 24, 6, 1, acc)
        rect(dm, 36, 21, 9, 7, acc)
        rect(dm, 39, 23, 4, 2, core)
        outline(dc, 20, 22, 6, 5, core, o)

    elif wid == "abyssal_monolith":
        outline(db, 6, 19, 26, 11, b, o)
        outline(db, 10, 15, 10, 4, hi, o)
        outline(db, 9, 30, 4, 13, wood, o)
        rect(db, 10, 34, 2, 7, wood_hi)
        outline(db, 26, 16, 10, 6, hi, o)
        rect(dm, 35, 20, 11, 9, acc)
        rect(dm, 39, 23, 5, 3, core)
        for x in (33, 34, 35):
            px(mz, x, 24, core)
        outline(dc, 21, 22, 7, 5, core, o)

    elif wid == "starfall_engine":
        outline(db, 11, 23, 20, 10, b, o)
        outline(db, 17, 12, 12, 12, hi, o)
        outline(db, 21, 8, 4, 4, b, o)
        rect(db, 22, 9, 2, 2, acc)
        outline(db, 13, 33, 4, 11, wood, o)
        rect(db, 14, 36, 2, 6, wood_hi)
        rect(dm, 31, 22, 9, 8, acc)
        rect(dm, 34, 24, 4, 2, core)
        rect(dm, 21, 7, 4, 3, acc)
        outline(dc, 21, 17, 4, 6, core, o)

    elif wid == "ragnarok_twinfang":
        outline(db, 8, 20, 22, 10, b, o)
        outline(db, 12, 16, 8, 4, hi, o)
        outline(db, 11, 30, 4, 13, wood, o)
        rect(db, 12, 34, 2, 7, wood_hi)
        rect(db, 30, 21, 9, 2, hi)
        rect(db, 30, 25, 9, 2, hi)
        rect(dm, 38, 20, 9, 8, acc)
        rect(dm, 41, 22, 4, 3, core)
        outline(dc, 20, 22, 6, 5, core, o)

    _enhance_weapon_parts(wid, base, mz, c, (o, b, hi, acc, core))

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
    tile_h = 122
    out = Image.new("RGBA", (tile_w * cols + 24, tile_h * rows + 56), (9, 12, 18, 255))
    d = ImageDraw.Draw(out)
    d.text((14, 12), "Weapon Pixel Preview (48 unique, SK-inspired v3 epic themes)", fill=(227, 233, 245, 255))
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
        weapon_meta = data.get(wid, {})
        profile = _weapon_profile(wid, weapon_meta)
        signature_mode = str(weapon_meta.get("signature_mode", "")).strip().lower()
        series = EPIC_SERIES.get(wid, "")
        series_text = EPIC_SERIES_LABEL.get(series, "")
        d.text((x + 102, y + 40), wid, fill=(226, 232, 244, 255))
        d.text((x + 102, y + 64), f"{profile} | {signature_mode}", fill=(163, 193, 226, 255))
        if series_text:
            d.text((x + 102, y + 86), f"EPIC: {series_text}", fill=(255, 210, 148, 255))

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
