extends CharacterBody2D

## Player character controller using composition pattern.
## Delegates functionality to specialized system classes for better organization and maintainability.

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when the player shoots
signal player_shot

## Emitted when the player dies
signal player_died

# =============================================================================
# EXPORTED VARIABLES (Delegated to Systems)
# =============================================================================

# Movement System Exports
@export_group("Movement")
@export var brake_strength: float = 5.0
@export var brake_momentum_preservation: float = 0.3
@export var post_brake_acceleration: float = 400.0
@export var jump_velocity: float = -275.0

# Effects System Exports
@export_group("Effects")
@export var knockback_force: float = 150.0
@export var screen_shake_intensity: float = 0.5
@export var screen_shake_duration: float = 0.4

# Leveling System Exports
@export_group("Leveling")
@export var base_exp_required: int = 50
@export var exp_multiplier: float = 1.2

# =============================================================================
# SYSTEM COMPONENTS
# =============================================================================

var movement_system
var combat_system
var animation_system
var effects_system
var leveling_system
var loot_system
var stats_system

# Health System
var current_health: int
var is_dead: bool = false

# =============================================================================
# GODOT LIFECYCLE
# =============================================================================

func _ready():
	"""Initialize the player character and all system components."""
	# Add player to group for easy access by enemies
	add_to_group("player")
	
	
	
	# Initialize all systems
	stats_system = preload("res://Scenes/Player/Scripts/PlayerStats.gd").new(self)
	movement_system = preload("res://Scenes/Player/Scripts/PlayerMovement.gd").new(self)
	combat_system = preload("res://Scenes/Player/Scripts/PlayerCombat.gd").new(self)
	animation_system = preload("res://Scenes/Player/Scripts/PlayerAnimation.gd").new(self)
	effects_system = preload("res://Scenes/Player/Scripts/PlayerEffects.gd").new(self)
	leveling_system = preload("res://Scenes/Player/Scripts/PlayerLeveling.gd").new(self)
	loot_system = preload("res://Scenes/Player/Scripts/PlayerLoot.gd").new(self)
	
	# Pass exported values to systems
	_configure_systems()
	
	# Initialize health
	current_health = get_max_health()

	# Connect signals
	player_shot.connect(_on_player_shot)
	player_died.connect(_on_player_died)
	stats_system.stat_changed.connect(_on_stat_changed)
	
	# Start with idle animation
	animation_system.update_animation(movement_system)
	
	# Debug: Print initial stats
	stats_system.print_all_stats()

func _configure_systems():
	"""Configure all systems with exported values."""
	# Configure movement system
	movement_system.brake_strength = brake_strength
	movement_system.brake_momentum_preservation = brake_momentum_preservation
	movement_system.post_brake_acceleration = post_brake_acceleration
	movement_system.jump_velocity = jump_velocity
	
	# Configure effects system
	effects_system.knockback_force = knockback_force
	effects_system.screen_shake_intensity = screen_shake_intensity
	effects_system.screen_shake_duration = screen_shake_duration
	
	# Configure leveling system
	leveling_system.base_exp_required = base_exp_required
	leveling_system.exp_multiplier = exp_multiplier
	leveling_system.initialize()
	
	# Configure loot system
	loot_system.initialize()

func _physics_process(delta: float):
	"""Main physics update loop - delegates to system components."""
	# Don't update systems if player is dead
	if is_dead:
		return
	
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

func on_enemy_defeated(xp_amount: int):
	"""Handle enemy defeat - delegates to leveling system."""
	leveling_system.gain_experience(xp_amount)

# =============================================================================
# SYSTEM ACCESS (for external systems that need to query player state)
# =============================================================================

func is_invincible() -> bool:
	"""Check if the player is currently invincible."""
	return effects_system.is_player_invincible()

func is_braking() -> bool:
	"""Check if the player is currently braking."""
	return movement_system.is_player_braking()

func get_level() -> int:
	"""Get the current player level."""
	return leveling_system.get_current_level()

func get_experience() -> int:
	"""Get the current experience points."""
	return leveling_system.get_current_exp()

func get_exp_to_next_level() -> int:
	"""Get experience required for the next level."""
	return leveling_system.get_exp_to_next_level()

func get_active_items() -> Array:
	"""Get the player's currently active items."""
	return loot_system.get_active_items()

func has_item(item_name: String) -> bool:
	"""Check if the player has a specific item."""
	return loot_system.has_item(item_name)

func get_current_health() -> int:
	"""Get the current health."""
	return current_health

func get_max_health() -> int:
	"""Get the current maximum health from the stats system."""
	return int(stats_system.get_stat_value(PlayerStats.StatType.MAX_HEALTH))

func is_player_dead() -> bool:
	"""Check if the player is dead."""
	return is_dead

# =============================================================================
# STATS SYSTEM ACCESS
# =============================================================================

func get_fire_rate() -> float:
	"""Get the current fire rate from the stats system."""
	return stats_system.get_stat_value(PlayerStats.StatType.FIRE_RATE)

func get_attack() -> float:
	"""Get the current attack value from the stats system."""
	return stats_system.get_stat_value(PlayerStats.StatType.ATTACK)

func get_move_speed() -> float:
	"""Get the current movement speed multiplier from the stats system."""
	return stats_system.get_stat_value(PlayerStats.StatType.MOVE_SPEED)

func _on_player_died():
	"""Signal handler for player death - can be overridden by external systems."""
	print("Player died -- player.gd")
	pass

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_player_shot():
	"""Handle player shot signal - notify effects system."""
	effects_system.on_player_shoot()

func _on_stat_changed(stat_type: PlayerStats.StatType, old_value: float, new_value: float):
	"""
	Handle stat changes from the stats system.
	
	Args:
		stat_type: The type of stat that changed
		old_value: The previous value
		new_value: The new value
	"""
	# When max_health increases, add the health increase to current health
	if stat_type == PlayerStats.StatType.MAX_HEALTH:
		var health_increase = int(new_value) - int(old_value)
		if health_increase > 0:
			current_health += health_increase
			# Ensure current health doesn't exceed max health
			current_health = min(current_health, int(new_value))
			print("Health increased! Current: ", current_health, " / Max: ", int(new_value))
