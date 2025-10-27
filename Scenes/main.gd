extends Node2D

@onready var enemy_spawn_point: Marker2D = $EnemySpawnDebug
@onready var background_track: AudioStreamPlayer = $BackgroundTrack
@onready var player: CharacterBody2D = $Player
@onready var xp_bar: XPBar = $CanvasLayer/XPBar

var enemy_scene: PackedScene

# =============================================================================
# GAME STATISTICS TRACKING
# =============================================================================

## Game statistics to track for the game over screen
var enemies_defeated: int = 0
var game_start_time: float
var items_collected: int = 0

# Enemy spawning variables
var enemy_spawn_counter: int = 0

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
	
	# Alternate between sphere and golem enemies
	var enemy_data: Resource
	if enemy_spawn_counter % 2 == 0:
		# Spawn sphere (bouncing)
		enemy_data = preload("res://Scenes/Enemies/Data/sphere_enemy_data.tres")
	else:
		# Spawn golem (patrol)
		enemy_data = preload("res://Scenes/Enemies/Data/ice_golem_data.tres")
	
	# Apply enemy data
	enemy.apply_enemy_data(enemy_data)
	
	# Set enemy name for debugging
	enemy.name = enemy_data.enemy_name + "_" + str(Time.get_unix_time_from_system())
	print("Spawned enemy: ", enemy.name, " with movement type: ", enemy_data.movement_type)
	print("  - Animation type: ", enemy_data.animation_type)
	print("  - Gravity scale: ", enemy_data.gravity_scale)
	
	# Position enemy based on movement type
	if enemy_data.movement_type == "patrol":
		# Spawn patrol enemies on actual ground at screen edges
		var viewport_size = get_viewport().get_visible_rect().size
		var spawn_x = 50 if randf() < 0.5 else viewport_size.x - 50  # Left or right edge
		
		# Add some horizontal spacing to prevent overlapping
		if spawn_x < viewport_size.x / 2:
			spawn_x += randf_range(-10, 10)  # Left side variation
		else:
			spawn_x += randf_range(-10, 10)  # Right side variation
		
		# Find ground level - use player's Y position as reference
		var ground_y = player.global_position.y  # Same level as player
		print("Using ground level: ", ground_y, " (player Y: ", player.global_position.y, ")")
		
		enemy.global_position = Vector2(spawn_x, ground_y)
		
		# Set initial direction based on spawn side
		if spawn_x < viewport_size.x / 2:
			enemy.linear_velocity = Vector2(enemy_data.speed, 0)  # Move right
		else:
			enemy.linear_velocity = Vector2(-enemy_data.speed, 0)  # Move left
	else:
		# Spawn bouncing enemies at the original spawn point
		enemy.global_position = enemy_spawn_point.global_position
	
	# Increment spawn counter for next enemy
	enemy_spawn_counter += 1
	
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
	
	# Use call_deferred to avoid physics callback issues
	call_deferred("_transition_to_game_over")

func _transition_to_game_over():
	"""Deferred scene transition to avoid physics callback issues."""
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
