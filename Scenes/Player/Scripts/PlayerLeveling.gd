extends Node
class_name PlayerLeveling

## Handles all leveling-related functionality including experience gain and level progression.
## Manages experience points, level calculations, and level-up events.

# =============================================================================
# CONFIGURATION
# =============================================================================

## Base experience required for level 1
var base_exp_required: int

## Experience multiplier per level (exponential growth)
var exp_multiplier: float

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Current experience points
var current_exp: int = 0

## Current level
var current_level: int = 1

## Total experience required for next level
var exp_to_next_level: int

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when the player levels up
signal level_up(new_level: int)

## Emitted when experience is gained
signal experience_gained(amount: int, total_exp: int)

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the leveling system with a reference to the player."""
	player = player_node

func initialize():
	"""Initialize the leveling system after configuration values are set."""
	_calculate_exp_to_next_level()

# =============================================================================
# LEVELING SYSTEM
# =============================================================================

func gain_experience(amount: int):
	"""Add experience points and check for level up."""
	current_exp += amount
	print("Gained ", amount, " experience! Total: ", current_exp, " (Level ", current_level, ")")
	experience_gained.emit(amount, current_exp)
	
	# Check if we can level up
	while current_exp >= exp_to_next_level:
		_level_up()

func _level_up():
	"""Handle level up logic."""
	current_exp -= exp_to_next_level
	current_level += 1
	_calculate_exp_to_next_level()
	print("LEVEL UP! Now level ", current_level, "! Experience to next level: ", exp_to_next_level)
	level_up.emit(current_level)

func _calculate_exp_to_next_level():
	"""Calculate experience required for the next level."""
	exp_to_next_level = int(base_exp_required * pow(exp_multiplier, current_level - 1))

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func get_current_level() -> int:
	"""Get the current player level."""
	return current_level

func get_current_exp() -> int:
	"""Get the current experience points."""
	return current_exp

func get_exp_to_next_level() -> int:
	"""Get experience required for the next level."""
	return exp_to_next_level

func get_exp_progress() -> float:
	"""Get progress towards next level as a percentage (0.0 to 1.0)."""
	if exp_to_next_level == 0:
		return 1.0
	return float(current_exp) / float(exp_to_next_level)
