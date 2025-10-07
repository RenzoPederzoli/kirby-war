extends CharacterBody2D

## Player character controller with momentum-based movement, jumping, shooting, and damage handling.
## Features ice-skating style movement with braking mechanics and invincibility frames.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var pellet_spawn_point: Marker2D = $ProjSpawnPoint
@onready var ground_raycast: RayCast2D = $GroundRayCast

# =============================================================================
# MOVEMENT CONFIGURATION
# =============================================================================

## Base acceleration when moving horizontally
var acceleration: float = 260.0

## Base deceleration when stopping or changing direction
var deceleration: float = 150.0

## Multiplier for deceleration when changing direction (momentum reversal)
var deceleration_multiplier: float = 1.0

## Maximum horizontal speed the player can reach
var terminal_velocity: float = 180.0

## How much stronger braking force is compared to normal deceleration
@export var brake_strength: float = 5.0

## Percentage of momentum preserved during brake (0.0 = full stop, 1.0 = no braking)
@export var brake_momentum_preservation: float = 0.3

## Enhanced acceleration applied after braking to quickly regain speed
@export var post_brake_acceleration: float = 400.0

# =============================================================================
# JUMPING CONFIGURATION
# =============================================================================

## Vertical velocity applied when jumping (negative for upward movement)
@export var jump_velocity: float = -275.0

## Minimum delay between jump attempts to prevent spam
var jump_reset_delay: float = 0.1

# =============================================================================
# SHOOTING CONFIGURATION
# =============================================================================

## Scene to instantiate when shooting
@export var pellet_scene: PackedScene

## Time in seconds between consecutive shots
@export var fire_rate: float = 0.2

# =============================================================================
# BRAKING SYSTEM
# =============================================================================

## Minimum horizontal velocity required to initiate braking
var min_brake_velocity: float = 10.0

## Duration of the brake action in seconds
var brake_duration: float = 0.4

# =============================================================================
# DAMAGE SYSTEM
# =============================================================================

## Total duration of invincibility after taking damage
var invincibility_duration: float = 1.2

## Interval between flicker state changes during invincibility
var flicker_interval: float = 0.05

## Force applied to player when knocked back by enemies
@export var knockback_force: float = 150.0

## Intensity of screen shake when taking damage (0.0 = no shake, 1.0 = maximum)
@export var screen_shake_intensity: float = 0.5

## Duration of screen shake effect in seconds
@export var screen_shake_duration: float = 0.4

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Whether the player can currently shoot
var can_shoot: bool = true

## Whether the player can currently jump
var can_jump: bool = true

## Timer tracking jump reset delay
var jump_reset_timer: float = 0.0

## Whether the player is currently in a braking state
var is_braking: bool = false

## Horizontal velocity before braking started
var pre_brake_velocity: float = 0.0

## Timer tracking current brake duration
var brake_timer: float = 0.0

## Whether the player is currently invincible
var is_invincible: bool = false

## Timer tracking remaining invincibility time
var invincibility_timer: float = 0.0

## Whether the player is currently flickering during invincibility
var is_flickering: bool = false

## Timer tracking flicker state changes
var flicker_timer: float = 0.0

## Whether the brake animation has been played for the current brake
var brake_animation_played: bool = false


## Whether screen shake is currently active
var is_screen_shaking: bool = false

## Timer tracking screen shake duration
var screen_shake_timer: float = 0.0

## Original camera position for screen shake
var original_camera_position: Vector2 = Vector2.ZERO

## Gravity value from project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# =============================================================================
# GODOT LIFECYCLE
# =============================================================================

func _ready():
	"""Initialize the player character on scene load."""
	animation_player.play("idle")
	pellet_scene = preload("res://Scenes/Props/base_pellet.tscn")
	_setup_ground_raycast()

func _physics_process(delta: float):
	"""Main physics update loop handling movement, input, and state management."""
	_update_timers(delta)
	_apply_gravity()
	_handle_screen_shake(delta)
	_handle_animation()
	_handle_sprite_direction()
	_handle_movement_input(delta)
	_handle_screen_wrapping()
	move_and_slide()
	_check_jump_reset()

# =============================================================================
# TIMER MANAGEMENT
# =============================================================================

func _update_timers(delta: float):
	"""Update all game timers and handle timer-based state changes."""
	if jump_reset_timer > 0:
		jump_reset_timer -= delta
	
	if is_braking:
		brake_timer += delta
	
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

# =============================================================================
# PHYSICS AND MOVEMENT
# =============================================================================

func _apply_gravity():
	"""Apply gravity when the player is not on the ground."""
	if not is_on_floor():
		velocity.y += gravity * get_physics_process_delta_time()


func _handle_screen_shake(_delta: float):
	"""Handle screen shake effect by offsetting the viewport."""
	if is_screen_shaking:
		var shake_intensity = (screen_shake_timer / screen_shake_duration) * screen_shake_intensity
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		get_viewport().canvas_transform.origin = original_camera_position + shake_offset

func _handle_movement_input(delta: float):
	"""Process all movement-related input and apply movement logic."""
	var direction = Input.get_axis("ui_left", "ui_right")
	_handle_momentum_movement(direction, delta)
	_handle_braking_input(delta)
	_handle_jumping_input()
	_handle_shooting_input()

