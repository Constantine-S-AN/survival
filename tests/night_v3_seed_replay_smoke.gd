extends SceneTree

const ROUTE_A_SEED := 9000
const ROUTE_B_SEED := 9003
const ROUTE_A_TEMPLATE_ID := "harbor_rift_v2_route_a"
const ROUTE_B_TEMPLATE_ID := "sunken_exchange_v2_route_b"
const ROUTE_A_MINIBOSS_ENCOUNTER_ID := "pressure_lock_trial"
const ROUTE_B_BOSS_ENCOUNTER_ID := "customs_leviathan_trial"

var failed: int = 0
var _completed: bool = false
var _summary: Dictionary = {}
var _shop_replay_offer_ids: Array[String] = []
var _finish_requested: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	await _run_hidden_reveal_replay()
	await _run_hidden_breach_replay()
	await _run_hidden_condition_replay()
	await _run_shop_replay()
	await _run_shop_theme_replay()
	await _run_shrine_replay()
	await _run_miniboss_extract_replay()
	await _run_boss_replay()
	_finish()


func _run_hidden_reveal_replay() -> void:
	var seed := ROUTE_A_SEED
	var stage := "hidden_clear"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_A_TEMPLATE_ID, "route-a replay seed resolves the expected floor template")

	await _clear_and_claim_combat_room(run_node, seed, stage, "turret_cache", 0)
	run_node.call("debug_use_exit", "swarm_nest")
	await _wait_for_room_id(run_node, "swarm_nest")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, not _snapshot_has_exit(snapshot, "smuggler_cut"), "hidden room exit stays concealed before the reveal room is cleared")
	_assert_stage_true(seed, stage, not _snapshot_has_room(snapshot, "smuggler_cut"), "hidden room stays off the floor snapshot before reveal")

	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed, stage, bool(reward_snapshot.get("reward_panel_visible", false)), "hidden-room source room still opens its reward panel")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, _snapshot_has_exit(snapshot, "smuggler_cut"), "clearing the reveal room exposes the hidden exit")
	_assert_stage_true(seed, stage, _snapshot_has_room(snapshot, "smuggler_cut"), "clearing the reveal room exposes the hidden room on the floor snapshot")
	var hidden_room_snapshot := _snapshot_room(snapshot, "smuggler_cut")
	_assert_stage_equal(seed, stage, String(hidden_room_snapshot.get("hidden_reveal_type", "")), "clear_source", "clear-source reveal keeps its authored reveal type on the floor snapshot")
	var hidden_reveal_entry := _snapshot_hidden_reveal_entry(snapshot, "smuggler_cut")
	_assert_stage_equal(seed, stage, String(hidden_reveal_entry.get("reveal_type", "")), "clear_source", "clear-source reveal logs its reveal type in runtime state")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", 0)), "hidden-room source reward remains claimable after the reveal")
	await _wait_frames(2)

	run_node.call("debug_use_exit", "smuggler_cut")
	await _wait_for_room_id(run_node, "smuggler_cut")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "smuggler_cut", "hidden room replay reaches the revealed room")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_type_id", "")), "treasure", "revealed hidden room keeps the treasure-room shell")
	_assert_stage_true(seed, stage, bool(snapshot.get("room_reward_claimed", false)), "hidden treasure room auto-claims on entry")
	_assert_stage_equal(seed, stage, _route_resource_count(snapshot, "key"), 0, "hidden room replay spends one route key on entry")
	_assert_stage_true(seed, stage, _route_resource_count(snapshot, "contract") >= 2, "hidden room replay grants a contract after the hidden cache is claimed")

	await _dispose_run_node(run_node)


func _run_hidden_breach_replay() -> void:
	var seed := ROUTE_A_SEED
	var stage := "hidden_breach"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, seed, stage, "turret_cache", 0)
	run_node.call("debug_use_exit", "echo_bazaar")
	await _wait_for_room_id(run_node, "echo_bazaar")
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, not _snapshot_has_exit(snapshot, "brine_cache"), "breach reveal keeps the secret exit concealed before interaction")
	_assert_stage_true(seed, stage, not _snapshot_has_room(snapshot, "brine_cache"), "breach reveal keeps the secret room off the map before interaction")
	var breach_interaction := _find_interaction_snapshot(snapshot, "breach", "brine_cache")
	_assert_stage_true(seed, stage, not breach_interaction.is_empty(), "breach reveal exposes a dedicated wall-breach interaction")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature", String(breach_interaction.get("interaction_id", "")))), "breach reveal interaction can be activated explicitly")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, _snapshot_has_exit(snapshot, "brine_cache"), "breach reveal exposes the secret exit after interaction")
	_assert_stage_true(seed, stage, _snapshot_has_room(snapshot, "brine_cache"), "breach reveal exposes the secret room on the floor snapshot after interaction")
	var hidden_room_snapshot := _snapshot_room(snapshot, "brine_cache")
	_assert_stage_equal(seed, stage, String(hidden_room_snapshot.get("hidden_reveal_type", "")), "breach_wall", "breach reveal keeps its authored reveal type on the floor snapshot")
	var hidden_reveal_entry := _snapshot_hidden_reveal_entry(snapshot, "brine_cache")
	_assert_stage_equal(seed, stage, String(hidden_reveal_entry.get("reveal_type", "")), "breach_wall", "breach reveal logs its reveal type in runtime state")
	_assert_stage_equal(seed, stage, int((snapshot.get("interactions", []) as Array).size()), 1, "breach reveal removes only the breach interaction and keeps the shop interaction alive")
	run_node.call("debug_use_exit", "brine_cache")
	await _wait_for_room_id(run_node, "brine_cache")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "brine_cache", "breach replay reaches the revealed secret cache")
	_assert_stage_true(seed, stage, bool(snapshot.get("room_reward_claimed", false)), "breach replay auto-claims the hidden cache reward on entry")
	await _dispose_run_node(run_node)


