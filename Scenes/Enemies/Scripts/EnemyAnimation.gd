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
# ANIMATION TYPE CONFIGURATION
# =============================================================================

var animation_type: String = "sphere"

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(enemy_node: RigidBody2D):
	"""Initialize the animation system with a reference to the enemy."""
	enemy = enemy_node
	animation_player = enemy.get_node("AnimationPlayer")
	sprite = enemy.get_node("Sprite2D")

func set_animation_type(type: String):
	"""Set the animation type for this enemy."""
	animation_type = type
	print("Animation system - Set animation type to: ", animation_type)

# =============================================================================
# ANIMATION MANAGEMENT
# =============================================================================

func start_idle_animation():
	"""Start the idle animation (looping)."""
	var animation_name = "idle"
	if animation_type == "golem":
		animation_name = "golem_walking"
	animation_player.play(animation_name)
	print("Playing idle animation: ", animation_name, " (type: ", animation_type, ")")

func start_walking_animation():
	"""Start the walking animation (looping)."""
	var animation_name = "walking"
	if animation_type == "golem":
		animation_name = "golem_walking"
	animation_player.play(animation_name)
	print("Playing walking animation: ", animation_name, " (type: ", animation_type, ")")

func set_animation_speed(speed: float):
	"""Set the animation playback speed."""
	animation_player.speed_scale = speed

func play_take_damage_animation():
	"""Play the take damage animation (one-shot)."""
	var animation_name = "take_damage"
	if animation_type == "golem":
		animation_name = "take_damage"  # Golems can use the same take damage animation
	animation_player.play(animation_name)
	print("Playing take damage animation: ", animation_name)

func return_to_idle():
	"""Return to idle animation."""
	start_idle_animation()

func play_death_animation():
	"""Play the death animation (one-shot)."""
	var animation_name = "death"
	if animation_type == "golem":
		animation_name = "golem_death"
	animation_player.play(animation_name)
	print("Playing death animation: ", animation_name)

func get_take_damage_animation_duration() -> float:
	"""Get the duration of the take damage animation."""
	return animation_player.get_animation("take_damage").length

func get_death_animation_duration() -> float:
	"""Get the duration of the death animation."""
	return animation_player.get_animation("death").length
