extends SceneTree

var failed: int = 0
var _completed: bool = false
var _summary: Dictionary = {}
var _original_language_code: String = "en"
var _finish_requested: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	var localization := _localization()
	if localization != null and localization.has_method("get_language_code"):
		_original_language_code = String(localization.call("get_language_code"))
	if localization != null and localization.has_method("set_language_code"):
		localization.call("set_language_code", "zh_CN")
	await _run_cover_blocking_tests()
	_run_generator_validation_tests()
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("night run scaffold test could not load NightRun.tscn")
		_finish()
		return
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
	if run_node.has_signal("session_completed"):
		run_node.connect("session_completed", Callable(self, "_on_session_completed"))
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": 9001,
		"session_duration_sec": 60.0
	})

	await _wait_frames(10)
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("presentation_profile", "")), "clear_dungeon", "night run boots the bright dungeon presentation profile")
	_assert_true(bool(snapshot.get("runtime_clear_dungeon_presentation", false)), "night run enables clear dungeon presentation in the embedded combat world")
	_assert_true(not bool(snapshot.get("runtime_fog_enabled", true)), "night run disables fog darkness for readable dungeon rooms")
	_assert_equal(String(snapshot.get("floor_label", "")), "裂隙第一层", "night run floor label follows the Chinese localization pass")
	_assert_equal(String(snapshot.get("room_id", "")), "camp", "night run starts in the deterministic rest room")
	_assert_equal(String(snapshot.get("room_label", "")), "港湾庇护所", "night run room labels localize into Chinese")
	_assert_equal(String(snapshot.get("room_type_id", "")), "rest", "night run opens on a rest node")
	_assert_equal(String(snapshot.get("room_type_label", "")), "休整", "night run room-type labels localize into Chinese")
	_assert_equal(String(snapshot.get("room_render_parent", "")), "RuntimeRoomLayer", "night rooms mount into the dedicated runtime room layer instead of the dark world root")
	_assert_true(bool(snapshot.get("runtime_map_geometry_hidden", false)), "clear dungeon presentation hides the old map geometry behind the room-based dungeon view")
	var camera_zoom_variant: Variant = snapshot.get("camera_zoom", Vector2.ONE)
	var camera_zoom: Vector2 = camera_zoom_variant if camera_zoom_variant is Vector2 else Vector2.ONE
	_assert_true(camera_zoom.x < 0.8 and camera_zoom.y < 0.8, "clear dungeon presentation uses a tighter zoom that frames the room like a dedicated dungeon chamber")
	var room_scene_scale_variant: Variant = snapshot.get("room_scene_scale", Vector2.ONE)
	var room_scene_scale: Vector2 = room_scene_scale_variant if room_scene_scale_variant is Vector2 else Vector2.ONE
	_assert_true(room_scene_scale.x >= 1.0 and room_scene_scale.y >= 1.0, "night rooms scale up to their authored footprint")
	_assert_true(bool(snapshot.get("room_shell_present", false)), "night run builds an explicit runtime room shell around the active chamber")
	_assert_true(int(snapshot.get("room_shell_visual_count", 0)) >= 12, "runtime room shell includes visible walls, floor slabs, and doorway framing")
	_assert_true(int(snapshot.get("room_tile_visual_count", 0)) >= 16, "runtime room shell lays down explicit floor tile slabs for chamber readability")
	_assert_true(int(snapshot.get("room_corner_shadow_count", 0)) >= 8, "runtime room shell adds corner shadows so the chamber reads as a bounded room")
	_assert_true(int(snapshot.get("room_plank_visual_count", 0)) >= 8, "open doorways add wooden plank corridor trim instead of raw empty holes")
	_assert_true(int(snapshot.get("room_corridor_visual_count", 0)) >= 8, "rest room shell extends each visible doorway into a readable corridor segment")
	_assert_true(int(snapshot.get("room_open_door_visual_count", 0)) >= 4, "unlocked room exits render as visibly open doors")
	_assert_equal(int(snapshot.get("room_closed_door_visual_count", 0)), 0, "entry rest room does not render sealed doors when both exits are open")
	_assert_equal(String((snapshot.get("minimap", {}) as Dictionary).get("layout_mode", "")), "spatial", "minimap snapshot now reports a spatial floor-plan layout")
	_assert_equal(String(snapshot.get("room_status", "")), "cleared", "rest room resolves immediately after entry")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "rest room auto-claims its room reward")
	_assert_equal(int((snapshot.get("available_exits", []) as Array).size()), 2, "entry room exposes two route choices")
	_assert_true(_minimap_has_room_type(snapshot, "boss"), "minimap snapshot includes the boss room type")
	_assert_true(_minimap_has_room_type(snapshot, "treasure"), "minimap snapshot includes the treasure room type")
	_assert_true(_minimap_has_room_type(snapshot, "event"), "minimap snapshot includes the event room type")
	_assert_true(_minimap_grid_spacing_is_valid(snapshot), "minimap snapshot includes a valid spatial grid spacing")
	_assert_true(_minimap_room_has_positive_size(snapshot, "camp"), "camp room exports a positive minimap footprint")
	_assert_true(_minimap_room_has_positive_size(snapshot, "apex_guardian"), "boss room exports a positive minimap footprint")
	_assert_true(_minimap_room_area(snapshot, "apex_guardian") > _minimap_room_area(snapshot, "camp"), "boss room footprint is larger than the entry room on the spatial map")
	_assert_true(_minimap_room_position(snapshot, "reef_patrol").y < _minimap_room_position(snapshot, "camp").y, "upper branch room stays north of camp in the spatial floor plan")
	_assert_true(_minimap_room_position(snapshot, "swarm_nest").y > _minimap_room_position(snapshot, "camp").y, "lower branch room stays south of camp in the spatial floor plan")
	_assert_equal(float((snapshot.get("player_hud", {}) as Dictionary).get("visibility_penalty_multiplier", 0.0)), 1.0, "clear dungeon presentation removes the old darkness visibility penalty")
	var reef_patrol_room := _find_room_snapshot(snapshot, "reef_patrol")
	var swarm_nest_room := _find_room_snapshot(snapshot, "swarm_nest")
	var apex_guardian_room := _find_room_snapshot(snapshot, "apex_guardian")
	_assert_equal(String(reef_patrol_room.get("encounter_category", "")), "standard", "reef patrol is marked as a standard encounter")
	_assert_equal(String(swarm_nest_room.get("encounter_category", "")), "elite", "swarm nest is marked as an elite encounter")
	_assert_equal(String(apex_guardian_room.get("encounter_category", "")), "boss", "apex guardian is marked as a boss encounter")
	_assert_true(String(reef_patrol_room.get("scene_path", "")).find("CombatRoom.tscn") < 0, "reef patrol now uses an authored combat room scene")
	_assert_true(String(apex_guardian_room.get("scene_path", "")).find("CombatRoom.tscn") < 0, "boss room now uses an authored boss-room scene")
	var first_reef_scene_path := String(reef_patrol_room.get("scene_path", ""))

	run_node.call("debug_use_exit", "swarm_nest")
	await _wait_frames(1)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("transition_active", false)), "selecting a door first enters a corridor transition state")
	_assert_true(bool(snapshot.get("transition_corridor_present", false)), "corridor transition spawns a visible corridor bridge between rooms")
	_assert_equal(String(snapshot.get("transition_target_room_id", "")), "swarm_nest", "corridor transition tracks the chosen target room")
	var corridor_camera_zoom_variant: Variant = snapshot.get("camera_zoom", Vector2.ONE)
	var corridor_camera_zoom: Vector2 = corridor_camera_zoom_variant if corridor_camera_zoom_variant is Vector2 else Vector2.ONE
	_assert_true(corridor_camera_zoom.x > 0.70 and corridor_camera_zoom.y > 0.70, "corridor transition zooms the camera back out while crossing rooms")
	await _wait_for_room_id(run_node, "swarm_nest")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "swarm_nest", "selecting an exit advances into the chosen combat room")
	_assert_equal(String(snapshot.get("room_type_id", "")), "combat", "swarm nest room is treated as a combat room")
	_assert_equal(String(snapshot.get("encounter_category", "")), "elite", "combat room exposes its elite encounter category")
	_assert_equal(String(snapshot.get("room_status", "")), "active", "combat room becomes active on entry")
	_assert_true(not bool(snapshot.get("room_cleared", true)), "combat room remains uncleared until the encounter is resolved")
	_assert_true(_snapshot_has_locked_exit(snapshot), "combat room keeps its exit locked while enemies are alive")
	_assert_true(int(snapshot.get("room_corridor_visual_count", 0)) >= 8, "combat room keeps a visible entry/exit corridor shell while locked")
	_assert_true(int(snapshot.get("room_closed_door_visual_count", 0)) >= 4, "locked combat room renders sealed doorway visuals")
	_assert_equal(int(snapshot.get("room_open_door_visual_count", 0)), 0, "locked combat room does not leave exit doors visually open")
	var elite_room_content: Dictionary = snapshot.get("room_content", {})
	_assert_true(int(elite_room_content.get("cover_layer_z", 0)) >= 28, "elite room lifts authored cover into a dedicated foreground layer")
	_assert_true(int(elite_room_content.get("cover_count", 0)) >= 3, "elite room exposes authored cover geometry")
	_assert_true(int(elite_room_content.get("cover_proxy_count", 0)) >= int(elite_room_content.get("cover_count", 0)), "elite room generates visible cover proxies for every authored blocker")
	_assert_true(int(elite_room_content.get("hazard_count", 0)) >= 1, "elite room exposes authored hazard setpieces")
	_assert_true(int(elite_room_content.get("explosive_count", 0)) >= 1, "elite room exposes authored explosive props")
	_assert_true(int(elite_room_content.get("wall_visual_count", 0)) >= 4, "elite room exposes visible room-shell wall geometry")
	var base_weapon_dps := float((snapshot.get("player_hud", {}) as Dictionary).get("weapon_dps_estimate", 0.0))

	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("room_cleared", false)), "forcing the encounter clear marks the room as cleared")
	_assert_true(not _snapshot_has_locked_exit(snapshot), "clearing the room unlocks its exit")
	_assert_true(int(snapshot.get("room_open_door_visual_count", 0)) >= 4, "clearing the combat room visibly opens its onward door")
	_assert_true(int(snapshot.get("room_closed_door_visual_count", 0)) >= 4, "entry door remains visibly sealed behind the player after room clear")
	_assert_true(bool(snapshot.get("reward_panel_visible", false)), "combat clear opens a room-end reward panel")
	_assert_true(not bool(snapshot.get("room_reward_claimed", true)), "combat room reward remains unclaimed until the player picks one")
	_assert_equal(int((snapshot.get("reward_choices", []) as Array).size()), 3, "combat clear presents three compact reward choices")
	_assert_true(_reward_choices_are_localized(snapshot), "room-end reward choices are fully localized in Chinese")
	_assert_true(_reward_choice_has_kind(snapshot, "currency"), "reward panel includes a currency or materials option")
	_assert_true(_reward_choice_has_kind(snapshot, "weapon"), "reward panel includes a weapon-focused run modifier")

	_assert_true(bool(run_node.call("debug_select_room_reward", 2)), "weapon reward option can be claimed from the room-end reward panel")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "claiming a room-end reward marks the room reward as claimed")
	_assert_true(not bool(snapshot.get("reward_panel_visible", true)), "reward panel closes after a reward is chosen")
	var run_modifier_state: Dictionary = snapshot.get("run_modifier_state", {})
	var applied_modifiers: Array = run_modifier_state.get("applied_modifiers", [])
	_assert_equal(int(applied_modifiers.size()), 1, "claiming a weapon reward records one applied run modifier")
	if not applied_modifiers.is_empty() and applied_modifiers[0] is Dictionary:
		_assert_equal(String((applied_modifiers[0] as Dictionary).get("reward_kind", "")), "weapon", "chosen reward is tracked as a weapon modifier")
	var upgraded_weapon_dps := float((snapshot.get("player_hud", {}) as Dictionary).get("weapon_dps_estimate", 0.0))
	_assert_true(upgraded_weapon_dps > base_weapon_dps, "claiming a weapon reward makes the player stronger within the same run")

	run_node.call("debug_use_exit", "quiet_niche")
	await _wait_for_room_id(run_node, "quiet_niche")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "quiet_niche", "elite branch advances into its linked rest room")
	_assert_equal(String(snapshot.get("room_type_id", "")), "rest", "quiet niche is marked as a rest room")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "rest room claims its reward on entry")
	_assert_equal(String(snapshot.get("room_status", "")), "cleared", "rest room resolves immediately after its reward")

	run_node.call("debug_use_exit", "omen_shrine")
	await _wait_for_room_id(run_node, "omen_shrine")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_type_id", "")), "event", "elite branch feeds into an event room")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "event room marks its reward as claimed")

	run_node.call("debug_use_exit", "apex_guardian")
	await _wait_for_room_id(run_node, "apex_guardian")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_type_id", "")), "boss", "final room is marked as a boss room")
	_assert_equal(String(snapshot.get("encounter_category", "")), "boss", "boss room exposes boss encounter metadata")
	var boss_climax: Dictionary = snapshot.get("boss_climax", {})
	_assert_true(bool(boss_climax.get("active", false)), "boss room activates the floor-climax panel")
	_assert_equal(String(boss_climax.get("title", "")), "楼层高潮战", "boss panel shows the localized climax title")
	_assert_true(_snapshot_has_locked_exit(snapshot) == false, "boss room with no onward exits does not expose unlocked navigation")
	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("reward_panel_visible", false)), "boss clear also triggers a final reward choice")
	_assert_true(bool(run_node.call("debug_select_room_reward", 0)), "final room reward can be claimed before extraction")
	await _wait_for_completion()

	_assert_true(_completed, "clearing the boss room completes the night run")
	_assert_equal(String(_summary.get("exit_reason", "")), "completed", "goal-room completion preserves the normal completed return flow")
	_assert_true(int(_summary.get("dungeon_rooms_cleared", 0)) >= 5, "summary tracks cleared rooms across the dungeon route")
	var room_path: Array = _summary.get("dungeon_room_path", [])
	_assert_true(room_path.has("camp"), "summary records the rest room in the dungeon path")
	_assert_true(room_path.has("swarm_nest"), "summary records the chosen elite branch room in the dungeon path")
	_assert_true(room_path.has("quiet_niche"), "summary records the linked rest room in the dungeon path")
	_assert_true(room_path.has("omen_shrine"), "summary records the event room in the dungeon path")
	_assert_true(room_path.has("apex_guardian"), "summary records the boss room in the dungeon path")
	_assert_equal(String(_summary.get("dungeon_last_room_type_id", "")), "boss", "summary records the final boss-room type")
	_assert_true((_summary.get("dungeon_run_rewards", []) as Array).size() >= 2, "summary records claimed room-end rewards across the run")
	_assert_true((_summary.get("dungeon_run_modifiers", []) as Array).size() >= 1, "summary records applied temporary run modifiers")
	_assert_true(bool(_summary.get("dungeon_boss_cleared", false)), "summary records the boss-floor clear")
	_assert_equal(String(_summary.get("dungeon_return_route_label", "")), "首领层已清空", "completed return payload stays localized in Chinese")
	var boss_bonus_materials: Dictionary = _summary.get("dungeon_boss_bonus_materials", {})
	_assert_true(int(boss_bonus_materials.get("kitchen_blueprint_fragment", 0)) >= 1, "boss completion contributes explicit carryover materials")

	await _dispose_run_node(run_node)
	run_node = null

	_completed = false
	_summary.clear()
	run_node = run_scene.instantiate()
	root.add_child(run_node)
	if run_node.has_signal("session_completed"):
		run_node.connect("session_completed", Callable(self, "_on_session_completed"))
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": 9002,
		"session_duration_sec": 60.0
	})

	await _wait_frames(10)
	snapshot = run_node.call("debug_get_snapshot")
	var second_reef_scene_path := String(_find_room_snapshot(snapshot, "reef_patrol").get("scene_path", ""))
	_assert_true(
		not second_reef_scene_path.is_empty() and second_reef_scene_path != first_reef_scene_path,
		"different deterministic seeds pick different authored combat-room scenes"
	)
	run_node.call("debug_use_exit", "reef_patrol")
	await _wait_for_room_id(run_node, "reef_patrol")
	snapshot = run_node.call("debug_get_snapshot")
	var standard_room_content: Dictionary = snapshot.get("room_content", {})
	_assert_true(int(standard_room_content.get("cover_layer_z", 0)) >= 28, "standard room lifts authored cover into a dedicated foreground layer")
	_assert_true(int(standard_room_content.get("wall_visual_count", 0)) >= 4, "standard room exposes visible room-shell wall geometry")
	_assert_true(int(standard_room_content.get("cover_count", 0)) >= 3, "standard room exposes authored cover geometry")
	_assert_true(int(standard_room_content.get("cover_proxy_count", 0)) >= int(standard_room_content.get("cover_count", 0)), "standard room generates visible cover proxies for every authored blocker")
	_assert_true(int(standard_room_content.get("hazard_count", 0)) >= 1, "standard room exposes authored hazards")
	_assert_true(int(standard_room_content.get("explosive_count", 0)) >= 1, "standard room exposes authored explosive props")
	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	_assert_true(bool(run_node.call("debug_select_room_reward", 0)), "extraction test can still claim a room reward before leaving")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var extraction_snapshot: Dictionary = snapshot.get("extraction", {})
	_assert_true(bool(extraction_snapshot.get("available", false)), "early extraction becomes available after securing a combat room")
	_assert_true(bool(run_node.call("debug_request_extract")), "night run accepts an early extraction request from a secured room")
	await _wait_for_completion()
	_assert_true(_completed, "early extraction also completes the night run flow")
	_assert_equal(String(_summary.get("exit_reason", "")), "extracted", "early extract produces the extracted return reason")
	_assert_true(bool(_summary.get("dungeon_extracted_early", false)), "summary records that the run ended via early extraction")
	_assert_equal(String(_summary.get("dungeon_extraction_room_id", "")), "reef_patrol", "summary records which room the player extracted from")
	_assert_equal(String(_summary.get("dungeon_return_route_label", "")), "小艇提前撤离", "extraction return payload stays localized in Chinese")
	var carryover_materials: Dictionary = _summary.get("dungeon_carryover_materials", {})
	_assert_true(int(carryover_materials.get("scrap", 0)) >= 1, "extraction secures room-clear carryover materials")
	var carryover_rows: Array = _summary.get("dungeon_carryover_rows", [])
	_assert_true(int(carryover_rows.size()) >= 2, "summary includes a carryover breakdown for return presentation")
	_assert_true((_summary.get("dungeon_boss_bonus_materials", {}) as Dictionary).is_empty(), "early extraction leaves boss-only carryover behind")

	await _dispose_run_node(run_node)
	_finish()


