extends RigidBody2D
class_name EnemyBase

## Enemy base class using composition pattern.
## Delegates functionality to specialized system classes for better organization and maintainability.

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

@export var min_spawn_speed: float = 80.0
@export var max_spawn_speed: float = 120.0     # random ±deg on bounce to vary direction

@export var min_speed: float = 75.0
@export var keepalive_jitter_deg: float = 2.0

# =============================================================================
# RUNTIME STATE
# =============================================================================

var health: int

# =============================================================================
# SYSTEM COMPONENTS
# =============================================================================

var effects_system
var animation_system

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var touch_damage: Area2D = $TouchDamage

func _ready() -> void:
	"""Initialize the enemy and all system components."""
	health = max_health
	
	# Initialize all systems
	effects_system = preload("res://Scenes/Enemies/Scripts/EnemyEffects.gd").new(self)
	animation_system = preload("res://Scenes/Enemies/Scripts/EnemyAnimation.gd").new(self)
	
	# Connect signals
	enemy_died.connect(_on_enemy_died)
	
	if is_instance_valid(touch_damage):
		touch_damage.body_entered.connect(_on_touch_damage_body_entered);

	# Start idle animation
	animation_system.start_idle_animation()

	# Randomize initial velocity
	var angle := randf_range(0.05, PI - 0.05) # small margin to avoid perfectly horizontal
	var spawn_speed := randf_range(min_spawn_speed, max_spawn_speed)
	var dir := Vector2.RIGHT.rotated(angle)   # unit direction vector
	set_initial_velocity(dir * spawn_speed)

func _physics_process(_delta: float) -> void:
	"""Main physics update loop - stops when enemy is dead."""
	# Don't update physics if enemy is dead
	if effects_system.is_enemy_dead():
		return
		
	var v := linear_velocity
	var speed := v.length()
	if speed < min_speed:
		var dir := v.normalized() if speed > 0.0 else Vector2.RIGHT.rotated(randf() * TAU)
		# Small random nudge so it doesn't stick on edges
		var jitter := deg_to_rad(randf_range(-keepalive_jitter_deg, keepalive_jitter_deg))
		linear_velocity = dir.rotated(jitter) * min_speed

func set_initial_velocity(v: Vector2) -> void:
	linear_velocity = v

# Called by your pellet (see your BasePellet.fire/impact flow)
func apply_pellet_hit(pellet: Node) -> void:
	if "damage" in pellet:
		_take_damage(pellet.damage)

func _take_damage(amount: int) -> void:
	health -= amount
	
	# Play take damage animation
	effects_system.handle_take_damage(animation_system)
	
	if health <= 0:
		die()

func die() -> void:
	"""Handle enemy death - delegates to effects system."""
	# Notify the player that this enemy was defeated and give XP
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_defeated"):
		player.on_enemy_defeated(xp_reward)
	
	# Handle death effects (includes death animation)
	effects_system.handle_death(animation_system)

func _on_touch_damage_body_entered(body: Node) -> void:
	if body.has_method("apply_enemy_contact"):
		body.apply_enemy_contact(self, contact_damage)

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func get_current_health() -> int:
	"""Get the current health."""
	return health

func get_max_health() -> int:
	"""Get the maximum health."""
	return max_health

func is_enemy_dead() -> bool:
	"""Check if the enemy is dead."""
	return effects_system.is_enemy_dead()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_enemy_died():
	"""Signal handler for enemy death - can be overridden by external systems."""
	print("Enemy died -- enemy_base.gd")
	pass
