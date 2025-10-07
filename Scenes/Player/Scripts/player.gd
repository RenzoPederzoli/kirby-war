extends CharacterBody2D

## Player character controller using composition pattern.
## Delegates functionality to specialized system classes for better organization and maintainability.

# =============================================================================
# EXPORTED VARIABLES (Delegated to Systems)
# =============================================================================

# Movement System Exports
@export_group("Movement")
@export var brake_strength: float = 5.0
@export var brake_momentum_preservation: float = 0.3
@export var post_brake_acceleration: float = 400.0
@export var jump_velocity: float = -275.0

# Combat System Exports
@export_group("Combat")
@export var fire_rate: float = 0.2

# Effects System Exports
@export_group("Effects")
@export var knockback_force: float = 150.0
@export var screen_shake_intensity: float = 0.5
@export var screen_shake_duration: float = 0.4

# =============================================================================
# SYSTEM COMPONENTS
# =============================================================================

var movement_system
var combat_system
var animation_system
var effects_system

# =============================================================================
# GODOT LIFECYCLE
# =============================================================================

func _ready():
	"""Initialize the player character and all system components."""
	# Initialize all systems
	movement_system = preload("res://Scenes/Player/Scripts/PlayerMovement.gd").new(self)
	combat_system = preload("res://Scenes/Player/Scripts/PlayerCombat.gd").new(self)
	animation_system = preload("res://Scenes/Player/Scripts/PlayerAnimation.gd").new(self)
	effects_system = preload("res://Scenes/Player/Scripts/PlayerEffects.gd").new(self)
	
	# Pass exported values to systems
	_configure_systems()
	
	# Start with idle animation
	animation_system.update_animation(movement_system)

func _configure_systems():
	"""Configure all systems with exported values."""
	# Configure movement system
	movement_system.brake_strength = brake_strength
	movement_system.brake_momentum_preservation = brake_momentum_preservation
	movement_system.post_brake_acceleration = post_brake_acceleration
	movement_system.jump_velocity = jump_velocity
	
	# Configure combat system
	combat_system.fire_rate = fire_rate
	
	# Configure effects system
	effects_system.knockback_force = knockback_force
	effects_system.screen_shake_intensity = screen_shake_intensity
	effects_system.screen_shake_duration = screen_shake_duration

func _physics_process(delta: float):
	"""Main physics update loop - delegates to system components."""
	# Update all systems
	movement_system.update_movement(delta)
	combat_system.update_combat()
	effects_system.update_effects(delta)
	
	# Update animations and visuals
	animation_system.update_animation(movement_system)
	animation_system.update_sprite_direction()
	
	# Apply physics
	move_and_slide()
	
	# Check for jump reset after movement
	movement_system.check_jump_reset()

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func apply_enemy_contact(enemy: Node2D, damage: int):
	"""Handle damage from enemy contact - delegates to effects system."""
	effects_system.apply_enemy_contact(enemy, damage, animation_system)

# =============================================================================
# SYSTEM ACCESS (for external systems that need to query player state)
# =============================================================================

func is_invincible() -> bool:
	"""Check if the player is currently invincible."""
	return effects_system.is_player_invincible()

func is_braking() -> bool:
	"""Check if the player is currently braking."""
	return movement_system.is_player_braking()
