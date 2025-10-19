extends MarginContainer

signal pressed
signal hovered(inside: bool)
signal picked

@export var disabled := false: set = set_disabled

@onready var _name := $CenterContainer/VBoxContainer/Name
@onready var _stats := $CenterContainer/VBoxContainer/Stats
@onready var _icon  := $CenterContainer/VBoxContainer/Icon
var _choice_data

var _is_hovered := false
var _is_pressed := false

func _ready() -> void:
	# Make sure this runs while the world is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Let this node receive mouse/GUI events and block clicks from passing through
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Allow keyboard/controller focus
	focus_mode = Control.FOCUS_ALL

	mouse_entered.connect(func():
		_is_hovered = true
		emit_signal("hovered", true)
	)
	mouse_exited.connect(func():
		_is_hovered = false
		_is_pressed = false
		emit_signal("hovered", false)
	)
	pressed.connect(func(): emit_signal("picked"))

func set_disabled(v: bool) -> void:
	disabled = v
	modulate.a = 0.6 if disabled else 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	# Mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
		else:
			var was_pressed = _is_pressed
			_is_pressed = false
			if was_pressed and _is_hovered:
				emit_signal("pressed")

	# Keyboard/controller activation while focused
	if has_focus() and event.is_action_pressed("ui_accept"):
		emit_signal("pressed")

func _unhandled_key_input(event: InputEvent) -> void:
	# Optional: let focused card activate via Enter/Space at the tree level
	if disabled: return
	if has_focus() and (event.is_action_pressed("ui_accept")):
		emit_signal("pressed")

func set_choice(choice_data) -> void:
	_choice_data = choice_data
	_name.text = str(choice_data.item_name)
	_stats.text = str(choice_data.description)
	if "icon" in choice_data and choice_data.icon != null:
		_icon.texture = choice_data.icon
	else:
		_icon.visible = false

func grab_primary_focus() -> void:
	grab_focus()
