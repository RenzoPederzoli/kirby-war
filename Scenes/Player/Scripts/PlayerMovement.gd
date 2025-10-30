extends Node
class_name PlayerMovement

## Handles all player movement, physics, and input processing.
## Manages momentum-based movement, jumping, braking, and screen wrapping.

# =============================================================================
# CONFIGURATION
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
var brake_strength: float = 5.0

## Percentage of momentum preserved during brake (0.0 = full stop, 1.0 = no braking)
var brake_momentum_preservation: float = 0.3

## Enhanced acceleration applied after braking to quickly regain speed
var post_brake_acceleration: float = 400.0

## Vertical velocity applied when jumping (negative for upward movement)
var jump_velocity: float = -275.0

## Minimum delay between jump attempts to prevent spam
var jump_reset_delay: float = 0.1

## Minimum horizontal velocity required to initiate braking
var min_brake_velocity: float = 10.0

## Duration of the brake action in seconds
var brake_duration: float = 0.4

# =============================================================================
# RUNTIME STATE
# =============================================================================

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

## Whether the brake animation has been played for the current brake
var brake_animation_played: bool = false

## Gravity value from project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D
var ground_raycast: RayCast2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the movement system with a reference to the player."""
	player = player_node
	ground_raycast = player.get_node("GroundRayCast")
	_setup_ground_raycast()

func _setup_ground_raycast():
	"""Configure the ground detection raycast."""
	ground_raycast.target_position = Vector2(0, 15)
	ground_raycast.enabled = true
	ground_raycast.collision_mask = 1

# =============================================================================
# MAIN UPDATE
# =============================================================================

func update_movement(delta: float):
	"""Main movement update function called from player's _physics_process."""
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_movement_input(delta)
	_handle_screen_wrapping()

func _update_timers(delta: float):
	"""Update all movement-related timers."""
	if jump_reset_timer > 0:
		jump_reset_timer -= delta
	
	if is_braking:
		brake_timer += delta

func _apply_gravity(delta: float):
	"""Apply gravity when the player is not on the ground."""
	if not player.is_on_floor():
		player.velocity.y += gravity * delta

func _handle_movement_input(delta: float):
	"""Process all movement-related input and apply movement logic."""
	var direction = Input.get_axis("ui_left", "ui_right")
	_handle_momentum_movement(direction, delta)
	_handle_braking_input(delta)
	_handle_jumping_input()

func _handle_momentum_movement(direction: float, delta: float):
	"""Handle momentum-based horizontal movement with acceleration and deceleration."""
	if direction != 0:
		# Get movement speed multiplier from stats system
		var move_speed_multiplier = player.get_move_speed()
		
		# Apply movement speed multiplier to terminal velocity
		var target_velocity = direction * terminal_velocity * move_speed_multiplier
		var current_acceleration = acceleration
		
		# Apply enhanced acceleration after braking
		if not is_braking and abs(player.velocity.x) < abs(pre_brake_velocity) * 0.5:
			current_acceleration = post_brake_acceleration
		
		# Handle direction changes with stronger deceleration
		if (direction > 0 and player.velocity.x < 0) or (direction < 0 and player.velocity.x > 0):
			player.velocity.x = move_toward(player.velocity.x, 0, deceleration * deceleration_multiplier * delta)
		else:
			player.velocity.x = move_toward(player.velocity.x, target_velocity, current_acceleration * delta)
	else:
		# Decelerate only when on ground
		if player.is_on_floor():
			player.velocity.x = move_toward(player.velocity.x, 0, deceleration * delta)

func _handle_braking_input(delta: float):
	"""Process braking input and apply braking forces."""
	if Input.is_action_just_pressed("brake") and player.is_on_floor():
		if abs(player.velocity.x) >= min_brake_velocity and not is_braking:
			is_braking = true
			pre_brake_velocity = player.velocity.x
			brake_timer = 0.0
	
	if is_braking:
		var target_velocity = pre_brake_velocity * brake_momentum_preservation
		player.velocity.x = move_toward(player.velocity.x, target_velocity, deceleration * brake_strength * delta)
		
		if brake_timer >= brake_duration:
			is_braking = false

func _handle_jumping_input():
	"""Process jumping input and execute jump if conditions are met."""
	if Input.is_action_just_pressed("ui_accept") and can_jump:
		jump()

func _handle_screen_wrapping():
	"""Wrap player position when moving off screen edges."""
	var viewport_size = player.get_viewport().get_visible_rect().size
	
	if player.global_position.x < 0:
		player.global_position.x = viewport_size.x
	elif player.global_position.x > viewport_size.x:
		player.global_position.x = 0

# =============================================================================
# JUMPING SYSTEM
# =============================================================================

func jump():
	"""Execute a jump by setting vertical velocity and managing jump state."""
	player.velocity.y = jump_velocity
	can_jump = false
	jump_reset_timer = jump_reset_delay

func check_jump_reset():
	"""Reset jump ability when player touches the ground."""
	if ground_raycast.is_colliding() and jump_reset_timer <= 0:
		can_jump = true

# =============================================================================
# BRAKING SYSTEM
# =============================================================================

func is_player_braking() -> bool:
	"""Check if the player is currently braking."""
	return is_braking

func should_play_brake_animation() -> bool:
	"""Check if brake animation should be played."""
	return is_braking and not brake_animation_played

func mark_brake_animation_played():
	"""Mark that the brake animation has been played."""
	brake_animation_played = true

func reset_brake_animation_flag():
	"""Reset the brake animation flag when not braking."""
	if not is_braking:
		brake_animation_played = false
