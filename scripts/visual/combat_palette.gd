extends RefCounted
class_name CombatPalette

const ENEMY_ACCENT_DEFAULT: Color = Color(0.34, 0.92, 1.0, 1.0)
const ENEMY_ACCENT_DANGER: Color = Color(1.0, 0.47, 0.55, 1.0)
const ENEMY_ACCENT_ELITE: Color = Color(1.0, 0.83, 0.56, 1.0)
const PROJECTILE_ACCENT_BASE: Color = Color(0.58, 0.95, 1.0, 1.0)
const PROJECTILE_ACCENT_DRONE: Color = Color(0.70, 1.0, 0.92, 1.0)
const PROJECTILE_ACCENT_MINE: Color = Color(1.0, 0.80, 0.58, 1.0)
const PROJECTILE_ACCENT_HEAT: Color = Color(1.0, 0.72, 0.46, 1.0)
const PROJECTILE_ACCENT_SILENCE: Color = Color(0.64, 0.90, 1.0, 1.0)
const PROJECTILE_ACCENT_CHAIN: Color = Color(0.62, 1.0, 0.82, 1.0)
const PROJECTILE_ACCENT_AOE: Color = Color(1.0, 0.86, 0.58, 1.0)
const PICKUP_ACCENT_BASE: Color = Color(0.62, 1.0, 0.94, 1.0)
const PICKUP_ACCENT_RARE: Color = Color(1.0, 0.90, 0.64, 1.0)
const HIT_FAMILY_TECH: Color = Color(0.80, 0.96, 1.0, 1.0)
const HIT_FAMILY_BALLISTIC: Color = Color(1.0, 0.78, 0.62, 1.0)
const HIT_FAMILY_PULSE: Color = Color(0.84, 0.72, 1.0, 1.0)
const HIT_FAMILY_BEAM: Color = Color(0.66, 0.88, 1.0, 1.0)
const HIT_FAMILY_CHAIN: Color = Color(0.74, 0.68, 1.0, 1.0)
const HIT_FAMILY_ORDNANCE: Color = Color(1.0, 0.82, 0.52, 1.0)
const HIT_FAMILY_SUMMON: Color = Color(0.72, 1.0, 0.88, 1.0)
const HIT_FAMILY_BLADE: Color = Color(1.0, 0.68, 0.78, 1.0)
const HIT_FAMILY_SONIC: Color = Color(0.68, 1.0, 0.94, 1.0)

