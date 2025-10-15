extends Node
class_name EnemyEffects

## Handles all visual and gameplay effects for enemies including death handling.
## Manages death effects and visual feedback.

# =============================================================================
# CONFIGURATION
# =============================================================================

## Duration of death animation before enemy is removed
var death_animation_duration: float = 0.85

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Whether the enemy is currently dead
var is_dead: bool = false

# =============================================================================
# NODE REFERENCES
# =============================================================================

var enemy: RigidBody2D
var sprite: Sprite2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(enemy_node: RigidBody2D):
	"""Initialize the effects system with a reference to the enemy."""
	enemy = enemy_node
	sprite = enemy.get_node("Sprite2D")

# =============================================================================
# DAMAGE SYSTEM
# =============================================================================

func handle_take_damage(animation_system):
	"""Handle enemy taking damage - play take damage animation and return to idle."""
	if not is_dead:
		print("Enemy took damage: ", enemy.name)
		animation_system.play_take_damage_animation()
		
		# Wait for take damage animation to complete, then return to idle
		var take_damage_duration = animation_system.get_take_damage_animation_duration()
		await enemy.get_tree().create_timer(take_damage_duration).timeout
		
		# Only return to idle if enemy is not dead
		if not is_dead:
			animation_system.return_to_idle()

# =============================================================================
# DEATH SYSTEM
# =============================================================================

func handle_death(animation_system):
	"""Handle enemy death - play death animation and emit signal."""
	if not is_dead:
		is_dead = true
		print("Enemy died: ", enemy.name)
		
		# Play death animation
		animation_system.play_death_animation()
		
		# Disable physics and collision
		enemy.set_deferred("freeze", true)
		enemy.set_deferred("collision_layer", 0)
		enemy.set_deferred("collision_mask", 0)
		
		# Emit death signal
		enemy.enemy_died.emit()
		
		# Wait for death animation to complete before removing
		await enemy.get_tree().create_timer(death_animation_duration).timeout
		enemy.queue_free()

# =============================================================================
# STATE QUERIES
# =============================================================================

func is_enemy_dead() -> bool:
	"""Check if the enemy is currently dead."""
	return is_dead
