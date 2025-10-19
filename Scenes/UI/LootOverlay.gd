extends CanvasLayer

signal choice_made(choice)

@onready var _root := $Root
@onready var _choices_row := $Root/CenterContainer/ChoicesRow

var _choices_data: Array = []

func _ready() -> void:
	# Keep this overlay “alive” while the SceneTree is paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Block clicks into the game:
	$Root.mouse_filter = Control.MOUSE_FILTER_STOP

func setup(choices: Array) -> void:
	_choices_data = choices
	_build_options()
	_animate_open()

func grab_initial_focus() -> void:
	if _choices_row.get_child_count() > 0:
		var first := _choices_row.get_child(0)
		if first.has_method("grab_primary_focus"):
			first.grab_primary_focus()

func _build_options() -> void:
	for c in _choices_row.get_children():
		c.queue_free()
	var option_scene := preload("res://Scenes/ui/LootOption.tscn")
	for i in _choices_data.size():
		var node := option_scene.instantiate()
		node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		_choices_row.add_child(node)
		node.set_choice(_choices_data[i])
		node.picked.connect(func(): _on_pick(i))

func _on_pick(idx: int) -> void:
	emit_signal("choice_made", _choices_data[idx])

func _animate_open() -> void:
	# Bind tween to this node (which processes during pause).
	var t := create_tween()  # Godot 4: tweens are node-bound; runs if node can process.
	_root.modulate.a = 0.0
	_root.scale = Vector2(0.95, 0.95)
	t.tween_property(_root, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(_root, "scale", Vector2.ONE, 0.15)