const LAYER_PICKUP_GLOW: int = 3
const LAYER_PICKUP: int = 4
const LAYER_ENEMY_AURA: int = 4
const LAYER_ENEMY: int = 5
const LAYER_PROJECTILE_GLOW: int = 7
const LAYER_PROJECTILE: int = 8
const WEAPON_HIT_STYLE_OVERRIDES: Dictionary = {
	"needle_rifle": {
		"accent": Color(0.64, 0.90, 1.0, 1.0),
		"crit_shape": "slash",
		"kill_shape": "diamond_ring",
		"transient": {"pitch_mult": 1.04, "click_gain": 1.16, "low_gain": 1.02, "high_gain": 1.18, "noise_gain": 0.78, "rhythm_hz_add": 1.0}
	},
	"burst_smg": {
		"accent": Color(0.54, 1.0, 0.68, 1.0),
		"crit_shape": "x",
		"kill_shape": "burst",
		"transient": {"pitch_mult": 1.08, "click_gain": 1.34, "low_gain": 1.14, "high_gain": 1.08, "noise_gain": 0.88, "rhythm_hz_add": 1.2}
	},
	"silence_dart": {
		"accent": Color(1.0, 0.79, 0.68, 1.0),
		"crit_shape": "diamond",
		"kill_shape": "ripple",
		"transient": {"pitch_mult": 1.16, "click_gain": 0.86, "low_gain": 0.78, "high_gain": 1.30, "noise_gain": 0.34, "rhythm_hz_add": 2.2}
	},
	"shock_pulse": {
		"accent": Color(1.0, 0.44, 0.66, 1.0),
		"crit_shape": "star",
		"kill_shape": "ripple",
		"transient": {"pitch_mult": 1.14, "click_gain": 0.90, "low_gain": 0.78, "high_gain": 1.38, "noise_gain": 0.56, "rhythm_hz_add": 2.1}
	},
	"abyss_mine": {
		"accent": Color(1.0, 0.80, 0.50, 1.0),
		"crit_shape": "diamond",
		"kill_shape": "burst",
		"transient": {"pitch_mult": 0.82, "click_gain": 0.90, "low_gain": 1.54, "high_gain": 0.78, "noise_gain": 1.30, "rhythm_hz_add": -0.8}
	},
	"tether_beam": {
		"accent": Color(0.55, 0.80, 1.0, 1.0),
		"crit_shape": "slash",
		"kill_shape": "diamond_ring",
		"transient": {"pitch_mult": 0.90, "click_gain": 0.84, "low_gain": 0.82, "high_gain": 1.40, "noise_gain": 0.42, "rhythm_hz_add": 1.1}
	},
	"orbital_drone": {
		"accent": Color(0.60, 1.0, 0.90, 1.0),
		"crit_shape": "star",
		"kill_shape": "ring",
		"transient": {"pitch_mult": 1.24, "click_gain": 0.72, "low_gain": 0.82, "high_gain": 1.22, "noise_gain": 0.48, "rhythm_hz_add": 2.4}
	},
	"sonar_blade": {
		"accent": Color(1.0, 0.68, 0.50, 1.0),
		"crit_shape": "slash",
		"kill_shape": "diamond_ring",
		"transient": {"pitch_mult": 1.08, "click_gain": 1.36, "low_gain": 1.04, "high_gain": 1.22, "noise_gain": 0.66, "rhythm_hz_add": 1.5}
	},
	"idol_railgun": {
		"accent": Color(1.0, 0.88, 0.62, 1.0),
		"crit_shape": "slash",
		"kill_shape": "burst",
		"transient": {"pitch_mult": 0.88, "click_gain": 1.02, "low_gain": 1.18, "high_gain": 1.36, "noise_gain": 0.54, "rhythm_hz_add": 0.5}
	},
	"abyssal_monolith": {
		"accent": Color(0.58, 0.82, 1.0, 1.0),
		"crit_shape": "x",
		"kill_shape": "diamond_ring",
		"transient": {"pitch_mult": 0.86, "click_gain": 0.92, "low_gain": 1.06, "high_gain": 1.42, "noise_gain": 0.50, "rhythm_hz_add": 0.9}
	},
	"leviathan_bombard": {
		"accent": Color(1.0, 0.80, 0.56, 1.0),
		"crit_shape": "diamond",
		"kill_shape": "burst",
		"transient": {"pitch_mult": 0.78, "click_gain": 0.84, "low_gain": 1.64, "high_gain": 0.74, "noise_gain": 1.42, "rhythm_hz_add": -1.0}
	},
	"seraphim_swarm": {
		"accent": Color(0.72, 0.97, 1.0, 1.0),
		"crit_shape": "star",
		"kill_shape": "ripple",
		"transient": {"pitch_mult": 1.26, "click_gain": 0.76, "low_gain": 0.78, "high_gain": 1.30, "noise_gain": 0.40, "rhythm_hz_add": 2.6}
	},
	"eclipse_requiem": {
		"accent": Color(0.82, 0.66, 1.0, 1.0),
		"crit_shape": "diamond",
		"kill_shape": "ripple",
		"transient": {"pitch_mult": 1.12, "click_gain": 0.86, "low_gain": 0.76, "high_gain": 1.34, "noise_gain": 0.44, "rhythm_hz_add": 2.4}
	},
	"ragnarok_twinfang": {
		"accent": Color(1.0, 0.62, 0.76, 1.0),
		"crit_shape": "x",
		"kill_shape": "burst",
		"transient": {"pitch_mult": 1.10, "click_gain": 1.36, "low_gain": 1.08, "high_gain": 1.24, "noise_gain": 0.74, "rhythm_hz_add": 1.8}
	}
}


static func _normalize_neon(input_color: Color, min_saturation: float = 0.52, min_value: float = 0.84) -> Color:
	var alpha := clampf(input_color.a, 0.0, 1.0)
	if alpha <= 0.001:
		alpha = 1.0
	var normalized := Color.from_hsv(
		input_color.h,
		maxf(min_saturation, input_color.s),
		maxf(min_value, input_color.v),
		alpha
	)
	return normalized


