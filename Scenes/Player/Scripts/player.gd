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
var brake_timer = 0.0
var brake_duration = 0.5  # Brake duration in seconds

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
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle left/right movement using input map actions
	var direction = Input.get_axis("ui_left", "ui_right")

	# Update animation
	if direction != 0:
		animation_player.play("move")
		# Flip sprite based on movement direction
		sprite.flip_h = direction < 0
	elif direction == 0 and velocity.x != 0:
		animation_player.play("braking")
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
	# Check if brake action is pressed (Shift key) and we're on the ground
	if Input.is_action_pressed("brake") and is_on_floor():
		if not is_braking:
			# Start braking - store current velocity and reset timer
			is_braking = true
			pre_brake_velocity = velocity.x
			brake_timer = 0.0
		
		# Check if brake duration has expired
		if brake_timer >= brake_duration:
			# Stop braking after duration expires
			is_braking = false
		else:
			# Apply ice skating brake - preserve some momentum
			var target_velocity = pre_brake_velocity * brake_momentum_preservation
			velocity.x = move_toward(velocity.x, target_velocity, deceleration * brake_strength * delta)
	else:
		if is_braking:
			# Stop braking - enable quick acceleration
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
	print("Player hit by enemy: ", enemy.name, " with damage: ", damage);