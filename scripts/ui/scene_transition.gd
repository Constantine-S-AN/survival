extends CanvasLayer
class_name SceneTransitionController

signal transition_started(operation: String)
signal transition_finished(operation: String)

const OP_FADE_IN := "fade_in"
const OP_FADE_OUT := "fade_out"
const OP_TRANSITION_TO := "transition_to"
const OP_TRANSITION_CALL := "transition_call"
const OP_PULSE := "pulse"

@onready var input_blocker: Control = $InputBlocker
@onready var fade_rect: ColorRect = $FadeRect

var _operation_queue: Array[Dictionary] = []
var _processing: bool = false
var _input_blocked: bool = false
var _headless_runtime: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless_runtime = DisplayServer.get_name() == "headless"
	input_blocker.visible = false
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	input_blocker.focus_mode = Control.FOCUS_ALL
	fade_rect.visible = false
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0
	set_process_input(true)
	set_process_unhandled_input(true)


func fade_in(duration: float = 0.2) -> void:
	_enqueue_operation({
		"operation": OP_FADE_IN,
		"duration": maxf(0.0, duration),
		"block_input": true
	})


func fade_out(duration: float = 0.2) -> void:
	_enqueue_operation({
		"operation": OP_FADE_OUT,
		"duration": maxf(0.0, duration),
		"block_input": true
	})


func transition_to(scene_path: String, duration: float = 0.2) -> void:
	_enqueue_operation({
		"operation": OP_TRANSITION_TO,
		"scene_path": scene_path.strip_edges(),
		"duration": maxf(0.0, duration),
		"block_input": true
	})


func transition_call(action: Callable, duration: float = 0.2) -> void:
	if not action.is_valid():
		push_error("SceneTransition.transition_call received an invalid Callable.")
		return
	_enqueue_operation({
		"operation": OP_TRANSITION_CALL,
		"action": action,
		"duration": maxf(0.0, duration),
		"block_input": true
	})


func play_pulse(duration: float = 0.14) -> void:
	_enqueue_operation({
		"operation": OP_PULSE,
		"duration": maxf(0.01, duration),
		"block_input": false
	})


func is_transitioning() -> bool:
	return _processing or not _operation_queue.is_empty()


func _input(_event: InputEvent) -> void:
	if _input_blocked:
		get_viewport().set_input_as_handled()


func _unhandled_input(_event: InputEvent) -> void:
	if _input_blocked:
		get_viewport().set_input_as_handled()


func _enqueue_operation(operation: Dictionary) -> void:
	_operation_queue.append(operation)
	if _processing:
		return
	_processing = true
	call_deferred("_drain_queue")


func _drain_queue() -> void:
	while not _operation_queue.is_empty():
		var operation: Dictionary = _operation_queue.pop_front()
		await _run_operation(operation)
	_processing = false
	_set_input_blocked(false)


func _run_operation(operation: Dictionary) -> void:
	var operation_type := String(operation.get("operation", "")).strip_edges()
	var duration := maxf(0.0, float(operation.get("duration", 0.2)))
	var block_input := bool(operation.get("block_input", true))
	_set_input_blocked(block_input)
	transition_started.emit(operation_type)

	match operation_type:
		OP_FADE_IN:
			await _run_fade(1.0, 0.0, duration)
		OP_FADE_OUT:
			await _run_fade(0.0, 1.0, duration)
		OP_TRANSITION_TO:
			await _run_transition_to(String(operation.get("scene_path", "")), duration)
		OP_TRANSITION_CALL:
			var callable_variant: Variant = operation.get("action", Callable())
			if callable_variant is Callable:
				await _run_transition_call(callable_variant, duration)
			else:
				push_error("SceneTransition queue received invalid action payload.")
		OP_PULSE:
			await _run_pulse(duration)
		_:
			push_warning("SceneTransition ignored unknown operation: %s" % operation_type)

	transition_finished.emit(operation_type)
	if _operation_queue.is_empty():
		_set_input_blocked(false)


func _run_transition_to(scene_path: String, duration: float) -> void:
	await _run_fade(0.0, 1.0, duration)
	if not _is_valid_scene_path(scene_path):
		push_error("SceneTransition.transition_to invalid path: %s" % scene_path)
		await _run_fade(1.0, 0.0, duration)
		return
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneTransition.transition_to failed (%d): %s" % [error, scene_path])
		await _run_fade(1.0, 0.0, duration)
		return
	await get_tree().process_frame
	await _run_fade(1.0, 0.0, duration)


func _run_transition_call(action: Callable, duration: float) -> void:
	await _run_fade(0.0, 1.0, duration)
	action.call()
	await get_tree().process_frame
	await _run_fade(1.0, 0.0, duration)


func _run_pulse(duration: float) -> void:
	var baseline_alpha := fade_rect.modulate.a
	var peak_alpha := clampf(maxf(baseline_alpha, 0.22), 0.0, 0.4)
	fade_rect.visible = true
	if _headless_runtime or duration <= 0.0:
		fade_rect.modulate.a = baseline_alpha
		fade_rect.visible = baseline_alpha > 0.001
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", peak_alpha, duration * 0.4)
	tween.tween_property(fade_rect, "modulate:a", baseline_alpha, duration * 0.6)
	await tween.finished
	fade_rect.visible = fade_rect.modulate.a > 0.001


func _run_fade(from_alpha: float, to_alpha: float, duration: float) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = clampf(from_alpha, 0.0, 1.0)
	if _headless_runtime or duration <= 0.0:
		fade_rect.modulate.a = clampf(to_alpha, 0.0, 1.0)
		fade_rect.visible = fade_rect.modulate.a > 0.001
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", clampf(to_alpha, 0.0, 1.0), duration)
	await tween.finished
	fade_rect.visible = fade_rect.modulate.a > 0.001


func _set_input_blocked(blocked: bool) -> void:
	_input_blocked = blocked
	input_blocker.visible = blocked
	if blocked:
		input_blocker.grab_focus()


func _is_valid_scene_path(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	return ResourceLoader.exists(scene_path, "PackedScene")