func _run_hidden_condition_replay() -> void:
	var seed := ROUTE_B_SEED
	var stage := "hidden_condition"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, seed, stage, "salt_vault", 0)
	run_node.call("debug_use_exit", "rust_market")
	await _wait_for_room_id(run_node, "rust_market")
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, _snapshot_has_exit(snapshot, "contraband_lockup"), "condition reveal exposes the secret exit once the prerequisite room is cleared")
	_assert_stage_true(seed, stage, _snapshot_has_room(snapshot, "contraband_lockup"), "condition reveal exposes the secret room on the floor snapshot")
	var hidden_room_snapshot := _snapshot_room(snapshot, "contraband_lockup")
	_assert_stage_equal(seed, stage, String(hidden_room_snapshot.get("hidden_reveal_type", "")), "condition", "condition reveal keeps its authored reveal type on the floor snapshot")
	var hidden_reveal_entry := _snapshot_hidden_reveal_entry(snapshot, "contraband_lockup")
	_assert_stage_equal(seed, stage, String(hidden_reveal_entry.get("reveal_type", "")), "condition", "condition reveal logs its reveal type in runtime state")
	run_node.call("debug_use_exit", "contraband_lockup")
	await _wait_for_room_id(run_node, "contraband_lockup")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, bool(snapshot.get("room_reward_claimed", false)), "condition reveal reaches and auto-claims the revealed contraband cache")
	await _dispose_run_node(run_node)