static func _tags_to_set(tags: Array) -> Dictionary:
	var out: Dictionary = {}
	for tag_variant in tags:
		var tag := String(tag_variant).strip_edges().to_lower()
		if tag.is_empty():
			continue
		out[tag] = true
	return out


static func enemy_palette(base_color: Color, spawn_group: String, elite: bool) -> Dictionary:
	var accent := _normalize_neon(base_color if base_color.a > 0.001 else ENEMY_ACCENT_DEFAULT, 0.55, 0.82)
	var normalized_group := spawn_group.strip_edges().to_lower()
	if normalized_group == "pursuer":
		accent = ENEMY_ACCENT_DANGER
	elif elite:
		accent = accent.lerp(ENEMY_ACCENT_ELITE, 0.35)
	var body := accent.darkened(0.16)
	body.a = 1.0
	var outline := accent.lightened(0.36)
	outline.a = 0.95
	var aura := accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.18)
	aura.a = 0.30 + (0.08 if elite else 0.0) + (0.10 if normalized_group == "pursuer" else 0.0)
	return {
		"accent": accent,
		"body": body,
		"outline": outline,
		"aura": aura
	}


static func projectile_palette(fx_color: Color, attack_model: String, tags: Array) -> Dictionary:
	var accent := _normalize_neon(fx_color if fx_color.a > 0.001 else PROJECTILE_ACCENT_BASE, 0.58, 0.90)
	var model := attack_model.strip_edges().to_lower()
	var tag_set := _tags_to_set(tags)
	match model:
		"drone":
			accent = accent.lerp(PROJECTILE_ACCENT_DRONE, 0.24)
		"mine":
			accent = accent.lerp(PROJECTILE_ACCENT_MINE, 0.26)
		_:
			pass
	if tag_set.has("heat"):
		accent = accent.lerp(PROJECTILE_ACCENT_HEAT, 0.44)
	if tag_set.has("silence"):
		accent = accent.lerp(PROJECTILE_ACCENT_SILENCE, 0.28)
	if tag_set.has("chain"):
		accent = accent.lerp(PROJECTILE_ACCENT_CHAIN, 0.30)
	if tag_set.has("aoe"):
		accent = accent.lerp(PROJECTILE_ACCENT_AOE, 0.26)
	var core := accent.lightened(0.05)
	core.a = 1.0
	var glow := accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.24)
	glow.a = 0.34
	var trail := accent.darkened(0.20)
	trail.a = 0.22
	return {
		"accent": accent,
		"core": core,
		"glow": glow,
		"trail": trail
	}


static func pickup_palette(xp_amount: int) -> Dictionary:
	var tier := clampf(float(maxi(1, xp_amount) - 1) / 28.0, 0.0, 1.0)
	var accent := PICKUP_ACCENT_BASE.lerp(PICKUP_ACCENT_RARE, pow(tier, 0.75))
	accent = _normalize_neon(accent, 0.50, 0.88)
	var core := accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.14)
	core.a = 0.98
	var glow := accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.30)
	glow.a = 0.30 + 0.08 * tier
	var ring := accent.darkened(0.12)
	ring.a = 0.56
	return {
		"accent": accent,
		"core": core,
		"glow": glow,
		"ring": ring,
		"pulse_speed": lerpf(2.8, 4.1, tier)
	}


static func _hit_family_base_color(family: String) -> Color:
	match family:
		"ballistic":
			return HIT_FAMILY_BALLISTIC
		"pulse":
			return HIT_FAMILY_PULSE
		"beam":
			return HIT_FAMILY_BEAM
		"chain":
			return HIT_FAMILY_CHAIN
		"ordnance":
			return HIT_FAMILY_ORDNANCE
		"summon":
			return HIT_FAMILY_SUMMON
		"blade":
			return HIT_FAMILY_BLADE
		"sonic":
			return HIT_FAMILY_SONIC
		_:
			return HIT_FAMILY_TECH


static func _resolve_hit_family(attack_model: String, tags: Dictionary) -> String:
	var model := attack_model.strip_edges().to_lower()
	if tags.has("summon") or model == "drone":
		return "summon"
	if tags.has("trap") or model == "mine":
		return "ordnance"
	if tags.has("chain"):
		return "chain"
	if model == "beam":
		return "beam"
	if model == "pulse":
		return "pulse"
	if model == "melee":
		return "blade"
	if tags.has("silence") or tags.has("sonar"):
		return "sonic"
	if tags.has("damage") or tags.has("kinetic") or tags.has("heat") or tags.has("pierce"):
		return "ballistic"
	return "tech"