func _run_cover_blocking_tests() -> void:
	var projectile_scene: PackedScene = load("res://scenes/projectile/Projectile.tscn")
	var cover_scene: PackedScene = load("res://scenes/night/rooms/setpieces/CoverWall.tscn")
	var pillar_scene: PackedScene = load("res://scenes/night/rooms/setpieces/CoverPillar.tscn")
	if projectile_scene == null:
		_fail("projectile cover test could not load Projectile.tscn")
		return
	if cover_scene == null:
		_fail("projectile cover test could not load CoverWall.tscn")
		return
	if pillar_scene == null:
		_fail("projectile cover test could not load CoverPillar.tscn")
		return
	var projectile_variant: Variant = projectile_scene.instantiate()
	var cover_variant: Variant = cover_scene.instantiate()
	var pillar_variant: Variant = pillar_scene.instantiate()
	if not (projectile_variant is Projectile):
		_fail("projectile cover test expected a Projectile instance")
		return
	if not (cover_variant is Node2D):
		_fail("projectile cover test expected a cover Node2D instance")
		return
	if not (pillar_variant is Node2D):
		_fail("projectile cover test expected a pillar Node2D instance")
		return
	var projectile: Projectile = projectile_variant
	var cover_node: Node2D = cover_variant
	var pillar_node: Node2D = pillar_variant
	root.add_child(projectile)
	root.add_child(cover_node)
	root.add_child(pillar_node)
	await _wait_frames(1)
	var cover_body: Node = cover_node.get_node_or_null("Body")
	_assert_true(cover_body != null, "cover scene exposes a dedicated body blocker")
	if cover_body != null:
		_assert_true(cover_body.is_in_group("ballistic_cover"), "cover body carries the ballistic cover group")
	_assert_true(cover_node.z_as_relative and cover_node.z_index == 0, "cover wall leaves foreground ordering to the authored room cover layer")
	_assert_true(cover_node.get_node_or_null("Shadow") != null, "cover wall exposes a visible shadow silhouette")
	_assert_true(cover_node.get_node_or_null("FaceInset") != null, "cover wall exposes a readable visible face")
	var pillar_body: Node = pillar_node.get_node_or_null("Body")
	_assert_true(pillar_body != null, "cover pillar exposes a dedicated body blocker")
	if pillar_body != null:
		_assert_true(pillar_body.is_in_group("ballistic_cover"), "cover pillar keeps the ballistic cover group")
	_assert_true(pillar_node.z_as_relative and pillar_node.z_index == 0, "cover pillar leaves foreground ordering to the authored room cover layer")
	_assert_true(pillar_node.get_node_or_null("Shadow") != null, "cover pillar exposes a visible shadow silhouette")
	_assert_true(pillar_node.get_node_or_null("FaceInset") != null, "cover pillar exposes a readable visible face")
	_assert_true((projectile.collision_mask & 8) != 0, "projectile collision mask includes the cover blocker layer")
	projectile.configure(Vector2.ZERO, Vector2.RIGHT, {}, null)
	await _wait_frames(1)
	if cover_body != null and projectile != null and is_instance_valid(projectile):
		projectile._on_body_entered(cover_body)
	var projectile_recycled := projectile == null or not is_instance_valid(projectile)
	if not projectile_recycled:
		projectile_recycled = not projectile.active
	_assert_true(projectile_recycled, "projectiles recycle immediately when they hit ballistic cover")
	await _wait_frames(1)
	if projectile != null and is_instance_valid(projectile):
		projectile.queue_free()
	if cover_node != null and is_instance_valid(cover_node):
		cover_node.queue_free()
	if pillar_node != null and is_instance_valid(pillar_node):
		pillar_node.queue_free()
	await process_frame


