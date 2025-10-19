extends Control

## Game Over scene that displays final statistics and provides restart/quit options.
## Matches the frostblade/ice theme of the main game.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var final_level_label: Label = $CanvasLayer/VBoxContainer/StatsContainer/FinalLevelLabel
@onready var enemies_defeated_label: Label = $CanvasLayer/VBoxContainer/StatsContainer/EnemiesDefeatedLabel
@onready var time_survived_label: Label = $CanvasLayer/VBoxContainer/StatsContainer/TimeSurvivedLabel
@onready var items_collected_label: Label = $CanvasLayer/VBoxContainer/StatsContainer/ItemsCollectedLabel
@onready var play_again_button: Button = $CanvasLayer/VBoxContainer/ButtonsContainer/PlayAgainButton
@onready var quit_button: Button = $CanvasLayer/VBoxContainer/ButtonsContainer/QuitButton
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

# =============================================================================
# GAME STATISTICS
# =============================================================================

## Statistics passed from the main game
var final_level: int = 1
var enemies_defeated: int = 0
var time_survived: float = 0.0
var items_collected: int = 0

# =============================================================================
# GODOT LIFECYCLE
# =============================================================================

func _ready():
	"""Initialize the game over scene."""
	# Connect button signals
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Load statistics from global GameStats
	_load_statistics_from_global()
	
	# Start background music
	if not background_music.playing:
		background_music.play()
	
	# Update display with current statistics
	_update_statistics_display()
	
	# Add some visual flair
	_play_game_over_animation()

# =============================================================================
# STATISTICS DISPLAY
# =============================================================================

func _load_statistics_from_global():
	"""Load statistics from the global GameStats singleton."""
	final_level = GameStats.final_level
	enemies_defeated = GameStats.enemies_defeated
	time_survived = GameStats.time_survived
	items_collected = GameStats.items_collected

func _update_statistics_display():
	"""Update all statistics labels with current values."""
	final_level_label.text = "Final Level: " + str(final_level)
	enemies_defeated_label.text = "Enemies Defeated: " + str(enemies_defeated)
	time_survived_label.text = "Time Survived: " + _format_time(time_survived)
	items_collected_label.text = "Items Collected: " + str(items_collected)

func _format_time(seconds: float) -> String:
	"""
	Format time in seconds to MM:SS format.
	
	Args:
		seconds: Time in seconds
		
	Returns:
		Formatted time string
	"""
	var minutes = int(seconds) / 60
	var remaining_seconds = int(seconds) % 60
	return "%02d:%02d" % [minutes, remaining_seconds]

# =============================================================================
# VISUAL EFFECTS
# =============================================================================

func _play_game_over_animation():
	"""Play a subtle animation effect for the game over screen."""
	# Fade in effect
	modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.0)
	
	# Slight scale animation for the title
	var title = $CanvasLayer/VBoxContainer/GameOverTitle
	title.scale = Vector2(0.8, 0.8)
	var title_tween = create_tween()
	title_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.5)
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_play_again_pressed():
	"""Handle play again button press - restart the game."""
	print("Play Again pressed - restarting game")
	
	# Stop background music
	background_music.stop()
	
	# Reset game statistics for new game
	GameStats.reset_stats()
	
	# Change to main scene
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_quit_pressed():
	"""Handle quit button press - exit the game."""
	print("Quit pressed - exiting game")
	
	# Stop background music
	background_music.stop()
	
	# Quit the game
	get_tree().quit()

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event):
	"""Handle input events for quick restart."""
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_play_again_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
