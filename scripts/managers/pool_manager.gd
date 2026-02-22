extends Node2D
class_name PoolManager

var scenes: Dictionary = {}
var buckets: Dictionary = {}
var default_parents: Dictionary = {}

var hits: int = 0
var misses: int = 0
var hits_by_key: Dictionary = {}
var misses_by_key: Dictionary = {}

var inactive_root: Node2D = null


func _ready() -> void:
	inactive_root = get_node_or_null("InactiveRoot")
	if inactive_root == null:
		inactive_root = Node2D.new()
		inactive_root.name = "InactiveRoot"
		add_child(inactive_root)


func ensure_pool(key: String, scene: PackedScene, default_parent: Node, prewarm_count: int = 0) -> void:
	if key.is_empty() or scene == null:
		return
	scenes[key] = scene
	if not buckets.has(key):
		buckets[key] = []
	if default_parent != null:
		default_parents[key] = default_parent
	if inactive_root == null:
		return
	var bucket: Array = buckets[key]
	var missing := maxi(0, prewarm_count - bucket.size())
	for _i in range(missing):
		var instance := scene.instantiate()
		inactive_root.add_child(instance)
		_prepare_for_recycle(instance)
		bucket.append(instance)
	buckets[key] = bucket


func checkout(key: String, parent_override: Node = null) -> Node:
	if not buckets.has(key):
		return null
	var bucket: Array = buckets[key]
	var instance: Node = null
	if bucket.is_empty():
		var scene_variant: Variant = scenes.get(key, null)
		if scene_variant is PackedScene:
			instance = (scene_variant as PackedScene).instantiate()
			misses += 1
			misses_by_key[key] = int(misses_by_key.get(key, 0)) + 1
		else:
			return null
	else:
		instance = bucket.pop_back()
		buckets[key] = bucket
		hits += 1
		hits_by_key[key] = int(hits_by_key.get(key, 0)) + 1

	if instance == null:
		return null
	var parent: Node = parent_override
	if parent == null:
		var parent_variant: Variant = default_parents.get(key, null)
		if parent_variant is Node:
			parent = parent_variant
	if parent != null:
		if instance.get_parent() == null:
			parent.add_child(instance)
		elif instance.get_parent() != parent:
			instance.reparent(parent)
	_prepare_for_spawn(instance)
	return instance


func recycle(key: String, instance: Node) -> void:
	if instance == null:
		return
	if not buckets.has(key):
		if instance.get_parent() != null:
			instance.get_parent().remove_child(instance)
		instance.queue_free()
		return
	_prepare_for_recycle(instance)
	if inactive_root != null:
		if instance.get_parent() == null:
			inactive_root.add_child(instance)
		elif instance.get_parent() != inactive_root:
			instance.reparent(inactive_root)
	var bucket: Array = buckets[key]
	if not bucket.has(instance):
		bucket.append(instance)
	buckets[key] = bucket


func reset_stats() -> void:
	hits = 0
	misses = 0
	hits_by_key.clear()
	misses_by_key.clear()


func get_stats() -> Dictionary:
	var total := hits + misses
	var rate := 0.0
	if total > 0:
		rate = float(hits) / float(total)
	return {
		"hits": hits,
		"misses": misses,
		"total": total,
		"hit_rate": rate
	}


func get_stats_for_key(key: String) -> Dictionary:
	var key_hits := int(hits_by_key.get(key, 0))
	var key_misses := int(misses_by_key.get(key, 0))
	var total := key_hits + key_misses
	var rate := 0.0
	if total > 0:
		rate = float(key_hits) / float(total)
	return {
		"key": key,
		"hits": key_hits,
		"misses": key_misses,
		"total": total,
		"hit_rate": rate
	}


func _prepare_for_spawn(instance: Node) -> void:
	if instance is CanvasItem:
		(instance as CanvasItem).visible = true
	if instance is Area2D:
		(instance as Area2D).set_deferred("monitoring", true)
		(instance as Area2D).set_deferred("monitorable", true)
	if instance.has_method("on_pool_spawned"):
		instance.call("on_pool_spawned")


func _prepare_for_recycle(instance: Node) -> void:
	if instance is Area2D:
		(instance as Area2D).set_deferred("monitoring", false)
		(instance as Area2D).set_deferred("monitorable", false)
	if instance is CanvasItem:
		(instance as CanvasItem).visible = false
	if instance.has_method("on_pool_recycle"):
		instance.call("on_pool_recycle")