func _run_shop_replay() -> void:
	var seed := ROUTE_A_SEED
	var stage := "shop"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_A_TEMPLATE_ID, "shop replay seed resolves the expected floor template")

	await _clear_and_claim_combat_room(run_node, seed, stage, "turret_cache", 0)
	run_node.call("debug_use_exit", "echo_bazaar")
	await _wait_for_room_id(run_node, "echo_bazaar")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "echo_bazaar", "shop replay reaches the deterministic second shop room")
	_assert_stage_equal(seed, stage, int((snapshot.get("interactions", []) as Array).size()), 2, "shop replay spawns both the shop and breach runtime interactions")
	_assert_stage_true(seed, stage, not _find_interaction_snapshot(snapshot, "shop").is_empty(), "shop replay keeps the shop interaction available in the multi-interaction room")
	_assert_stage_true(seed, stage, not _find_interaction_snapshot(snapshot, "breach", "brine_cache").is_empty(), "shop replay keeps the breach interaction available in the multi-interaction room")

	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("xp", 220.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	var xp_before := float(((run_node.call("debug_get_snapshot") as Dictionary).get("player_hud", {}) as Dictionary).get("xp", 0.0))
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature")), "shop replay opens the room interaction")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_stage_equal(seed, stage, int(reward_choices.size()), 3, "shop replay shows three purchasable offers")
	var shop_state: Dictionary = reward_snapshot.get("shop_state", {})
	_assert_stage_equal(seed, stage, String(shop_state.get("theme_id", "")), "harbor_rift", "shop replay snapshot records the harbor theme")
	_assert_stage_true(seed, stage, _shop_state_has_rare_slot(shop_state), "shop replay exposes a rare slot in the tier-2 market")
	_assert_stage_equal(seed, stage, _shop_offer_id_at(reward_choices, 0), "route_key_cache", "shop replay pins the route-key cache into the premium bundle slot")
	_assert_stage_true(seed, stage, _offer_grants_route_resource(reward_choices[0], "key"), "shop replay premium cache grants a route key")
	var initial_offer_ids := _shop_offer_ids(reward_choices)
	_assert_stage_true(seed, stage, bool(run_node.call("debug_toggle_shop_lock", 0)), "shop replay can lock the first slot")
	await _wait_frames(1)
	_assert_stage_true(seed, stage, bool(run_node.call("debug_refresh_shop")), "shop replay can refresh the current shop session")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_after_refresh := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	shop_state = snapshot.get("shop_state", {})
	var refreshed_offer_ids := _shop_offer_ids_from_state(shop_state)
	_shop_replay_offer_ids = refreshed_offer_ids.duplicate()
	_assert_stage_true(seed, stage, xp_after_refresh < xp_before, "shop replay deducts XP after refresh")
	_assert_stage_equal(seed, stage, int(shop_state.get("refresh_count", 0)), 1, "shop replay tracks refresh count in the snapshot")
	_assert_stage_equal(seed, stage, refreshed_offer_ids[0] if not refreshed_offer_ids.is_empty() else "", initial_offer_ids[0] if not initial_offer_ids.is_empty() else "", "shop replay keeps the locked slot stable across refresh")
	_assert_stage_equal(seed, stage, int(refreshed_offer_ids.size()), int(initial_offer_ids.size()), "shop replay keeps the unlocked slot count stable after refresh")
	_assert_stage_true(seed, stage, int((shop_state.get("actions", []) as Array).size()) >= 2, "shop replay records lock and refresh actions in the snapshot")
	_assert_stage_true(seed, stage, bool(snapshot.get("reward_panel_visible", false)), "shop replay keeps the refreshed market panel open for follow-up decisions")
	reward_choices = snapshot.get("reward_choices", [])
	var purchase_index := 0
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", purchase_index)), "shop replay can purchase a refreshed offer")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_after_purchase := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	shop_state = snapshot.get("shop_state", {})
	_assert_stage_true(seed, stage, xp_after_purchase < xp_after_refresh, "shop replay deducts XP after purchase")
	_assert_stage_true(seed, stage, _route_resource_count(snapshot, "key") >= 2, "shop replay purchase adds one route key into the route ledger")
	_assert_stage_true(seed, stage, not bool(snapshot.get("room_reward_claimed", false)), "shop replay keeps the shop room reusable after purchase")
	_assert_stage_equal(seed, stage, int((snapshot.get("interactions", []) as Array).size()), 2, "shop replay keeps both room interactions alive after purchase")
	_assert_stage_true(seed, stage, int((shop_state.get("actions", []) as Array).size()) >= 3, "shop replay records purchase actions in the snapshot")

	await _dispose_run_node(run_node)


func _run_shop_theme_replay() -> void:
	var seed := ROUTE_B_SEED
	var stage := "shop_theme"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, seed, stage, "salt_vault", 0)
	run_node.call("debug_use_exit", "rust_market")
	await _wait_for_room_id(run_node, "rust_market")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_adjust_route_resource", "curse", 1)), "shop-theme replay can inject one curse for the cleanse-path validation")
	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("xp", 220.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "rust_market", "shop-theme replay reaches the deterministic second-floor market")
	_assert_stage_equal(seed, stage, _route_resource_count(snapshot, "curse"), 1, "shop-theme replay starts the market validation with one route curse")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature")), "shop-theme replay opens the market interaction")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	var shop_state: Dictionary = reward_snapshot.get("shop_state", {})
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_stage_equal(seed, stage, String(shop_state.get("theme_id", "")), "sunken_exchange", "shop-theme replay snapshot records the second floor theme")
	_assert_stage_true(seed, stage, _shop_state_has_rare_slot(shop_state), "shop-theme replay keeps the rare slot on the exchange theme")
	_assert_stage_true(seed, stage, _shop_offer_ids(reward_choices) != _shop_replay_offer_ids, "shop-theme replay rolls a different pool from the harbor market")
	_assert_stage_equal(seed, stage, _shop_offer_id_at(reward_choices, 0), "route_curse_cleanse", "shop-theme replay pins the curse-cleanse cache into the premium bundle slot")
	_assert_stage_true(seed, stage, _offer_costs_route_resource(reward_choices[0], "curse"), "shop-theme replay premium cache spends one curse")
	var initial_rare_slot_index := _find_rare_slot_index(reward_choices)
	_assert_stage_true(seed, stage, initial_rare_slot_index >= 0, "shop-theme replay exposes a relic offer in the rare slot")
	var initial_rare_offer: Dictionary = reward_choices[initial_rare_slot_index] if initial_rare_slot_index >= 0 and reward_choices[initial_rare_slot_index] is Dictionary else {}
	var initial_rare_modifier_id := String(initial_rare_offer.get("modifier_id", "")).strip_edges()
	_assert_stage_equal(seed, stage, String(initial_rare_offer.get("reward_kind", "")), "relic", "shop-theme replay upgrades the rare slot into a relic reward")
	_assert_stage_true(seed, stage, not initial_rare_modifier_id.is_empty(), "shop-theme replay keeps a concrete relic id on the rare-slot offer")
	_assert_stage_true(seed, stage, not String(initial_rare_offer.get("relic_rarity", "")).strip_edges().is_empty(), "shop-theme replay keeps the relic rarity metadata on the reward offer")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", 0)), "shop-theme replay can purchase the curse-cleanse route bundle")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, _route_resource_count(snapshot, "curse"), 0, "shop-theme replay purchase removes the injected curse from the route ledger")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature")), "shop-theme replay can reopen the market after the premium cache purchase")
	reward_snapshot = await _wait_for_reward_panel(run_node)
	reward_choices = reward_snapshot.get("reward_choices", [])
	var rare_slot_index := _find_rare_slot_index(reward_choices)
	_assert_stage_true(seed, stage, rare_slot_index >= 0, "shop-theme replay keeps the relic rare slot available after the premium cache purchase")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", rare_slot_index)), "shop-theme replay can purchase the rare-slot relic through the shared market flow")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var modifier_snapshot: Dictionary = snapshot.get("run_modifier_state", {})
	var claimed_relics: Array = modifier_snapshot.get("claimed_relics", [])
	_assert_stage_equal(seed, stage, int(claimed_relics.size()), 1, "shop-theme replay records one claimed relic after the rare-slot purchase")
	var claimed_relic: Dictionary = claimed_relics[0] if not claimed_relics.is_empty() and claimed_relics[0] is Dictionary else {}
	_assert_stage_equal(seed, stage, String(claimed_relic.get("id", "")), initial_rare_modifier_id, "shop-theme replay summary state preserves the purchased rare-slot relic id")
	var reward_multipliers: Dictionary = modifier_snapshot.get("reward_multipliers", {})
	_assert_stage_true(seed, stage, float(reward_multipliers.get("meta_currency", 1.0)) > 1.20, "shop-theme replay applies the relic reward multiplier into the live run state")
	await _dispose_run_node(run_node)


