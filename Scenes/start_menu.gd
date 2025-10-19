extends Control

@onready var start_button   : Button = $CenterContainer/VBoxContainer/StartButton
@onready var options_button : Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var quit_button    : Button = $CenterContainer/VBoxContainer/QuitButton
@onready var options_label  : Label  = $CenterContainer/VBoxContainer/OptionsLabel

const GAME_SCENE_PATH := "res://Scenes/main.tscn"

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_options_pressed() -> void:
	options_label.visible = true
	options_label.text = "Options coming soon…"

func _on_quit_pressed() -> void:
	get_tree().quit()
