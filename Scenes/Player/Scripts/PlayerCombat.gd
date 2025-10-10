extends Node
class_name PlayerCombat

## Handles all combat-related functionality including shooting and damage.
## Manages projectile spawning, fire rate, and damage processing.

# =============================================================================
# CONFIGURATION
# =============================================================================

## Scene to instantiate when shooting
@export var pellet_scene: PackedScene

## Time in seconds between consecutive shots
var fire_rate: float = 0.2

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Whether the player can currently shoot
var can_shoot: bool = true

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D
var pellet_spawn_point: Marker2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the combat system with a reference to the player."""
	player = player_node
	pellet_spawn_point = player.get_node("ProjSpawnPoint")
	pellet_scene = preload("res://Scenes/Props/base_pellet.tscn")

# =============================================================================
# SHOOTING SYSTEM
# =============================================================================

func update_combat():
	"""Update combat system - called from player's _physics_process."""
	_handle_shooting_input()

func _handle_shooting_input():
	"""Process shooting input and fire projectiles."""
	if Input.is_action_pressed("fire") or Input.is_action_pressed("ui_up"):
		shoot()

func shoot():
	"""Fire a projectile from the spawn point."""
	if can_shoot:
		var pellet = pellet_scene.instantiate()
		player.get_parent().add_child(pellet)
		pellet.global_position = pellet_spawn_point.global_position
		pellet.fire(Vector2.UP)
		
		# Emit signal to notify other systems
		player.player_shot.emit()
		
		can_shoot = false
		await player.get_tree().create_timer(fire_rate).timeout
		can_shoot = true