func _run_shrine_replay() -> void:
	var seed := ROUTE_A_SEED
	var stage := "shrine"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_A_TEMPLATE_ID, "shrine replay seed resolves the expected floor template")

	await _clear_and_claim_combat_room(run_node, seed, stage, "turret_cache", 0)
	run_node.call("debug_use_exit", "swarm_nest")
	await _wait_for_room_id(run_node, "swarm_nest")
	await _clear_and_claim_combat_room(run_node, seed, stage, "swarm_nest", 1)
	run_node.call("debug_use_exit", "undertow_altar")
	await _wait_for_room_id(run_node, "undertow_altar")

	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "undertow_altar", "shrine replay reaches the deterministic shrine room")
	_assert_stage_equal(seed, stage, int((snapshot.get("interactions", []) as Array).size()), 1, "shrine replay spawns one runtime interaction node")
	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("hp", 52.0)
		player.set("noise", 6.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature")), "shrine replay opens the room interaction")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_stage_equal(seed, stage, int(reward_choices.size()), 3, "shrine replay shows three blessing offers")
	_assert_stage_equal(seed, stage, int(_shrine_direction_ids(reward_choices).size()), 3, "shrine replay exposes one blessing per directed build lane")
	var cost_types := _shrine_cost_types(reward_choices)
	_assert_stage_true(seed, stage, cost_types.has("hp"), "shrine replay includes an HP cost lane")
	_assert_stage_true(seed, stage, cost_types.has("noise"), "shrine replay includes a noise cost lane")
	_assert_stage_true(seed, stage, cost_types.has("curse"), "shrine replay includes a curse cost lane")
	var initial_offer_ids := _shop_offer_ids(reward_choices)
	for reward_variant in reward_choices:
		if not (reward_variant is Dictionary):
			continue
		_assert_stage_equal(seed, stage, String((reward_variant as Dictionary).get("reward_kind", "")), "blessing", "shrine replay keeps all offers in the blessing category")
		_assert_stage_true(seed, stage, not String((reward_variant as Dictionary).get("shrine_direction_label", "")).strip_edges().is_empty(), "shrine replay exposes direction labels on each blessing")
	var shrine_state: Dictionary = reward_snapshot.get("shrine_state", {})
	_assert_stage_equal(seed, stage, String(shrine_state.get("pool_id", "")), "undertow_altar_pool", "shrine replay snapshot records the undertow altar pool")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_reject_room_interaction")), "shrine replay supports rejecting the current blessing set")
	await _wait_frames(1)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, not bool(snapshot.get("reward_panel_visible", false)), "shrine replay hides the panel after a rejection")
	_assert_stage_true(seed, stage, not bool(snapshot.get("room_reward_claimed", false)), "shrine replay keeps the shrine room reusable after rejection")
	_assert_stage_equal(seed, stage, int((snapshot.get("interactions", []) as Array).size()), 1, "shrine replay keeps the shrine interaction node after rejection")
	_assert_stage_true(seed, stage, _summaryless_shrine_has_action(snapshot, "reject"), "shrine replay snapshot records the reject action")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature")), "shrine replay can reopen the rejected shrine")
	reward_snapshot = await _wait_for_reward_panel(run_node)
	reward_choices = reward_snapshot.get("reward_choices", [])
	_assert_stage_equal(seed, stage, _shop_offer_ids(reward_choices), initial_offer_ids, "shrine replay keeps the same directed offers when reopened")
	var selected_index := _find_offer_index_by_cost_type(reward_choices, "curse")
	_assert_stage_true(seed, stage, selected_index >= 0, "shrine replay exposes a curse-cost blessing lane")
	var selected_offer: Dictionary = reward_choices[selected_index] if reward_choices[selected_index] is Dictionary else {}
	var selected_direction_id := String(selected_offer.get("shrine_direction_id", "")).strip_edges().to_lower()
	var selected_cost_value := int(selected_offer.get("cost_value", 0))
	_assert_stage_true(seed, stage, _offer_costs_route_resource(selected_offer, "contract"), "shrine replay return lane spends a contract")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", selected_index)), "shrine replay can claim a blessing after rejection")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, bool(snapshot.get("room_reward_claimed", false)), "shrine replay marks the room reward as claimed after blessing")
	_assert_stage_equal(seed, stage, int((snapshot.get("interactions", []) as Array).size()), 0, "shrine replay removes the interaction node after blessing acceptance")
	shrine_state = snapshot.get("shrine_state", {})
	_assert_stage_equal(seed, stage, String(shrine_state.get("accepted_direction_id", "")), selected_direction_id, "shrine replay snapshot records the accepted direction")
	_assert_stage_true(seed, stage, int((snapshot.get("shrine_action_log", []) as Array).size()) >= 2, "shrine replay snapshot retains both reject and accept actions")
	var modifier_snapshot: Dictionary = snapshot.get("run_modifier_state", {})
	_assert_stage_true(seed, stage, int(modifier_snapshot.get("curse_level", 0)) >= selected_cost_value, "shrine replay applies the curse cost into run modifier state")
	_assert_stage_equal(seed, stage, _route_resource_count(snapshot, "contract"), 0, "shrine replay spends the route contract after accepting the return blessing")

	run_node.call("debug_use_exit", "pressure_lock")
	await _wait_for_room_id(run_node, "pressure_lock")
	run_node.call("debug_force_clear_room")
	var pressure_reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed, stage, bool(pressure_reward_snapshot.get("reward_panel_visible", false)), "shrine replay still reaches the deterministic extraction route after the shrine")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", 0)), "shrine replay can claim the post-shrine combat reward")
	await _wait_frames(2)
	_assert_stage_true(seed, stage, bool(run_node.call("debug_request_extract")), "shrine replay can extract after the post-shrine route")
	await _wait_for_completion()

	_assert_stage_true(seed, stage, _completed, "shrine replay completes after the post-shrine extraction")
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_shrine_accept_count", 0)), 1, "shrine replay summary tracks one accepted shrine choice")
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_shrine_reject_count", 0)), 1, "shrine replay summary tracks one rejected shrine choice")
	_assert_stage_true(seed, stage, _summary_has_shrine_action("reject"), "shrine replay summary keeps the reject action")
	_assert_stage_true(seed, stage, _summary_has_shrine_action("accept"), "shrine replay summary keeps the accept action")
	var summary_room := _summary_shrine_room("undertow_altar")
	_assert_stage_equal(seed, stage, String(summary_room.get("accepted_direction_id", "")), selected_direction_id, "shrine replay summary preserves the accepted direction on the room record")
	_assert_stage_true(seed, stage, int((_summary.get("dungeon_curse_events", []) as Array).size()) >= 1, "shrine replay summary records the curse event from the accepted blessing")
	_assert_stage_true(seed, stage, int(_summary.get("dungeon_curse_level", 0)) >= selected_cost_value, "shrine replay summary preserves the applied curse level")
	_assert_stage_true(seed, stage, _summary.get("dungeon_route_resource_flow", {}) is Dictionary, "shrine replay summary preserves route-resource flow payload")
	var route_flow: Dictionary = _summary.get("dungeon_route_resource_flow", {})
	_assert_stage_equal(seed, stage, int((route_flow.get("spent", {}) as Dictionary).get("contract", 0)), 1, "shrine replay summary records the spent contract in route-resource flow")

	await _dispose_run_node(run_node)


