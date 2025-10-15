extends Node
class_name PlayerAnimation

## Handles all player animation logic and sprite management.
## Manages animation states, sprite flipping, and visual effects.

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D
var animation_player: AnimationPlayer
var sprite: Sprite2D

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the animation system with a reference to the player."""
	player = player_node
	animation_player = player.get_node("AnimationPlayer")
	sprite = player.get_node("Sprite2D")

# =============================================================================
# ANIMATION MANAGEMENT
# =============================================================================

func update_animation(movement_system):
	"""Update player animations based on current state."""
	# Don't update animations if player is dead
	if player.is_dead:
		return
		
	if not animation_player.is_playing() or animation_player.current_animation != "take_damage":
		if not player.is_on_floor():
			if player.velocity.y < 0:
				animation_player.play("rise")
			else:
				animation_player.play("fall")
		elif movement_system.is_player_braking():
			if movement_system.should_play_brake_animation():
				animation_player.play("brake")
				movement_system.mark_brake_animation_played()
		else:
			# Reset brake animation flag when not braking
			movement_system.reset_brake_animation_flag()
			
			var direction = Input.get_axis("ui_left", "ui_right")
			
			if direction != 0:
				animation_player.play("move")
			elif direction == 0 and player.velocity.x != 0:
				animation_player.play("sliding")
			else:
				animation_player.play("idle")

func update_sprite_direction():
	"""Flip sprite based on movement direction."""
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		sprite.flip_h = direction < 0

func play_damage_animation():
	"""Play the damage animation."""
	animation_player.play("take_damage")

func get_damage_animation_duration() -> float:
	"""Get the duration of the damage animation."""
	return animation_player.get_animation("take_damage").length

func play_death_animation():
	"""Play the death animation."""
	animation_player.play("death")