func _handle_momentum_movement(direction: float, delta: float):
	"""Handle momentum-based horizontal movement with acceleration and deceleration."""
	if direction != 0:
		var target_velocity = direction * terminal_velocity
		var current_acceleration = acceleration
		
		# Apply enhanced acceleration after braking
		if not is_braking and abs(velocity.x) < abs(pre_brake_velocity) * 0.5:
			current_acceleration = post_brake_acceleration
		
		# Handle direction changes with stronger deceleration
		if (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0):
			velocity.x = move_toward(velocity.x, 0, deceleration * deceleration_multiplier * delta)
		else:
			velocity.x = move_toward(velocity.x, target_velocity, current_acceleration * delta)
	else:
		# Decelerate only when on ground
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func _handle_braking_input(delta: float):
	"""Process braking input and apply braking forces."""
	if Input.is_action_just_pressed("brake") and is_on_floor():
		if abs(velocity.x) >= min_brake_velocity and not is_braking:
			is_braking = true
			pre_brake_velocity = velocity.x
			brake_timer = 0.0
	
	if is_braking:
		var target_velocity = pre_brake_velocity * brake_momentum_preservation
		velocity.x = move_toward(velocity.x, target_velocity, deceleration * brake_strength * delta)
		
		if brake_timer >= brake_duration:
			is_braking = false

func _handle_jumping_input():
	"""Process jumping input and execute jump if conditions are met."""
	if Input.is_action_just_pressed("ui_accept") and can_jump:
		jump()

func _handle_shooting_input():
	"""Process shooting input and fire projectiles."""
	if Input.is_action_pressed("fire") or Input.is_action_pressed("ui_up"):
		shoot()

func _handle_screen_wrapping():
	"""Wrap player position when moving off screen edges."""
	var viewport_size = get_viewport().get_visible_rect().size
	
	if global_position.x < 0:
		global_position.x = viewport_size.x
	elif global_position.x > viewport_size.x:
		global_position.x = 0

func jump():
	"""Execute a jump by setting vertical velocity and managing jump state."""
	velocity.y = jump_velocity
	can_jump = false
	jump_reset_timer = jump_reset_delay

func _check_jump_reset():
	"""Reset jump ability when player touches the ground."""
	if ground_raycast.is_colliding() and jump_reset_timer <= 0:
		can_jump = true

# =============================================================================
# ANIMATION AND VISUAL
# =============================================================================

func _handle_animation():
	"""Update player animations based on current state."""
	if not animation_player.is_playing() or animation_player.current_animation != "take_damage":
		if not is_on_floor():
			if velocity.y < 0:
				animation_player.play("rise")
			else:
				animation_player.play("fall")
		elif is_braking:
			if not brake_animation_played:
				animation_player.play("brake")
				brake_animation_played = true
		else:
			brake_animation_played = false
			var direction = Input.get_axis("ui_left", "ui_right")
			
			if direction != 0:
				animation_player.play("move")
			elif direction == 0 and velocity.x != 0:
				animation_player.play("sliding")
			else:
				animation_player.play("idle")

func _handle_sprite_direction():
	"""Flip sprite based on movement direction."""
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		sprite.flip_h = direction < 0

# =============================================================================
# COMBAT SYSTEM
# =============================================================================

func shoot():
	"""Fire a projectile from the spawn point."""
	if can_shoot:
		var pellet = pellet_scene.instantiate()
		get_parent().add_child(pellet)
		pellet.global_position = pellet_spawn_point.global_position
		pellet.fire(Vector2.UP)
		
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true

func apply_enemy_contact(enemy: Node2D, damage: int):
	"""Handle damage from enemy contact with invincibility frames, knockback, and screen shake."""
	if not is_invincible:
		print("Player hit by enemy: ", enemy.name, " with damage: ", damage)
		
		# Apply knockback
		_apply_knockback(enemy)
		
		# Start screen shake
		_start_screen_shake()
		
		# Start invincibility
		is_invincible = true
		invincibility_timer = invincibility_duration
		animation_player.play("take_damage")
		
		var damage_animation_duration = animation_player.get_animation("take_damage").length
		await get_tree().create_timer(damage_animation_duration).timeout
		
		if is_invincible:
			is_flickering = true

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
# SETUP AND UTILITIES
# =============================================================================

func _setup_ground_raycast():
	"""Configure the ground detection raycast."""
	ground_raycast.target_position = Vector2(0, 15)
	ground_raycast.enabled = true
	ground_raycast.collision_mask = 1

func _apply_knockback(enemy: Node2D):
	"""Apply one-shot knockback force away from the enemy."""
	var direction_to_enemy = (enemy.global_position - global_position).normalized()
	var knockback_direction = -direction_to_enemy  # Push away from enemy
	
	# Only apply horizontal knockback (preserve vertical movement)
	knockback_direction.y = 0.0
	knockback_direction = knockback_direction.normalized()
	
	# Apply immediate knockback force to velocity
	velocity.x = knockback_direction.x * knockback_force

func _start_screen_shake():
	"""Start the screen shake effect."""
	if not is_screen_shaking:
		original_camera_position = get_viewport().canvas_transform.origin
		is_screen_shaking = true
		screen_shake_timer = screen_shake_duration

func _reset_camera_position():
	"""Reset the camera to its original position after screen shake."""
	get_viewport().canvas_transform.origin = original_camera_position