func _run_miniboss_extract_replay() -> void:
	var seed := ROUTE_A_SEED
	var stage := "miniboss_extract"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_A_TEMPLATE_ID, "miniboss replay seed resolves the expected floor template")

	await _clear_and_claim_combat_room(run_node, seed, stage, "reef_patrol", 0)
	run_node.call("debug_use_exit", "relay_beacon")
	await _wait_for_room_id(run_node, "relay_beacon")
	await _clear_and_claim_combat_room(run_node, seed, stage, "relay_beacon", 1)
	run_node.call("debug_use_exit", "pressure_lock")
	await _wait_for_room_id(run_node, "pressure_lock")

	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "pressure_lock", "miniboss replay reaches the deterministic pressure-lock room")
	_assert_stage_equal(seed, stage, String(snapshot.get("encounter_id", "")), ROUTE_A_MINIBOSS_ENCOUNTER_ID, "miniboss replay enters the expected challenge encounter")
	_assert_stage_equal(seed, stage, String(snapshot.get("encounter_category", "")), "elite", "miniboss replay keeps the encounter in the elite category")

	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed, stage, bool(reward_snapshot.get("reward_panel_visible", false)), "miniboss replay opens the reward panel after clear")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", 0)), "miniboss replay can still claim a room reward")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var extraction_snapshot: Dictionary = snapshot.get("extraction", {})
	_assert_stage_true(seed, stage, bool(extraction_snapshot.get("available", false)), "miniboss replay unlocks early extraction after the room is secured")
	var runtime_peak_room := _snapshot_peak_room(snapshot, "pressure_lock")
	_assert_stage_equal(seed, stage, String(runtime_peak_room.get("peak_room_kind", "")), "miniboss", "miniboss replay runtime state records the cleared pressure-lock peak room")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_request_extract")), "miniboss replay accepts an extraction request")
	await _wait_for_completion()

	_assert_stage_true(seed, stage, _completed, "miniboss replay completes the run after extraction")
	_assert_stage_equal(seed, stage, String(_summary.get("exit_reason", "")), "extracted", "miniboss replay records the extracted outcome")
	_assert_stage_true(seed, stage, bool(_summary.get("dungeon_extracted_early", false)), "miniboss replay flags the early extraction path")
	_assert_stage_equal(seed, stage, String(_summary.get("dungeon_extraction_room_id", "")), "pressure_lock", "miniboss replay records the extraction room id")
	_assert_stage_true(seed, stage, (_summary.get("dungeon_room_path", []) as Array).has("pressure_lock"), "miniboss replay summary preserves the visited miniboss room in the route path")
	var summary_peak_room := _summary_peak_room("pressure_lock")
	_assert_stage_equal(seed, stage, String(summary_peak_room.get("peak_room_kind", "")), "miniboss", "miniboss replay summary preserves the pressure-lock peak room kind")
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_peak_clear_count", 0)), 1, "miniboss replay summary records one cleared peak room")

	await _dispose_run_node(run_node)


