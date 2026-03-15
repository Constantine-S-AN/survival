extends Node2D
class_name AuthoredNightRoom

@export var content_label: String = ""
@export var content_tags: Array[String] = []

const COVER_LAYER_Z := 28


func _ready() -> void:
	var cover_root := get_node_or_null("CoverProps")
	if cover_root is Node2D:
		var cover_layer := cover_root as Node2D
		cover_layer.z_as_relative = false
		cover_layer.z_index = COVER_LAYER_Z


func get_room_content_snapshot() -> Dictionary:
	var cover_root := get_node_or_null("CoverProps")
	var hazard_root := get_node_or_null("Hazards")
	var explosive_root := get_node_or_null("ExplosiveProps")
	var wall_root := get_node_or_null("WallVisuals")
	return {
		"content_label": content_label,
		"content_tags": content_tags.duplicate(),
		"wall_visual_count": _count_direct_children(wall_root),
		"cover_layer_z": _canvas_item_z(cover_root),
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


func _canvas_item_z(node: Node) -> int:
	if node is CanvasItem:
		return (node as CanvasItem).z_index
	return 0
