extends Node
class_name PlayerCombat

## Handles all combat-related functionality including shooting and damage.
## Manages projectile spawning, fire rate, and damage processing.

# =============================================================================
# CONFIGURATION
# =============================================================================

## Scene to instantiate when shooting
@export var pellet_scene: PackedScene

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Whether the player can currently shoot
var can_shoot: bool = true

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D
var player_sprite: Sprite2D
var pellet_spawn_point: Marker2D
var aim_pivot: Node2D
var aim_pivot_origin: Vector2 = Vector2.ZERO
var current_fire_direction: Vector2 = Vector2.RIGHT

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the combat system with a reference to the player."""
	player = player_node
	player_sprite = player.get_node("Sprite2D") as Sprite2D
	pellet_spawn_point = player.get_node("AimPivot/Muzzle") as Marker2D
	aim_pivot = player.get_node("AimPivot") as Node2D
	aim_pivot_origin = aim_pivot.position
	pellet_scene = preload("res://Scenes/Props/base_pellet.tscn")

# =============================================================================
# SHOOTING SYSTEM
# =============================================================================

func update_combat():
	"""Update combat system - called from player's _physics_process."""
	_sync_pivot_side_with_player()
	_handle_aiming()
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
		
		var fire_direction = current_fire_direction.normalized()
		if fire_direction == Vector2.ZERO:
			fire_direction = Vector2.RIGHT
		pellet.fire(fire_direction)
		
		
		can_shoot = false
		# Use fire rate from stats system
		var current_fire_rate = player.get_fire_rate()
		await player.get_tree().create_timer(current_fire_rate).timeout
		can_shoot = true

func _handle_aiming():
	"""Rotate the aim pivot toward the mouse and update fire direction."""
	if aim_pivot == null:
		return
	
	var mouse_position = player.get_global_mouse_position()
	var pivot_global_position = aim_pivot.global_position
	var aim_vector = mouse_position - pivot_global_position
	
	if aim_vector == Vector2.ZERO:
		return
	
	aim_pivot.rotation = aim_vector.angle() + PI/2
	current_fire_direction = aim_vector.normalized()

func _sync_pivot_side_with_player():
	if aim_pivot == null or player_sprite == null:
		return
	
	var facing_right = not player_sprite.flip_h
	var offset_x = abs(aim_pivot_origin.x)
	if not facing_right:
		offset_x = -offset_x
	
	aim_pivot.position = Vector2(offset_x, aim_pivot_origin.y)