func _run_boss_replay() -> void:
	var seed := ROUTE_B_SEED
	var stage := "boss"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_B_TEMPLATE_ID, "boss replay seed resolves the expected floor template")

	await _clear_and_claim_combat_room(run_node, seed, stage, "salt_vault", 0)
	run_node.call("debug_use_exit", "rust_market")
	await _wait_for_room_id(run_node, "rust_market")
	var market_snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_true(seed, stage, _snapshot_has_exit(market_snapshot, "contraband_lockup"), "boss replay reuses the condition-reveal path before the boss")
	run_node.call("debug_use_exit", "customs_gate")
	await _wait_for_room_id(run_node, "customs_gate")
	await _clear_and_claim_combat_room(run_node, seed, stage, "customs_gate", 0)
	run_node.call("debug_use_exit", "apex_guardian")
	await _wait_for_room_id(run_node, "apex_guardian")
	await _wait_frames(2)

	snapshot = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), "apex_guardian", "boss replay reaches the stable boss endpoint")
	_assert_stage_equal(seed, stage, String(snapshot.get("room_type_id", "")), "boss", "boss replay marks the final room as a boss room")
	_assert_stage_equal(seed, stage, String(snapshot.get("encounter_id", "")), ROUTE_B_BOSS_ENCOUNTER_ID, "boss replay enters the deterministic second-floor boss encounter")

	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed, stage, bool(reward_snapshot.get("reward_panel_visible", false)), "boss replay opens the final reward panel")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", 0)), "boss replay can claim the final reward")
	await _wait_for_completion()

	_assert_stage_true(seed, stage, _completed, "boss replay completes the run after the final reward")
	_assert_stage_equal(seed, stage, String(_summary.get("exit_reason", "")), "completed", "boss replay records the completed outcome")
	_assert_stage_true(seed, stage, bool(_summary.get("dungeon_boss_cleared", false)), "boss replay flags the boss as cleared")
	_assert_stage_equal(seed, stage, String(_summary.get("dungeon_last_encounter_id", "")), ROUTE_B_BOSS_ENCOUNTER_ID, "boss replay summary preserves the final boss encounter id")
	_assert_true(int((_summary.get("dungeon_boss_bonus_materials", {}) as Dictionary).size()) >= 1, _stage_label(seed, stage, "boss replay carries boss bonus materials into the summary"))
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_hidden_reveal_count", 0)), 1, "boss replay summary records one hidden reveal on the condition route")
	var summary_hidden_reveal := _summary_hidden_reveal_entry("contraband_lockup")
	_assert_stage_equal(seed, stage, String(summary_hidden_reveal.get("reveal_type", "")), "condition", "boss replay summary preserves the hidden room reveal type")
	var summary_peak_room := _summary_peak_room("customs_gate")
	_assert_stage_equal(seed, stage, String(summary_peak_room.get("peak_room_kind", "")), "miniboss", "boss replay summary still preserves the fixed customs-gate peak room kind before the boss")
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_peak_clear_count", 0)), 1, "boss replay summary records one cleared peak room on the route to the boss")

	await _dispose_run_node(run_node)


func _start_run(seed_value: int, stage: String) -> Node:
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail(_stage_label(seed_value, stage, "could not load NightRun.tscn"))
		return null
	_completed = false
	_summary.clear()
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
	if run_node.has_signal("session_completed"):
		run_node.connect("session_completed", Callable(self, "_on_session_completed"))
	print("Seed replay start: seed=%d stage=%s" % [seed_value, stage])
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": seed_value,
		"session_duration_sec": 60.0
	})
	await _wait_frames(10)
	return run_node