static func _weapon_signature_seed(weapon_id: String) -> int:
	var normalized := weapon_id.strip_edges().to_lower()
	if normalized.is_empty():
		return -1
	return int(hash(normalized)) & 0x7fffffff


static func _shape_candidates_for_family(family: String) -> Dictionary:
	match family:
		"ballistic":
			return {"crit": ["slash", "x", "cross"], "kill": ["burst", "diamond_ring", "ring"]}
		"pulse":
			return {"crit": ["star", "diamond", "cross"], "kill": ["ripple", "ring", "diamond_ring"]}
		"beam":
			return {"crit": ["slash", "x", "diamond"], "kill": ["diamond_ring", "ring", "ripple"]}
		"chain":
			return {"crit": ["x", "star", "slash"], "kill": ["ripple", "diamond_ring", "ring"]}
		"ordnance":
			return {"crit": ["diamond", "x", "cross"], "kill": ["burst", "ring", "ripple"]}
		"summon":
			return {"crit": ["star", "cross", "x"], "kill": ["ring", "ripple", "diamond_ring"]}
		"blade":
			return {"crit": ["slash", "x", "diamond"], "kill": ["diamond_ring", "burst", "ring"]}
		"sonic":
			return {"crit": ["diamond", "star", "cross"], "kill": ["ripple", "ring", "diamond_ring"]}
		_:
			return {"crit": ["cross", "x", "star"], "kill": ["ring", "ripple", "diamond_ring"]}


static func _resolve_weapon_shapes(family: String, seed: int) -> Dictionary:
	var candidates := _shape_candidates_for_family(family)
	var crit_options_variant: Variant = candidates.get("crit", ["cross"])
	var kill_options_variant: Variant = candidates.get("kill", ["ring"])
	var crit_options: Array = crit_options_variant if crit_options_variant is Array else ["cross"]
	var kill_options: Array = kill_options_variant if kill_options_variant is Array else ["ring"]
	var crit_idx := seed % maxi(1, crit_options.size())
	var kill_idx := (seed >> 3) % maxi(1, kill_options.size())
	return {
		"crit_shape": String(crit_options[crit_idx]),
		"kill_shape": String(kill_options[kill_idx])
	}


static func _apply_weapon_accent_variation(accent: Color, family_base: Color, seed: int) -> Color:
	var hue_shift := (float(seed & 31) / 31.0 - 0.5) * 0.10
	var sat_shift := (float((seed >> 5) & 15) / 15.0 - 0.5) * 0.18
	var val_shift := (float((seed >> 9) & 15) / 15.0 - 0.5) * 0.14
	var tinted := Color.from_hsv(
		fposmod(accent.h + hue_shift + (family_base.h - 0.5) * 0.02, 1.0),
		clampf(accent.s + sat_shift, 0.48, 1.0),
		clampf(accent.v + val_shift, 0.78, 1.0),
		1.0
	)
	return _normalize_neon(tinted, 0.48, 0.80)


static func _apply_weapon_transient_variation(transient: Dictionary, seed: int) -> Dictionary:
	var out := transient.duplicate(true)
	var pitch_mult := lerpf(0.94, 1.08, float((seed >> 2) & 7) / 7.0)
	var click_mult := lerpf(0.84, 1.20, float((seed >> 6) & 7) / 7.0)
	var low_mult := lerpf(0.86, 1.18, float((seed >> 10) & 7) / 7.0)
	var high_mult := lerpf(0.86, 1.22, float((seed >> 13) & 7) / 7.0)
	var noise_mult := lerpf(0.82, 1.20, float((seed >> 16) & 7) / 7.0)
	var rhythm_add := (float((seed >> 19) & 7) - 3.0) * 0.14
	out["pitch_mult"] = clampf(float(out.get("pitch_mult", 1.0)) * pitch_mult, 0.65, 1.55)
	out["click_gain"] = clampf(float(out.get("click_gain", 1.0)) * click_mult, 0.45, 1.80)
	out["low_gain"] = clampf(float(out.get("low_gain", 1.0)) * low_mult, 0.45, 1.95)
	out["high_gain"] = clampf(float(out.get("high_gain", 1.0)) * high_mult, 0.45, 1.95)
	out["noise_gain"] = clampf(float(out.get("noise_gain", 1.0)) * noise_mult, 0.20, 1.95)
	out["rhythm_hz_add"] = clampf(float(out.get("rhythm_hz_add", 0.0)) + rhythm_add, -3.0, 4.0)
	return out


