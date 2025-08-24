extends CharacterBody2D

# Animation variables
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D

# Movement variables
var acceleration = 260.0  # How quickly we build up speed
var deceleration = 150.0  # How quickly we slow down
var deceleration_multiplier = 1.0  # How much faster we slow down when changing direction
var terminal_velocity = 180.0  # Maximum speed we can reach

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	animation_player.play("idle")

func _physics_process(delta):
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
	
	move_and_slide()

func _handle_momentum_movement(direction: float, delta: float):
	# If we have input, accelerate in that direction
	if direction != 0:
		# Calculate target velocity based on direction and terminal velocity
		var target_velocity = direction * terminal_velocity
		
		# If we're changing direction (momentum reversal), apply braking first
		if (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0):
			# Apply stronger deceleration for direction change
			velocity.x = move_toward(velocity.x, 0, deceleration * deceleration_multiplier * delta)
		else:
			# Normal acceleration toward target velocity
			velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		# No input - gradually decelerate toward zero
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