func _clear_and_claim_combat_room(run_node: Node, seed_value: int, stage: String, target_room_id: String, reward_index: int) -> void:
	var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
	if snapshot_variant is Dictionary:
		var snapshot: Dictionary = snapshot_variant
		if String(snapshot.get("room_id", "")) != target_room_id:
			run_node.call("debug_use_exit", target_room_id)
			await _wait_for_room_id(run_node, target_room_id)
	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed_value, stage, bool(reward_snapshot.get("reward_panel_visible", false)), "room %s opens a reward panel before advancing" % target_room_id)
	_assert_stage_true(seed_value, stage, bool(run_node.call("debug_select_room_reward", reward_index)), "room %s reward can be claimed before advancing" % target_room_id)
	await _wait_frames(2)


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
	if _registry().call("ensure_loaded") != true:
		_fail("Seed replay smoke could not load DataRegistry")
		return
	_profile_store().call("load_profile", _registry().call("get_default_character_id"), _registry().call("get_default_map_id"))


func _find_player(run_node: Node) -> Node:
	if run_node == null or not is_instance_valid(run_node):
		return null
	for node in run_node.find_children("*", "Node", true, false):
		if String(node.name) == "Player" and node.has_method("get_hud_data"):
			return node
	return null


func _snapshot_has_room(snapshot: Dictionary, room_id: String) -> bool:
	var rooms: Array = snapshot.get("floor_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		if String((room_variant as Dictionary).get("id", "")) == room_id:
			return true
	return false


func _snapshot_room(snapshot: Dictionary, room_id: String) -> Dictionary:
	var rooms: Array = snapshot.get("floor_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		if String(room.get("id", "")).strip_edges() == room_id:
			return room
	return {}


func _snapshot_has_exit(snapshot: Dictionary, room_id: String) -> bool:
	var exits: Array = snapshot.get("available_exits", [])
	for exit_variant in exits:
		if not (exit_variant is Dictionary):
			continue
		if String((exit_variant as Dictionary).get("target_room_id", "")) == room_id:
			return true
	return false


func _find_interaction_snapshot(snapshot: Dictionary, interaction_kind: String, target_room_id: String = "") -> Dictionary:
	var normalized_kind := interaction_kind.strip_edges().to_lower()
	var normalized_target := target_room_id.strip_edges().to_lower()
	var interactions: Array = snapshot.get("interactions", [])
	for interaction_variant in interactions:
		if not (interaction_variant is Dictionary):
			continue
		var interaction: Dictionary = interaction_variant
		if String(interaction.get("interaction_kind", "")).strip_edges().to_lower() != normalized_kind:
			continue
		if not normalized_target.is_empty() and String(interaction.get("target_room_id", "")).strip_edges().to_lower() != normalized_target:
			continue
		return interaction
	return {}


func _snapshot_hidden_reveal_entry(snapshot: Dictionary, room_id: String) -> Dictionary:
	var normalized_room_id := room_id.strip_edges().to_lower()
	var entries: Array = snapshot.get("hidden_reveal_log", [])
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("room_id", "")).strip_edges().to_lower() == normalized_room_id:
			return entry
	return {}


func _snapshot_peak_room(snapshot: Dictionary, room_id: String) -> Dictionary:
	var normalized_room_id := room_id.strip_edges().to_lower()
	var peak_rooms: Array = snapshot.get("peak_rooms", [])
	for entry_variant in peak_rooms:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("room_id", "")).strip_edges().to_lower() == normalized_room_id:
			return entry
	return {}


func _shop_offer_ids(items_variant: Variant) -> Array[String]:
	var ids: Array[String] = []
	if not (items_variant is Array):
		return ids
	var items: Array = items_variant
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var offer_id := String(
			item.get("offer_id", item.get("shop_entry_id", item.get("modifier_id", item.get("id", ""))))
		).strip_edges().to_lower()
		if offer_id.is_empty():
			continue
		ids.append(offer_id)
	return ids


func _shop_offer_ids_from_state(shop_state: Dictionary) -> Array[String]:
	return _shop_offer_ids(shop_state.get("slots", []))


func _shop_offer_id_at(items_variant: Variant, index: int) -> String:
	if not (items_variant is Array):
		return ""
	var items: Array = items_variant
	if index < 0 or index >= items.size() or not (items[index] is Dictionary):
		return ""
	return String((items[index] as Dictionary).get("offer_id", (items[index] as Dictionary).get("shop_entry_id", ""))).strip_edges().to_lower()


func _shop_state_has_rare_slot(shop_state: Dictionary) -> bool:
	var slots_variant: Variant = shop_state.get("slots", [])
	if not (slots_variant is Array):
		return false
	var slots: Array = slots_variant
	for slot_variant in slots:
		if not (slot_variant is Dictionary):
			continue
		if bool((slot_variant as Dictionary).get("rare_slot", false)):
			return true
	return false


func _find_rare_slot_index(items_variant: Variant) -> int:
	if not (items_variant is Array):
		return -1
	var items: Array = items_variant
	for item_index in range(items.size()):
		if not (items[item_index] is Dictionary):
			continue
		if bool((items[item_index] as Dictionary).get("shop_slot_rare", false)):
			return item_index
	return -1


func _route_resource_count(snapshot: Dictionary, kind: String) -> int:
	var route_resources: Dictionary = snapshot.get("route_resources", {})
	return int(route_resources.get(kind, 0))


