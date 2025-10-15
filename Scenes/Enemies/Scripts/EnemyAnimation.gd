extends Node
class_name EnemyAnimation

## Handles all enemy animation logic and sprite management.
## Manages animation states and visual effects.

# =============================================================================
# NODE REFERENCES
# =============================================================================

var enemy: RigidBody2D
var animation_player: AnimationPlayer
var sprite: Sprite2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(enemy_node: RigidBody2D):
	"""Initialize the animation system with a reference to the enemy."""
	enemy = enemy_node
	animation_player = enemy.get_node("AnimationPlayer")
	sprite = enemy.get_node("Sprite2D")

# =============================================================================
# ANIMATION MANAGEMENT
# =============================================================================

func start_idle_animation():
	"""Start the idle animation (looping)."""
	animation_player.play("idle")

func play_take_damage_animation():
	"""Play the take damage animation (one-shot)."""
	animation_player.play("take_damage")

func return_to_idle():
	"""Return to idle animation."""
	animation_player.play("idle")

func play_death_animation():
	"""Play the death animation (one-shot)."""
	animation_player.play("death")

func get_take_damage_animation_duration() -> float:
	"""Get the duration of the take damage animation."""
	return animation_player.get_animation("take_damage").length

func get_death_animation_duration() -> float:
	"""Get the duration of the death animation."""
	return animation_player.get_animation("death").length
