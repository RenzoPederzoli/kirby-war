extends Node
class_name PlayerEffects

## Handles all visual and gameplay effects including knockback and screen shake.
## Manages damage effects, invincibility, and screen shake.

# =============================================================================
# CONFIGURATION
# =============================================================================

## Force applied to player when knocked back by enemies
var knockback_force: float

## Total duration of invincibility after taking damage
var invincibility_duration: float = 1.2

## Interval between flicker state changes during invincibility
var flicker_interval: float = 0.05

## Intensity of screen shake when taking damage (0.0 = no shake, 1.0 = maximum)
var screen_shake_intensity: float

## Duration of screen shake effect in seconds
var screen_shake_duration: float

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Whether the player is currently invincible
var is_invincible: bool = false

## Timer tracking remaining invincibility time
var invincibility_timer: float = 0.0

## Whether the player is currently flickering during invincibility
var is_flickering: bool = false

## Timer tracking flicker state changes
var flicker_timer: float = 0.0

## Whether screen shake is currently active
var is_screen_shaking: bool = false

## Timer tracking screen shake duration
var screen_shake_timer: float = 0.0

## Original camera position for screen shake
var original_camera_position: Vector2 = Vector2.ZERO

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D
var sprite: Sprite2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the effects system with a reference to the player."""
	player = player_node
	sprite = player.get_node("Sprite2D")

# =============================================================================
# MAIN UPDATE
# =============================================================================

func update_effects(delta: float):
	"""Update all effects - called from player's _physics_process."""
	_update_timers(delta)
	_handle_screen_shake(delta)

func _update_timers(delta: float):
	"""Update all effect timers."""
	if is_screen_shaking:
		screen_shake_timer -= delta
		if screen_shake_timer <= 0:
			is_screen_shaking = false
			_reset_camera_position()
	
	if is_invincible:
		invincibility_timer -= delta
		_handle_invincibility_flicker(delta)
		if invincibility_timer <= 0:
			is_invincible = false
			is_flickering = false
			sprite.modulate.a = 1.0

func _handle_screen_shake(_delta: float):
	"""Handle screen shake effect by offsetting the viewport."""
	if is_screen_shaking:
		var shake_intensity = (screen_shake_timer / screen_shake_duration) * screen_shake_intensity
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		player.get_viewport().canvas_transform.origin = original_camera_position + shake_offset

func _handle_invincibility_flicker(delta: float):
	"""Handle sprite flickering during invincibility period."""
	if is_flickering:
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			flicker_timer = 0.0
			if sprite.modulate.a == 1.0:
				sprite.modulate.a = 0.1
			else:
				sprite.modulate.a = 1.0

# =============================================================================
# DAMAGE SYSTEM
# =============================================================================

func apply_enemy_contact(enemy: Node2D, damage: int, animation_system):
	"""Handle damage from enemy contact with invincibility frames, knockback, and screen shake."""
	if not is_invincible and not player.is_dead:
		print("Player hit by enemy: ", enemy.name, " with damage: ", damage)
		
		# Apply damage to health
		player.current_health -= damage
		print("Player health: ", player.current_health, "/", player.get_max_health())
		
		# Check if player died
		if player.current_health <= 0:
			player.current_health = 0
			player.is_dead = true
			player.player_died.emit()
			animation_system.play_death_animation()
			return
		
		# Apply knockback
		_apply_knockback(enemy)
		
		# Start screen shake
		_start_screen_shake()
		
		# Start invincibility
		is_invincible = true
		invincibility_timer = invincibility_duration
		animation_system.play_damage_animation()
		
		var damage_animation_duration = animation_system.get_damage_animation_duration()
		await player.get_tree().create_timer(damage_animation_duration).timeout
		
		if is_invincible:
			is_flickering = true

func _apply_knockback(enemy: Node2D):
	"""Apply one-shot knockback force away from the enemy."""
	var direction_to_enemy = (enemy.global_position - player.global_position).normalized()
	var knockback_direction = -direction_to_enemy  # Push away from enemy
	
	# Only apply horizontal knockback (preserve vertical movement)
	knockback_direction.y = 0.0
	knockback_direction = knockback_direction.normalized()
	
	# Apply immediate knockback force to velocity
	player.velocity.x = knockback_direction.x * knockback_force

func _start_screen_shake():
	"""Start the screen shake effect."""
	if not is_screen_shaking:
		original_camera_position = player.get_viewport().canvas_transform.origin
		is_screen_shaking = true
		screen_shake_timer = screen_shake_duration

func _reset_camera_position():
	"""Reset the camera to its original position after screen shake."""
	player.get_viewport().canvas_transform.origin = original_camera_position

# =============================================================================
# STATE QUERIES
# =============================================================================

func is_player_invincible() -> bool:
	"""Check if the player is currently invincible."""
	return is_invincible