func _offer_grants_route_resource(offer_variant: Variant, kind: String) -> bool:
	if not (offer_variant is Dictionary):
		return false
	var spec: Dictionary = (offer_variant as Dictionary).get("route_resources", {})
	return int(((spec.get("grant", {}) as Dictionary).get(kind, 0))) > 0


func _offer_costs_route_resource(offer_variant: Variant, kind: String) -> bool:
	if not (offer_variant is Dictionary):
		return false
	var spec: Dictionary = (offer_variant as Dictionary).get("route_resources", {})
	return int(((spec.get("cost", {}) as Dictionary).get(kind, 0))) > 0


func _summary_has_shop_action(action_id: String) -> bool:
	var normalized_action := action_id.strip_edges().to_lower()
	var actions: Array = _summary.get("dungeon_shop_actions", [])
	for action_variant in actions:
		if not (action_variant is Dictionary):
			continue
		if String((action_variant as Dictionary).get("action", "")).strip_edges().to_lower() == normalized_action:
			return true
	return false


func _summary_has_shrine_action(action_id: String) -> bool:
	var normalized_action := action_id.strip_edges().to_lower()
	var actions: Array = _summary.get("dungeon_shrine_actions", [])
	for action_variant in actions:
		if not (action_variant is Dictionary):
			continue
		if String((action_variant as Dictionary).get("action", "")).strip_edges().to_lower() == normalized_action:
			return true
	return false


func _summary_shrine_room(room_id: String) -> Dictionary:
	var normalized_room_id := room_id.strip_edges()
	var rooms: Array = _summary.get("dungeon_shrine_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		if String(room.get("room_id", "")).strip_edges() == normalized_room_id:
			return room
	return {}


func _summary_hidden_reveal_entry(room_id: String) -> Dictionary:
	var normalized_room_id := room_id.strip_edges().to_lower()
	var entries: Array = _summary.get("dungeon_hidden_reveals", [])
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("room_id", "")).strip_edges().to_lower() == normalized_room_id:
			return entry
	return {}


func _summary_peak_room(room_id: String) -> Dictionary:
	var normalized_room_id := room_id.strip_edges().to_lower()
	var entries: Array = _summary.get("dungeon_peak_rooms", [])
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("room_id", "")).strip_edges().to_lower() == normalized_room_id:
			return entry
	return {}


func _summaryless_shrine_has_action(snapshot: Dictionary, action_id: String) -> bool:
	var normalized_action := action_id.strip_edges().to_lower()
	var actions: Array = snapshot.get("shrine_action_log", [])
	for action_variant in actions:
		if not (action_variant is Dictionary):
			continue
		if String((action_variant as Dictionary).get("action", "")).strip_edges().to_lower() == normalized_action:
			return true
	return false


func _shrine_direction_ids(items_variant: Variant) -> Array[String]:
	var ids: Array[String] = []
	if not (items_variant is Array):
		return ids
	var items: Array = items_variant
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var direction_id := String((item_variant as Dictionary).get("shrine_direction_id", "")).strip_edges().to_lower()
		if direction_id.is_empty() or ids.has(direction_id):
			continue
		ids.append(direction_id)
	return ids


func _shrine_cost_types(items_variant: Variant) -> Array[String]:
	var cost_types: Array[String] = []
	if not (items_variant is Array):
		return cost_types
	var items: Array = items_variant
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var cost_type := String((item_variant as Dictionary).get("cost_type", "")).strip_edges().to_lower()
		if cost_type.is_empty() or cost_types.has(cost_type):
			continue
		cost_types.append(cost_type)
	return cost_types


func _find_offer_index_by_cost_type(items_variant: Variant, cost_type: String) -> int:
	if not (items_variant is Array):
		return -1
	var normalized_cost_type := cost_type.strip_edges().to_lower()
	var items: Array = items_variant
	for item_index in range(items.size()):
		if not (items[item_index] is Dictionary):
			continue
		if String((items[item_index] as Dictionary).get("cost_type", "")).strip_edges().to_lower() == normalized_cost_type:
			return item_index
	return -1


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


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


func _wait_for_reward_panel(run_node: Node, max_frames: int = 180) -> Dictionary:
	for _index in range(maxi(1, max_frames)):
		var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
		if snapshot_variant is Dictionary:
			var snapshot: Dictionary = snapshot_variant
			if bool(snapshot.get("reward_panel_visible", false)):
				return snapshot
		await process_frame
	return {}


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


func _stage_label(seed_value: int, stage: String, label: String) -> String:
	return "[seed=%d stage=%s] %s" % [seed_value, stage, label]


func _assert_stage_true(seed_value: int, stage: String, condition: bool, label: String) -> void:
	_assert_true(condition, _stage_label(seed_value, stage, label))


func _assert_stage_equal(seed_value: int, stage: String, actual, expected, label: String) -> void:
	_assert_equal(actual, expected, _stage_label(seed_value, stage, label))


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
	print("Night V3 seed replay smoke finished. failed=%d" % failed)
	if failed == 0:
		print("Night V3 seed replay smoke PASS")
	call_deferred("_quit_after_cleanup", failed)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