static func _apply_weapon_style_override(
	weapon_id: String,
	accent: Color,
	crit_shape: String,
	kill_shape: String,
	transient: Dictionary
) -> Dictionary:
	var normalized := weapon_id.strip_edges().to_lower()
	var override_variant: Variant = WEAPON_HIT_STYLE_OVERRIDES.get(normalized, {})
	if not (override_variant is Dictionary):
		return {
			"accent": accent,
			"crit_shape": crit_shape,
			"kill_shape": kill_shape,
			"transient": transient
		}
	var weapon_override: Dictionary = override_variant
	var out_accent := accent
	var out_crit_shape := crit_shape
	var out_kill_shape := kill_shape
	var out_transient := transient.duplicate(true)
	var accent_variant: Variant = weapon_override.get("accent", null)
	if accent_variant is Color:
		out_accent = _normalize_neon(accent.lerp(accent_variant as Color, 0.62), 0.50, 0.82)
	var crit_shape_variant: Variant = weapon_override.get("crit_shape", "")
	var crit_shape_value := String(crit_shape_variant).strip_edges().to_lower()
	if not crit_shape_value.is_empty():
		out_crit_shape = crit_shape_value
	var kill_shape_variant: Variant = weapon_override.get("kill_shape", "")
	var kill_shape_value := String(kill_shape_variant).strip_edges().to_lower()
	if not kill_shape_value.is_empty():
		out_kill_shape = kill_shape_value
	var transient_variant: Variant = weapon_override.get("transient", {})
	if transient_variant is Dictionary:
		for key_variant in (transient_variant as Dictionary).keys():
			out_transient[String(key_variant)] = float((transient_variant as Dictionary)[key_variant])
	return {
		"accent": out_accent,
		"crit_shape": out_crit_shape,
		"kill_shape": out_kill_shape,
		"transient": out_transient
	}


static func _hit_post_profile_by_family(family: String, accent: Color) -> Dictionary:
	var base := {
		"trail_strength": 0.16,
		"trail_pixels": 2.4,
		"trail_decay": 6.0,
		"trail_tint": accent,
		"tint_strength": 0.10,
		"tint_decay": 7.6,
		"lut_strength": 0.10,
		"lut_decay": 6.4,
		"lut_speed": 1.6,
		"lut_palette_phase": 0.0
	}
	match family:
		"ballistic":
			base["trail_strength"] = 0.19
			base["trail_pixels"] = 3.0
			base["trail_decay"] = 5.2
			base["tint_strength"] = 0.11
			base["lut_strength"] = 0.08
			base["lut_speed"] = 1.3
		"pulse":
			base["trail_strength"] = 0.14
			base["trail_pixels"] = 2.0
			base["trail_decay"] = 7.2
			base["tint_strength"] = 0.18
			base["lut_strength"] = 0.20
			base["lut_speed"] = 2.6
		"beam":
			base["trail_strength"] = 0.23
			base["trail_pixels"] = 4.4
			base["trail_decay"] = 5.4
			base["tint_strength"] = 0.15
			base["lut_strength"] = 0.14
			base["lut_speed"] = 1.9
		"chain":
			base["trail_strength"] = 0.26
			base["trail_pixels"] = 3.5
			base["trail_decay"] = 5.0
			base["tint_strength"] = 0.16
			base["lut_strength"] = 0.22
			base["lut_speed"] = 2.8
		"ordnance":
			base["trail_strength"] = 0.30
			base["trail_pixels"] = 5.2
			base["trail_decay"] = 4.5
			base["tint_strength"] = 0.20
			base["lut_strength"] = 0.10
			base["lut_speed"] = 1.1
		"summon":
			base["trail_strength"] = 0.16
			base["trail_pixels"] = 2.2
			base["trail_decay"] = 6.8
			base["tint_strength"] = 0.14
			base["lut_strength"] = 0.17
			base["lut_speed"] = 2.2
		"blade":
			base["trail_strength"] = 0.21
			base["trail_pixels"] = 3.2
			base["trail_decay"] = 5.4
			base["tint_strength"] = 0.13
			base["lut_strength"] = 0.13
			base["lut_speed"] = 1.8
		"sonic":
			base["trail_strength"] = 0.18
			base["trail_pixels"] = 2.6
			base["trail_decay"] = 6.4
			base["tint_strength"] = 0.18
			base["lut_strength"] = 0.24
			base["lut_speed"] = 3.0
		_:
			pass
	return base