func _run_generator_validation_tests() -> void:
	var generator_script: Script = load("res://scripts/night/room_graph_generator.gd")
	var generator = generator_script.new()
	var room_types := {
		"rest": {
			"id": "rest",
			"label": "Rest",
			"scene": "res://scenes/night/rooms/TransitionRoom.tscn",
			"reward_on_enter": true
		},
		"combat": {
			"id": "combat",
			"label": "Combat",
			"scene": "res://scenes/night/rooms/CombatRoom.tscn",
			"locks_on_entry": true
		},
		"boss": {
			"id": "boss",
			"label": "Boss",
			"scene": "res://scenes/night/rooms/TransitionRoom.tscn",
			"is_goal": true,
			"locks_on_entry": true
		}
	}
	var room_templates := {
		"invalid_template": {
			"id": "invalid_template",
			"start_room_id": "ghost_start",
			"goal_room_id": "ghost_goal",
			"rooms": [
				{
					"id": "ghost_room",
					"room_type_id": "missing_type"
				}
			],
			"connections": []
		},
		"fallback_template": {
			"id": "fallback_template",
			"start_room_id": "camp",
			"goal_room_id": "boss_end",
			"rooms": [
				{
					"id": "camp",
					"room_type_id": "rest",
					"label": "Fallback Camp"
				},
				{
					"id": "route",
					"room_type_id": "combat",
					"label": "Fallback Route"
				},
				{
					"id": "boss_end",
					"room_type_id": "boss",
					"label": "Fallback Boss",
					"is_goal": true
				}
			],
			"connections": [
				{
					"from": "camp",
					"to": "route"
				},
				{
					"from": "route",
					"to": "missing_room"
				},
				{
					"from": "route",
					"to": "boss_end"
				}
			]
		}
	}
	var floor_rows: Array = [
		{
			"id": "validation_floor",
			"template_ids": [
				"missing_template",
				"invalid_template",
				"fallback_template"
			],
			"start_room_id": "broken_start",
			"goal_room_id": "broken_goal"
		}
	]
	var floors: Array = generator.call("build_floors_from_data", room_types, room_templates, floor_rows, 0)
	_assert_equal(int(floors.size()), 1, "room graph generator retries invalid template candidates until a valid floor builds")
	if floors.is_empty():
		return
	var floor_state = floors[0]
	_assert_equal(String(floor_state.template_id), "fallback_template", "room graph generator falls through to the next valid template")
	_assert_equal(String(floor_state.start_room_id), "camp", "invalid floor start falls back to the first valid room")
	_assert_equal(String(floor_state.goal_room_id), "boss_end", "invalid floor goal falls back to a reachable terminal room")
	var route_room = floor_state.get_room("route")
	_assert_true(route_room != null, "validated floor keeps the reachable combat room")
	if route_room != null:
		_assert_true(
			not route_room.connections.has("missing_room"),
			"validated floor strips broken room connections before the run starts"
		)


