extends RefCounted


static func from_dict(data: Dictionary) -> Dictionary:
	return {
		"hp_current": float(data.get("hp", 0.0)),
		"hp_max": maxf(1.0, float(data.get("max_hp", 100.0))),
		"noise_value": float(data.get("noise", 0.0)),
		"noise_min": float(data.get("noise_min", 0.0)),
		"noise_max": maxf(float(data.get("noise_min", 0.0)) + 1.0, float(data.get("noise_max", 100.0))),
		"noise_tier_name": String(data.get("noise_tier_name", "Silent")),
		"noise_tier_id": String(data.get("noise_tier_id", "silent")),
		"noise_tier_color": Color.from_string(String(data.get("noise_tier_color", "#74e7ff")), Color(0.45, 0.9, 1.0, 1.0)),
		"xp": float(data.get("xp", 0.0)),
		"xp_to_next": maxf(1.0, float(data.get("xp_to_next", 1.0))),
		"level": int(data.get("level", 1)),
		"elapsed_time": float(data.get("elapsed_time", 0.0)),
		"kills": int(data.get("kills", 0)),
		"enemy_count": int(data.get("enemy_count", 0)),
		"revealed_count": int(data.get("revealed_count", 0)),
		"weapon_id": String(data.get("active_weapon_id", "")),
		"weapon_name": String(data.get("active_weapon_name", data.get("active_weapon_id", "--"))),
		"weapon_tags": _string_array(data.get("weapon_tags", [])),
		"build_tags": _string_array(data.get("build_tags", [])),
		"sonar_cd_remaining": maxf(0.0, float(data.get("skill_cd", data.get("sonar_cd_remaining", 0.0)))),
		"sonar_cd_total": maxf(0.0, float(data.get("skill_cd_total", data.get("sonar_cd_total", 0.0)))),
		"sonar_feedback_timer": maxf(0.0, float(data.get("sonar_feedback_timer", 0.0))),
		"sonar_ping_count": int(data.get("sonar_ping_count", 0)),
		"sonar_ping_sequence": int(data.get("sonar_ping_sequence", 0)),
		"kill_streak": maxi(0, int(data.get("kill_streak", 0))),
		"kill_streak_timer": maxf(0.0, float(data.get("kill_streak_timer", 0.0))),
			"kill_streak_window": maxf(0.1, float(data.get("kill_streak_window", 4.2))),
			"kill_streak_step": maxi(1, int(data.get("kill_streak_step", 6))),
			"dash_cd_remaining": maxf(0.0, float(data.get("dash_cd", data.get("dash_cd_remaining", 0.0)))),
			"dash_cd_total": maxf(0.0, float(data.get("dash_cd_total", 0.0))),
			"contract_dash_disabled": bool(data.get("contract_dash_disabled", false)),
			"boss_active": bool(data.get("boss_active", false)),
			"boss_name": String(data.get("boss_name", "")),
			"boss_hp": maxf(0.0, float(data.get("boss_hp", 0.0))),
			"boss_hp_max": maxf(1.0, float(data.get("boss_hp_max", 1.0))),
			"boss_hp_ratio": clampf(float(data.get("boss_hp_ratio", 0.0)), 0.0, 1.0),
			"boss_phase_id": String(data.get("boss_phase_id", "")),
			"boss_phase_label": String(data.get("boss_phase_label", "")),
			"boss_exam_type": String(data.get("boss_exam_type", "")),
			"boss_exam_objective": String(data.get("boss_exam_objective", "")),
			"boss_summon_break_required": maxi(0, int(data.get("boss_summon_break_required", 0))),
			"boss_summon_break_kills": maxi(0, int(data.get("boss_summon_break_kills", 0))),
			"boss_summon_break_alive": maxi(0, int(data.get("boss_summon_break_alive", 0))),
			"boss_summon_break_active": bool(data.get("boss_summon_break_active", false))
		}


static func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in (value as Array):
			var text := String(item).strip_edges()
			if text.is_empty():
				continue
			out.append(text)
	return out
