extends Node2D

@onready var enemy_spawn_point: Marker2D = $EnemySpawnDebug
@onready var background_track: AudioStreamPlayer = $BackgroundTrack
@onready var player: CharacterBody2D = $Player
@onready var xp_bar: Control = $CanvasLayer/XPBar

var enemy_scene: PackedScene

# =============================================================================
# GAME STATISTICS TRACKING
# =============================================================================

## Game statistics to track for the game over screen
var enemies_defeated: int = 0
var game_start_time: float
var items_collected: int = 0

func _ready():
	# Load the enemy scene
	enemy_scene = preload("res://Scenes/Enemies/EnemyBase.tscn")
	
	# Connect XP bar to player leveling system
	if player and player.leveling_system and xp_bar:
		xp_bar.setup(player.leveling_system)
	
	# Connect player death signal
	if player:
		player.player_died.connect(_on_player_died)
	
	# Initialize game statistics
	game_start_time = Time.get_unix_time_from_system()
	
	# Start spawning enemies every 15 seconds
	spawn_enemy()
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.timeout.connect(spawn_enemy)
	timer.autostart = true
	add_child(timer)
	
	# Start playing the background track if it's not already playing
	if not background_track.playing:
		background_track.play()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position
	
	# Connect enemy death signal to track statistics
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)

# =============================================================================
# GAME STATISTICS TRACKING
# =============================================================================

func _on_enemy_died():
	"""Handle enemy death - increment defeated counter."""
	enemies_defeated += 1
	print("Enemy defeated! Total: ", enemies_defeated)

func _on_player_died():
	"""Handle player death - transition to game over scene."""
	print("Player died - transitioning to game over screen")
	
	# Calculate time survived
	var current_time = Time.get_unix_time_from_system()
	var time_survived = current_time - game_start_time
	
	# Get final player statistics
	var final_level = player.get_level()
	items_collected = player.get_active_items().size()
	
	# Stop background music
	background_track.stop()
	
	# Store statistics in a global variable for the game over scene to access
	GameStats.final_level = final_level
	GameStats.enemies_defeated = enemies_defeated
	GameStats.time_survived = time_survived
	GameStats.items_collected = items_collected
	
	# TODO: Let death animation play before transitioning to game over scene
	# Use call_deferred to avoid physics callback issues
	call_deferred("_transition_to_game_over")

func _transition_to_game_over():
	"""Deferred scene transition to avoid physics callback issues."""
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
