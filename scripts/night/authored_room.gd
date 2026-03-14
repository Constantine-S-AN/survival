extends Node2D
class_name AuthoredNightRoom

@export var content_label: String = ""
@export var content_tags: Array[String] = []


func get_room_content_snapshot() -> Dictionary:
	var cover_root := get_node_or_null("CoverProps")
	var hazard_root := get_node_or_null("Hazards")
	var explosive_root := get_node_or_null("ExplosiveProps")
	return {
		"content_label": content_label,
		"content_tags": content_tags.duplicate(),
		"cover_count": _count_direct_children(cover_root),
		"hazard_count": _count_direct_children(hazard_root),
		"explosive_count": _count_direct_children(explosive_root)
	}


func _count_direct_children(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	for child in node.get_children():
		if child != null:
			count += 1
	return count
