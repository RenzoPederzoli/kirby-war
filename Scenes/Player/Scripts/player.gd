extends CharacterBody2D

# Animation variables
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D

# Shooting variables
@onready var pellet_spawn_point : Marker2D = $ProjSpawnPoint
@export var pellet_scene : PackedScene
@export var fire_rate : float = 0.2  # Time between shots in seconds
var can_shoot : bool = true

# Movement variables
var acceleration = 260.0  # How quickly we build up speed
var deceleration = 150.0  # How quickly we slow down
var deceleration_multiplier = 1.0  # How much faster we slow down when changing direction
var terminal_velocity = 180.0  # Maximum speed we can reach
@export var brake_strength = 5.0  # How much stronger braking is than normal deceleration
@export var brake_momentum_preservation = 0.3  # How much momentum to preserve during brake (0-1)
@export var post_brake_acceleration = 400.0  # How quickly to regain speed after braking

# Jumping variables
@export var jump_velocity = -275.0  # How strong the jump is (negative for upward)
var can_jump = true
var jump_reset_timer = 0.0
var jump_reset_delay = 0.1  # Small delay to prevent jump spam
@onready var ground_raycast : RayCast2D = $GroundRayCast

# Braking state variables
var is_braking = false
var pre_brake_velocity = 0.0
var min_brake_velocity = 10.0  # Minimum velocity required to start braking
var brake_duration = 0.4  # Duration of the brake action
var brake_timer = 0.0

# Damage and invincibility variables
var is_invincible = false
var invincibility_timer = 0.0
var invincibility_duration = 1.2  # Total invincibility duration
var flicker_timer = 0.0
var flicker_interval = 0.05  # How fast to flicker
var is_flickering = false

# Brake animation tracking
var brake_animation_played = false

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	animation_player.play("idle")
	# Load the pellet scene
	pellet_scene = preload("res://Scenes/Props/base_pellet.tscn")
	# Setup ground raycast
	_setup_ground_raycast()

func _physics_process(delta):
	# Update jump reset timer
	if jump_reset_timer > 0:
		jump_reset_timer -= delta
	
	# Update brake timer
	if is_braking:
		brake_timer += delta
	
	# Update invincibility timer
	if is_invincible:
		invincibility_timer -= delta
		_handle_invincibility_flicker(delta)
		if invincibility_timer <= 0:
			is_invincible = false
			is_flickering = false
			sprite.modulate.a = 1.0  # Reset alpha to fully visible
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle left/right movement using input map actions
	var direction = Input.get_axis("ui_left", "ui_right")

	# Update animation (but don't override damage animation)
	if not animation_player.is_playing() or animation_player.current_animation != "take_damage":
		if is_braking:
			# Play brake animation only once when braking starts
			if not brake_animation_played:
				animation_player.play("brake")
				brake_animation_played = true
			# Handle sprite flipping during braking
			if direction != 0:
				sprite.flip_h = direction < 0
		else:
			# Reset brake animation flag when not braking
			brake_animation_played = false
			
			if direction != 0:
				animation_player.play("move")
				# Flip sprite based on movement direction
				sprite.flip_h = direction < 0
			elif direction == 0 and velocity.x != 0:
				animation_player.play("sliding")
			else:
				animation_player.play("idle")
	
	# Handle momentum-based horizontal movement
	_handle_momentum_movement(direction, delta)
	
	# Handle braking input
	_handle_braking_input(delta)
	
	# Handle jumping input
	_handle_jumping_input()
	
	# Handle shooting input
	_handle_shooting_input()
	
	# Handle screen wrapping
	_handle_screen_wrapping()
	
	move_and_slide()
	
	# Check for jump reset after movement
	_check_jump_reset()