func _bootstrap_script_mode_singletons() -> void:
	if root.get_node_or_null("DataRegistry") == null:
		var registry_script: Script = load("res://scripts/core/data_registry.gd")
		var registry_instance: Node = registry_script.new()
		registry_instance.name = "DataRegistry"
		root.add_child(registry_instance)
	if root.get_node_or_null("FeedbackBus") == null:
		var feedback_script: Script = load("res://scripts/core/feedback_bus.gd")
		var feedback_instance: Node = feedback_script.new()
		feedback_instance.name = "FeedbackBus"
		root.add_child(feedback_instance)
	if root.get_node_or_null("TelegraphBus") == null:
		var telegraph_script: Script = load("res://scripts/core/telegraph_bus.gd")
		var telegraph_instance: Node = telegraph_script.new()
		telegraph_instance.name = "TelegraphBus"
		root.add_child(telegraph_instance)
	if root.get_node_or_null("ProfileStore") == null:
		var profile_script: Script = load("res://scripts/core/profile_store.gd")
		var profile_instance: Node = profile_script.new()
		profile_instance.name = "ProfileStore"
		root.add_child(profile_instance)
	if not bool(_registry().call("ensure_loaded")):
		_fail("night run scaffold test could not load DataRegistry")
		return
	_profile_store().call(
		"load_profile",
		_registry().call("get_default_character_id"),
		_registry().call("get_default_map_id")
	)


