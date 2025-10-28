extends Node

var loot_overlay_scene := preload("res://Scenes/UI/LootOverlay.tscn")
var _is_modal_open := false
var _pause_refcount := 0

func _ready() -> void:
	# Important for running while SceneTree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS   # Godot 4.x

func _push_pause() -> void:
	_pause_refcount += 1
	if _pause_refcount == 1:
		get_tree().paused = true  # Pauses the tree; nodes not marked WHEN_PAUSED/ALWAYS stop. :contentReference[oaicite:1]{index=1}

func _pop_pause() -> void:
	_pause_refcount = max(0, _pause_refcount - 1)
	if _pause_refcount == 0:
		get_tree().paused = false

func _mount_overlay(node: Node) -> void:
	add_child(node)
	# Overlay itself should keep running during pause too:
	node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _guard_single_modal() -> void:
	if _is_modal_open:
		push_warning("Modal already open; ignoring second request.")

func show_loot_choices(choices: Array):
	_guard_single_modal()
	_is_modal_open = true
	_push_pause()

	var overlay := loot_overlay_scene.instantiate()
	_mount_overlay(overlay)
	overlay.setup(choices)
	overlay.grab_initial_focus()

	var result = await overlay.choice_made

	if is_instance_valid(overlay):
		overlay.queue_free()

	_pop_pause()
	_is_modal_open = false
	return result