func _handle_momentum_movement(direction: float, delta: float):
	# If we have input, accelerate in that direction
	if direction != 0:
		# Calculate target velocity based on direction and terminal velocity
		var target_velocity = direction * terminal_velocity
		
		# Use enhanced acceleration if we just finished braking
		var current_acceleration = acceleration
		if not is_braking and abs(velocity.x) < abs(pre_brake_velocity) * 0.5:
			current_acceleration = post_brake_acceleration
		
		# If we're changing direction (momentum reversal), apply braking first
		if (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0):
			# Apply stronger deceleration for direction change
			velocity.x = move_toward(velocity.x, 0, deceleration * deceleration_multiplier * delta)
		else:
			# Normal acceleration toward target velocity
			velocity.x = move_toward(velocity.x, target_velocity, current_acceleration * delta)
	else:
		# No input - only decelerate toward zero if on the ground
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		# If in air, maintain current horizontal velocity (no deceleration)

func _handle_braking_input(delta: float):
	if Input.is_action_just_pressed("brake") and is_on_floor():
		# Only allow braking if we have sufficient velocity and not already braking
		if abs(velocity.x) >= min_brake_velocity and not is_braking:
			is_braking = true
			pre_brake_velocity = velocity.x
			brake_timer = 0.0
	
	# Apply braking force during the brake duration
	if is_braking:
		# Apply moderate braking that preserves some momentum
		var target_velocity = pre_brake_velocity * brake_momentum_preservation
		velocity.x = move_toward(velocity.x, target_velocity, deceleration * brake_strength * delta)
				
		# Stop braking after duration expires
		if brake_timer >= brake_duration:
			is_braking = false

func _handle_jumping_input():
	# Check if space bar is pressed
	if Input.is_action_just_pressed("ui_accept") and can_jump:
		jump()

func _handle_shooting_input():
	# Check if left mouse button or up arrow is pressed
	if Input.is_action_pressed("fire") or Input.is_action_pressed("ui_up"):  # Using fire action for left click, ui_up as up arrow
		shoot();

func _handle_screen_wrapping():
	# Get the viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Check if player has gone off the left edge
	if global_position.x < 0:
		global_position.x = viewport_size.x
	
	# Check if player has gone off the right edge
	elif global_position.x > viewport_size.x:
		global_position.x = 0

func jump():
	# Set vertical velocity to jump velocity
	velocity.y = jump_velocity
	# Disable jumping until reset
	can_jump = false
	# Start jump reset timer
	jump_reset_timer = jump_reset_delay

func _setup_ground_raycast():
	# Configure the ground raycast to point downward
	ground_raycast.target_position = Vector2(0, 15)  # Cast 20 pixels downward
	ground_raycast.enabled = true
	ground_raycast.collision_mask = 1  # Only collide with layer 1 (default collision layer)

func _check_jump_reset():
	# Reset jump only if the ground raycast detects a collision (feet touching ground)
	if ground_raycast.is_colliding():
		# Only reset if the timer has expired (prevents immediate re-jump)
		if jump_reset_timer <= 0:
			can_jump = true

func shoot():
	if can_shoot:
		# Instantiate pellet at spawn point
		var pellet = pellet_scene.instantiate()
		get_parent().add_child(pellet)
		pellet.global_position = pellet_spawn_point.global_position
		
		# Fire the pellet upward
		pellet.fire(Vector2.UP)
		
		# Start fire rate cooldown
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true

func apply_enemy_contact(enemy: Node2D, damage: int):
	# Only take damage if not invincible
	if not is_invincible:
		print("Player hit by enemy: ", enemy.name, " with damage: ", damage)
		
		# Start invincibility period
		is_invincible = true
		invincibility_timer = invincibility_duration
		
		# Play damage animation
		animation_player.play("take_damage")
		
		# Get the actual duration of the damage animation
		var damage_animation_duration = animation_player.get_animation("take_damage").length
		
		# Start flickering after damage animation ends
		await get_tree().create_timer(damage_animation_duration).timeout
		if is_invincible:  # Only start flickering if still invincible
			is_flickering = true

func _handle_invincibility_flicker(delta: float):
	# Only flicker during the remaining invincibility time after damage animation
	if is_flickering:
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			flicker_timer = 0.0
			# Toggle sprite visibility
			if sprite.modulate.a == 1.0:
				sprite.modulate.a = 0.1  # Make semi-transparent
			else:
				sprite.modulate.a = 1.0  # Make fully visible