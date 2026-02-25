extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.call("_on_main_menu_start_requested")
	game.call("_on_start_run_requested", "diver")
	game.call("_on_map_select_start_requested", "map_trench_lab")
	game.call("_on_contract_select_start_requested", [])
	for i in range(3):
		await process_frame
	var player: Node = game.get_node_or_null("World/Player")
	var xp_to_next := float(player.get("xp_to_next"))
	player.set("xp", maxf(0.0, xp_to_next - 1.0))
	player.call("gain_xp", 1)
	for i in range(3):
		await process_frame
	print("state_before=", game.get("run_state"), " paused=", paused)
	print("opts=", game.get("_level_up_option_ids"))
	var panel: Node = game.get_node_or_null("UI/Root/UpgradeSelect")
	print("panel_visible=", panel.visible)
	if panel != null:
		print("snapshot=", panel.call("debug_get_snapshot"))
		panel.call("debug_select_index", 0)
	for i in range(20):
		await process_frame
	print("state_after=", game.get("run_state"), " paused=", paused)
	print("opts_after=", game.get("_level_up_option_ids"))
	quit(0)
