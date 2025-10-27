@tool
extends RigidBody2D
class_name EnemyBase

## Generic enemy base class that can be configured for different enemy types.
## Supports bouncing, patrol, stationary, and following movement patterns.

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when the enemy dies
signal enemy_died

# =============================================================================
# EXPORTED VARIABLES
# =============================================================================

@export var max_health: int = 50
@export var contact_damage: int = 1
@export var xp_reward: int = 25

# =============================================================================
# RUNTIME STATE
# =============================================================================

var health: int
var enemy_data: EnemyData
var movement_type: String = "bouncing"
var is_dead: bool = false

# =============================================================================
# SYSTEM COMPONENTS
# =============================================================================

var effects_system
var animation_system

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var touch_damage: Area2D = $TouchDamage
@onready var touch_damage_shape: CollisionShape2D = $TouchDamage/CollisionShape2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	"""Initialize the enemy and all system components."""
	health = max_health
	
	# Initialize all systems
	effects_system = preload("res://Scenes/Enemies/Scripts/EnemyEffects.gd").new(self)
	animation_system = preload("res://Scenes/Enemies/Scripts/EnemyAnimation.gd").new(self)
	
	# Connect signals
	enemy_died.connect(_on_enemy_died)
	
	if is_instance_valid(touch_damage):
		touch_damage.body_entered.connect(_on_touch_damage_body_entered)
	
	# Connect to body_entered for bounce detection
	body_entered.connect(_on_body_entered)
	
	# Apply enemy data if it was set before nodes were ready
	if enemy_data:
		_apply_enemy_data()

# =============================================================================
# PHYSICS PROCESS
# =============================================================================

func _physics_process(_delta: float) -> void:
	"""Main physics update loop - stops when enemy is dead."""
	if is_dead:
		return
	
	# Handle different movement types
	match movement_type:
		"bouncing":
			_apply_bouncing_physics(_delta)
		"patrol":
			_apply_patrol_physics(_delta)
		"stationary":
			_apply_stationary_physics(_delta)
		"following":
			_apply_following_physics(_delta)

# =============================================================================
# MOVEMENT SYSTEMS
# =============================================================================

func _apply_bouncing_physics(_delta: float):
	"""Apply bouncing physics behavior - consistent height bouncing like Bubble Trouble."""
	var viewport_size = get_viewport().get_visible_rect().size
	var margin = 20.0
	
	# Check and bounce off horizontal walls
	if global_position.x < margin:
		global_position.x = margin
		linear_velocity.x = abs(linear_velocity.x) + 10.0  # Bounce right with boost
	elif global_position.x > viewport_size.x - margin:
		global_position.x = viewport_size.x - margin
		linear_velocity.x = -abs(linear_velocity.x) - 10.0  # Bounce left with boost
	
	# Check and bounce off vertical walls - THIS IS THE KEY
	if global_position.y < margin:
		global_position.y = margin
		linear_velocity.y = abs(linear_velocity.y) + 50.0  # Bounce down with boost
	elif global_position.y > viewport_size.y - margin:
		global_position.y = viewport_size.y - margin
		# FORCE strong upward bounce every time - higher for better curve
		linear_velocity.y = -440.0  # Fixed strong upward velocity for nice arc

func _apply_patrol_physics(_delta: float):
	"""Apply patrol physics behavior - walk left to right and turn around at edges."""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Ground-based patrol movement - stay on ground level
	linear_velocity.y = 0
	
	# Edge detection and turning
	if global_position.x <= 15:
		# Hit left edge, turn right
		linear_velocity.x = enemy_data.speed
		_flip_sprite_for_direction(1)
	elif global_position.x >= viewport_size.x - 15:
		# Hit right edge, turn left
		linear_velocity.x = -enemy_data.speed
		_flip_sprite_for_direction(-1)
	
	# Ensure minimum speed
	if abs(linear_velocity.x) < enemy_data.min_speed:
		linear_velocity.x = enemy_data.speed if linear_velocity.x >= 0 else -enemy_data.speed

func _apply_stationary_physics(_delta: float):
	"""Apply stationary physics behavior - no movement."""
	linear_velocity = Vector2.ZERO

