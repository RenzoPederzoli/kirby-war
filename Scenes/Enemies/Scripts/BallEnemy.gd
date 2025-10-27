extends RigidBody2D
class_name BallEnemy

## Simple bouncing ball like Bubble Trouble

# =============================================================================
# BALL PROPERTIES
# =============================================================================

@export var bounce_speed: float = 100.0  # Consistent bounce speed
@export var bounce_angle: float = 45.0   # Bounce angle in degrees (45 = diagonal)
@export var gravity_strength: float = 500.0  # Gravity strength for realistic bouncing

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	"""Initialize the ball with simple bouncing physics."""
	# Set up physics material for good bouncing
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = 0.0
	physics_material.bounce = 1.0
	physics_material_override = physics_material
	
	# Set collision layers
	collision_layer = 2  # Ball is on layer 2
	collision_mask = 1   # Only collide with player (layer 1)
	
	# Set initial random velocity
	_set_random_initial_velocity()

# =============================================================================
# PHYSICS PROCESS
# =============================================================================

func _physics_process(_delta: float) -> void:
	"""Simple bouncing physics like Bubble Trouble."""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Apply gravity for realistic bouncing
	linear_velocity.y += gravity_strength * _delta
	
	# Handle edge bouncing with consistent speed
	if global_position.x <= 15:
		# Hit left edge, bounce right
		_bounce_horizontal(1)
	elif global_position.x >= viewport_size.x - 15:
		# Hit right edge, bounce left
		_bounce_horizontal(-1)
	
	if global_position.y <= 15:
		# Hit top edge, bounce down
		_bounce_vertical(1)
	elif global_position.y >= viewport_size.y - 15:
		# Hit bottom edge, bounce up
		_bounce_vertical(-1)

func _bounce_horizontal(direction: int):
	"""Bounce horizontally with consistent speed and angle."""
	var angle_rad = deg_to_rad(bounce_angle)
	linear_velocity.x = direction * bounce_speed * cos(angle_rad)
	linear_velocity.y = bounce_speed * sin(angle_rad)
	print("Ball horizontal bounce - direction: ", direction, " speed: ", bounce_speed)

func _bounce_vertical(direction: int):
	"""Bounce vertically with consistent speed and angle."""
	var angle_rad = deg_to_rad(bounce_angle)
	linear_velocity.x = bounce_speed * cos(angle_rad) * (1 if linear_velocity.x >= 0 else -1)
	linear_velocity.y = direction * bounce_speed * sin(angle_rad)
	print("Ball vertical bounce - direction: ", direction, " speed: ", bounce_speed)

# =============================================================================
# SIMPLE METHODS
# =============================================================================

func _set_random_initial_velocity():
	"""Set a random initial velocity for the ball."""
	var angle := randf_range(0.1, PI - 0.1)  # Avoid perfectly horizontal/vertical
	var dir := Vector2.RIGHT.rotated(angle)
	linear_velocity = dir * bounce_speed
	print("Ball initial velocity set: ", linear_velocity, " (speed: ", bounce_speed, ")")

func set_bounce_speed(new_speed: float):
	"""Set the bounce speed for the ball."""
	bounce_speed = new_speed
	print("Ball bounce speed set to: ", bounce_speed)

func set_bounce_angle(new_angle: float):
	"""Set the bounce angle for the ball."""
	bounce_angle = new_angle
	print("Ball bounce angle set to: ", bounce_angle, " degrees")

func set_gravity_strength(new_gravity: float):
	"""Set the gravity strength for the ball."""
	gravity_strength = new_gravity
	print("Ball gravity strength set to: ", gravity_strength)

func reset_bounce():
	"""Reset the ball to a random bounce direction."""
	_set_random_initial_velocity()