static func _apply_weapon_post_variation(post_fx: Dictionary, seed: int) -> Dictionary:
	var out := post_fx.duplicate(true)
	var trail_mult := lerpf(0.86, 1.22, float((seed >> 4) & 7) / 7.0)
	var tint_mult := lerpf(0.86, 1.26, float((seed >> 8) & 7) / 7.0)
	var lut_mult := lerpf(0.84, 1.30, float((seed >> 12) & 7) / 7.0)
	var trail_px_add := lerpf(-0.6, 1.4, float((seed >> 16) & 7) / 7.0)
	var lut_speed_add := lerpf(-0.35, 0.75, float((seed >> 20) & 7) / 7.0)
	out["trail_strength"] = clampf(float(out.get("trail_strength", 0.16)) * trail_mult, 0.04, 0.75)
	out["trail_pixels"] = clampf(float(out.get("trail_pixels", 2.4)) + trail_px_add, 0.8, 8.0)
	out["trail_decay"] = clampf(float(out.get("trail_decay", 6.0)), 3.0, 10.0)
	out["tint_strength"] = clampf(float(out.get("tint_strength", 0.10)) * tint_mult, 0.03, 0.42)
	out["tint_decay"] = clampf(float(out.get("tint_decay", 7.6)), 3.0, 11.0)
	out["lut_strength"] = clampf(float(out.get("lut_strength", 0.10)) * lut_mult, 0.03, 0.46)
	out["lut_decay"] = clampf(float(out.get("lut_decay", 6.4)), 3.0, 11.0)
	out["lut_speed"] = clampf(float(out.get("lut_speed", 1.6)) + lut_speed_add, 0.35, 4.8)
	out["lut_palette_phase"] = fposmod(float(seed & 255) / 255.0, 1.0)
	return out


static func _apply_weapon_post_override(weapon_id: String, post_fx: Dictionary) -> Dictionary:
	var normalized := weapon_id.strip_edges().to_lower()
	var override_variant: Variant = WEAPON_HIT_STYLE_OVERRIDES.get(normalized, {})
	if not (override_variant is Dictionary):
		return post_fx
	var post_variant: Variant = (override_variant as Dictionary).get("post_fx", {})
	if not (post_variant is Dictionary):
		return post_fx
	var out := post_fx.duplicate(true)
	var post_dict: Dictionary = post_variant
	for key_variant in post_dict.keys():
		var key := String(key_variant)
		if key == "trail_tint":
			var tint_variant: Variant = post_dict[key_variant]
			if tint_variant is Color:
				out[key] = tint_variant
			continue
		out[key] = float(post_dict[key_variant])
	return out