func _apply_following_physics(_delta: float):
	"""Apply following physics behavior - move toward player."""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_position - global_position).normalized()
		linear_velocity = direction * enemy_data.speed
	else:
		# If no player, fall back to bouncing
		_apply_bouncing_physics(_delta)

func _maintain_minimum_speed():
	"""Maintain minimum speed with small random nudges."""
	var v := linear_velocity
	var current_speed := v.length()
	
	if current_speed < enemy_data.min_speed:
		var dir := v.normalized() if current_speed > 0.0 else Vector2.RIGHT.rotated(randf() * TAU)
		var jitter := deg_to_rad(randf_range(-2.0, 2.0))
		linear_velocity = dir.rotated(jitter) * enemy_data.min_speed

# =============================================================================
# VISUAL SYSTEM
# =============================================================================

func _flip_sprite_for_direction(direction: int):
	"""Flip sprite based on movement direction"""
	if sprite and enemy_data:
		var base_scale = enemy_data.sprite_scale
		sprite.scale.x = base_scale.x * direction
		sprite.scale.y = base_scale.y

# =============================================================================
# DAMAGE SYSTEM
# =============================================================================

func apply_pellet_hit(pellet: Node) -> void:
	"""Handle being hit by a pellet."""
	if "damage" in pellet and enemy_data.vulnerable_to_bullets:
		_take_damage(pellet.damage)

func apply_jump_damage() -> void:
	"""Handle being jumped on by the player."""
	if enemy_data and enemy_data.vulnerable_to_jumping:
		_take_damage(1)  # Jumping always does 1 damage

func _take_damage(amount: int) -> void:
	"""Take damage and handle death."""
	health -= amount
	
	# Play take damage animation
	effects_system.handle_take_damage(animation_system)
	
	if health <= 0:
		die()

func die() -> void:
	"""Handle enemy death."""
	if is_dead:
		return
	
	is_dead = true
	
	# Notify the player that this enemy was defeated and give XP
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_defeated"):
		player.on_enemy_defeated(xp_reward)
	
	# Handle death effects (includes death animation)
	effects_system.handle_death(animation_system)

# =============================================================================
# COLLISION HANDLING
# =============================================================================

func _on_touch_damage_body_entered(body: Node) -> void:
	"""Handle player contact with enemy."""
	# For jump-vulnerable enemies (golems), check if player is coming from above
	if enemy_data and enemy_data.vulnerable_to_jumping:
		# Check if player is above the enemy AND falling down (jumping on head)
		var player_velocity_y = body.velocity.y if "velocity" in body else 0
		var is_above = body.global_position.y < global_position.y
		var is_falling = player_velocity_y > 0
		
		if is_above and is_falling:
			return  # Skip touch damage when jumping on head from above
	
	if body.has_method("apply_enemy_contact"):
		body.apply_enemy_contact(self, contact_damage)

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func apply_enemy_data(data: EnemyData):
	"""Apply enemy data configuration to make this enemy generic and configurable."""
	enemy_data = data
	
	# Apply basic stats
	max_health = data.max_health
	contact_damage = data.contact_damage
	xp_reward = data.xp_reward
	health = max_health
	movement_type = data.movement_type
	
	# Apply visual settings
	if sprite:
		if data.texture:
			sprite.texture = data.texture
		sprite.scale = data.sprite_scale
		sprite.offset = data.sprite_offset
		sprite.modulate = data.sprite_modulate
	
	# Apply physics settings
	gravity_scale = data.gravity_scale
	
	# Apply physics material
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = data.friction
	physics_material.bounce = data.bounce
	physics_material_override = physics_material
	
	# Set collision layers - all enemies on layer 4
	collision_layer = 4  # All enemies on layer 4
	
	# Enemies pass through player completely - NO physics collision with player
	if data.movement_type == "patrol":
		collision_mask = 1  # Only collide with ground (1) to walk, NOT player (2) or enemies (4)
	else:
		collision_mask = 0  # Bouncing enemies don't collide with anything - free movement
	
	# Apply animation settings
	if animation_system:
		animation_system.set_animation_type(data.animation_type)
		animation_system.set_animation_speed(data.animation_speed)
	
	# Setup collision and start appropriate animation
	call_deferred("_apply_enemy_data")

