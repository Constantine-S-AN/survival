extends "res://addons/gd-plug/plug.gd"

const DIALOGUE_MANAGER_VERSION := "v3.10.1"
const DIALOGUE_MANAGER_COMMIT := "b160e4dff4014135ed16af268c604b748cc17f2d"
const QUEST_SYSTEM_VERSION := "2.0.1.4_4"
const QUEST_SYSTEM_COMMIT := "f31db6f3622f1d027b3fae389688b2bb71229612"


func _plugging() -> void:
	# Keep the addons vendored and pinned without auto-enabling their editor plugins.
	plug("nathanhoad/godot_dialogue_manager", {"commit": DIALOGUE_MANAGER_COMMIT})
	plug("shomykohai/quest-system", {
		"commit": QUEST_SYSTEM_COMMIT,
		"include": ["addons/quest_system"]
	})