static func hit_feedback_profile(
	attack_model: String,
	tags: Array,
	fx_color: Color = Color(0.0, 0.0, 0.0, 0.0),
	weapon_id: String = ""
) -> Dictionary:
	var tag_set := _tags_to_set(tags)
	var family := _resolve_hit_family(attack_model, tag_set)
	var family_base := _hit_family_base_color(family)
	var has_fx := fx_color.a > 0.001 or (fx_color.r + fx_color.g + fx_color.b) > 0.03
	var accent_source := fx_color if has_fx else family_base
	var accent := _normalize_neon(accent_source, 0.50, 0.82).lerp(family_base, 0.42)
	var crit_shape := "cross"
	var kill_shape := "ring"
	var transient := {
		"pitch_mult": 1.0,
		"click_gain": 1.0,
		"low_gain": 1.0,
		"high_gain": 1.0,
		"noise_gain": 1.0,
		"rhythm_hz_add": 0.0
	}
	match family:
		"ballistic":
			crit_shape = "slash"
			kill_shape = "burst"
			transient = {
				"pitch_mult": 1.02,
				"click_gain": 1.22,
				"low_gain": 1.08,
				"high_gain": 1.06,
				"noise_gain": 0.86,
				"rhythm_hz_add": 0.7
			}
		"pulse":
			crit_shape = "star"
			kill_shape = "ripple"
			transient = {
				"pitch_mult": 1.08,
				"click_gain": 0.92,
				"low_gain": 0.90,
				"high_gain": 1.28,
				"noise_gain": 0.58,
				"rhythm_hz_add": 1.9
			}
		"beam":
			crit_shape = "slash"
			kill_shape = "diamond_ring"
			transient = {
				"pitch_mult": 0.92,
				"click_gain": 0.88,
				"low_gain": 0.84,
				"high_gain": 1.34,
				"noise_gain": 0.46,
				"rhythm_hz_add": 1.1
			}
		"chain":
			crit_shape = "x"
			kill_shape = "ripple"
			transient = {
				"pitch_mult": 1.06,
				"click_gain": 1.06,
				"low_gain": 0.86,
				"high_gain": 1.30,
				"noise_gain": 0.62,
				"rhythm_hz_add": 1.6
			}
		"ordnance":
			crit_shape = "diamond"
			kill_shape = "burst"
			transient = {
				"pitch_mult": 0.84,
				"click_gain": 0.94,
				"low_gain": 1.42,
				"high_gain": 0.82,
				"noise_gain": 1.22,
				"rhythm_hz_add": -0.5
			}
		"summon":
			crit_shape = "star"
			kill_shape = "ring"
			transient = {
				"pitch_mult": 1.18,
				"click_gain": 0.78,
				"low_gain": 0.86,
				"high_gain": 1.14,
				"noise_gain": 0.54,
				"rhythm_hz_add": 2.1
			}
		"blade":
			crit_shape = "slash"
			kill_shape = "diamond_ring"
			transient = {
				"pitch_mult": 1.04,
				"click_gain": 1.28,
				"low_gain": 0.98,
				"high_gain": 1.18,
				"noise_gain": 0.72,
				"rhythm_hz_add": 1.2
			}
		"sonic":
			crit_shape = "diamond"
			kill_shape = "ripple"
			transient = {
				"pitch_mult": 1.12,
				"click_gain": 0.82,
				"low_gain": 0.82,
				"high_gain": 1.24,
				"noise_gain": 0.40,
				"rhythm_hz_add": 2.3
			}
		_:
			pass
	var signature_seed := _weapon_signature_seed(weapon_id)
	if signature_seed >= 0:
		accent = accent.lerp(_apply_weapon_accent_variation(accent, family_base, signature_seed), 0.54)
		var shape_variant: Dictionary = _resolve_weapon_shapes(family, signature_seed)
		crit_shape = String(shape_variant.get("crit_shape", crit_shape)).strip_edges().to_lower()
		kill_shape = String(shape_variant.get("kill_shape", kill_shape)).strip_edges().to_lower()
		transient = _apply_weapon_transient_variation(transient, signature_seed)
	var override: Dictionary = _apply_weapon_style_override(weapon_id, accent, crit_shape, kill_shape, transient)
	accent = override.get("accent", accent)
	crit_shape = String(override.get("crit_shape", crit_shape)).strip_edges().to_lower()
	kill_shape = String(override.get("kill_shape", kill_shape)).strip_edges().to_lower()
	var transient_variant: Variant = override.get("transient", transient)
	transient = transient_variant if transient_variant is Dictionary else transient
	var flash := accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.12)
	var crit_color := accent.lightened(0.20)
	var kill_color := accent.lerp(Color(1.0, 0.92, 0.76, 1.0), 0.38)
	var particle_color := accent.lightened(0.14)
	var post_fx := _hit_post_profile_by_family(family, accent)
	if signature_seed >= 0:
		post_fx = _apply_weapon_post_variation(post_fx, signature_seed)
	post_fx["trail_tint"] = accent
	post_fx = _apply_weapon_post_override(weapon_id, post_fx)
	return {
		"family": family,
		"weapon_id": weapon_id.strip_edges().to_lower(),
		"accent": accent,
		"flash": flash,
		"particle": particle_color,
		"glow": accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.26),
		"crit_color": crit_color,
		"kill_color": kill_color,
		"crit_shape": crit_shape,
		"kill_shape": kill_shape,
		"transient": transient,
		"post_fx": post_fx
	}