func _apply_enemy_data():
	"""Deferred application of enemy data after nodes are ready."""
	if not enemy_data:
		return
	
	_setup_collision_from_data()
	_start_appropriate_animation()
	_apply_initial_movement()

func _setup_collision_from_data():
	"""Setup collision based on enemy data."""
	if not collision_shape or not enemy_data:
		return
	
	# Create collision shapes
	if enemy_data.collision_shape == "rectangle":
		_setup_rectangle_collision()
	else:
		_setup_circle_collision()
	
	# Setup touch damage area
	if touch_damage_shape:
		# Configure Area2D to detect player on layer 2
		touch_damage.collision_layer = 0  # Touch damage doesn't need a layer
		touch_damage.collision_mask = 2   # Detect player on layer 2
		
		touch_damage_shape.shape = CircleShape2D.new()
		var scale_factor = (enemy_data.sprite_scale.x + enemy_data.sprite_scale.y) / 2.0
		var scaled_touch_radius = enemy_data.touch_damage_radius * scale_factor
		touch_damage_shape.shape.radius = scaled_touch_radius
		
		# For golems, position touch damage at body level (not head)
		if enemy_data.movement_type == "patrol":
			# Position touch damage at body level so head is safe for jumping
			touch_damage.position = Vector2(0, 8 * enemy_data.sprite_scale.y)
			# Make the touch damage area smaller - only the lower body
			touch_damage_shape.shape.radius = scaled_touch_radius * 0.4

func _setup_rectangle_collision():
	"""Setup rectangle collision shape."""
	collision_shape.shape = RectangleShape2D.new()
	var scale_factor = min(enemy_data.sprite_scale.x, enemy_data.sprite_scale.y)
	# Make collision tighter - width and height proportional
	var scaled_width = enemy_data.collision_radius * scale_factor * 1.2
	var scaled_height = enemy_data.collision_radius * scale_factor * 1.5
	collision_shape.shape.size = Vector2(scaled_width, scaled_height)

func _setup_circle_collision():
	"""Setup circle collision shape."""
	collision_shape.shape = CircleShape2D.new()
	var scale_factor = (enemy_data.sprite_scale.x + enemy_data.sprite_scale.y) / 2.0
	collision_shape.shape.radius = enemy_data.collision_radius * scale_factor

func _start_appropriate_animation():
	"""Start the appropriate animation based on movement type."""
	if animation_system:
		if movement_type == "patrol":
			animation_system.start_walking_animation()
		else:
			animation_system.start_idle_animation()

func _apply_initial_movement():
	"""Apply initial movement based on movement type."""
	match movement_type:
		"bouncing":
			# Give the ball strong upward and horizontal velocity for proper bouncing
			var horizontal_speed = randf_range(80.0, 120.0) * (1 if randf() > 0.5 else -1)
			var vertical_speed = -randf_range(250.0, 350.0)  # Strong upward velocity
			linear_velocity = Vector2(horizontal_speed, vertical_speed)
		"patrol":
			var spawn_speed := randf_range(enemy_data.min_speed, enemy_data.max_speed)
			linear_velocity = Vector2.RIGHT * spawn_speed
		"stationary":
			linear_velocity = Vector2.ZERO
		"following":
			var angle := randf_range(0, TAU)
			var spawn_speed := randf_range(enemy_data.min_speed, enemy_data.max_speed)
			var dir := Vector2.RIGHT.rotated(angle)
			linear_velocity = dir * spawn_speed

# =============================================================================
# GETTERS
# =============================================================================

func get_current_health() -> int:
	"""Get the current health."""
	return health

func get_max_health() -> int:
	"""Get the maximum health."""
	return max_health

func is_enemy_dead() -> bool:
	"""Check if the enemy is dead."""
	return is_dead

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_enemy_died():
	"""Signal handler for enemy death."""
	print("Enemy died: ", name)

func _on_body_entered(body: Node):
	"""Handle collision with other bodies for bouncing."""
	if movement_type != "bouncing":
		return
	
	# This will help with collision-based bouncing if needed
	# For now, position-based bouncing should work