func _snapshot_has_locked_exit(snapshot: Dictionary) -> bool:
	var exits: Array = snapshot.get("available_exits", [])
	for exit_variant in exits:
		if not (exit_variant is Dictionary):
			continue
		if bool((exit_variant as Dictionary).get("locked", false)):
			return true
	return false


func _minimap_has_room_type(snapshot: Dictionary, room_type_id: String) -> bool:
	var minimap_snapshot: Dictionary = snapshot.get("minimap", {})
	var rooms: Array = minimap_snapshot.get("rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		if String((room_variant as Dictionary).get("room_type_id", "")) == room_type_id:
			return true
	return false


func _minimap_grid_spacing_is_valid(snapshot: Dictionary) -> bool:
	var minimap_snapshot: Dictionary = snapshot.get("minimap", {})
	var grid_spacing_variant: Variant = minimap_snapshot.get("grid_spacing", Vector2.ZERO)
	var grid_spacing := _coerce_vector2(grid_spacing_variant)
	return grid_spacing.x > 0.0 and grid_spacing.y > 0.0


func _minimap_room_has_positive_size(snapshot: Dictionary, room_id: String) -> bool:
	var room := _find_minimap_room(snapshot, room_id)
	if room.is_empty():
		return false
	var room_size := _coerce_vector2(room.get("map_size", Vector2.ZERO))
	return room_size.x > 0.0 and room_size.y > 0.0


func _minimap_room_area(snapshot: Dictionary, room_id: String) -> float:
	var room := _find_minimap_room(snapshot, room_id)
	if room.is_empty():
		return 0.0
	var room_size := _coerce_vector2(room.get("map_size", Vector2.ZERO))
	return room_size.x * room_size.y


func _minimap_room_position(snapshot: Dictionary, room_id: String) -> Vector2:
	var room := _find_minimap_room(snapshot, room_id)
	if room.is_empty():
		return Vector2.ZERO
	return _coerce_vector2(room.get("map_position", Vector2.ZERO))


func _find_minimap_room(snapshot: Dictionary, room_id: String) -> Dictionary:
	var minimap_snapshot: Dictionary = snapshot.get("minimap", {})
	var rooms: Array = minimap_snapshot.get("rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		if String(room.get("id", "")) == room_id:
			return room
	return {}


func _find_room_snapshot(snapshot: Dictionary, room_id: String) -> Dictionary:
	var rooms: Array = snapshot.get("floor_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		if String(room.get("id", "")) == room_id:
			return room
	return {}


func _reward_choice_has_kind(snapshot: Dictionary, reward_kind: String) -> bool:
	var rewards: Array = snapshot.get("reward_choices", [])
	for reward_variant in rewards:
		if not (reward_variant is Dictionary):
			continue
		if String((reward_variant as Dictionary).get("reward_kind", "")) == reward_kind:
			return true
	return false


func _reward_choices_are_localized(snapshot: Dictionary) -> bool:
	var rewards: Array = snapshot.get("reward_choices", [])
	if rewards.is_empty():
		return false
	for reward_variant in rewards:
		if not (reward_variant is Dictionary):
			return false
		var reward: Dictionary = reward_variant
		if not _contains_cjk(String(reward.get("reward_kind_label", ""))):
			return false
		if not _contains_cjk(String(reward.get("label", ""))):
			return false
		var summary := String(reward.get("summary", reward.get("description", ""))).strip_edges()
		if not summary.is_empty() and not _contains_cjk(summary):
			return false
	return true


func _contains_cjk(text: String) -> bool:
	for index in range(text.length()):
		var codepoint := text.unicode_at(index)
		if int(codepoint) >= 0x4e00 and int(codepoint) <= 0x9fff:
			return true
	return false


func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array:
		var parts: Array = value
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value is Dictionary:
		var payload: Dictionary = value
		return Vector2(float(payload.get("x", 0.0)), float(payload.get("y", 0.0)))
	return Vector2.ZERO


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


func _localization() -> Node:
	return root.get_node_or_null("Localization")


func _wait_frames(count: int) -> void:
	for _index in range(maxi(1, count)):
		await process_frame


func _wait_for_room_id(run_node: Node, expected_room_id: String, max_frames: int = 720) -> void:
	for _index in range(maxi(1, max_frames)):
		var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
		if snapshot_variant is Dictionary:
			var snapshot: Dictionary = snapshot_variant
			if String(snapshot.get("room_id", "")) == expected_room_id and String(snapshot.get("state", "")) != "transiting":
				return
		await process_frame


func _wait_for_completion(max_frames: int = 720) -> void:
	for _index in range(maxi(1, max_frames)):
		if _completed:
			return
		await process_frame


func _dispose_run_node(run_node: Node) -> void:
	if run_node == null or not is_instance_valid(run_node):
		return
	var completed_callable := Callable(self, "_on_session_completed")
	if run_node.has_signal("session_completed") and run_node.is_connected("session_completed", completed_callable):
		run_node.disconnect("session_completed", completed_callable)
	if run_node.has_method("stop_session"):
		run_node.call("stop_session")
	run_node.queue_free()
	await process_frame
	await process_frame


func _on_session_completed(summary: Dictionary) -> void:
	_completed = true
	_summary = summary.duplicate(true)


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_fail(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual == expected:
		print("PASS: %s" % label)
		return
	_fail("%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	failed += 1
	push_error(message)
	print("FAIL: %s" % message)


func _finish() -> void:
	if _finish_requested:
		return
	_finish_requested = true
	var localization := _localization()
	if localization != null and localization.has_method("set_language_code"):
		localization.call("set_language_code", _original_language_code)
	print("NightRun scaffold test finished. failed=%d" % failed)
	call_deferred("_quit_after_cleanup", failed)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
