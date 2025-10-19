extends Node

## Global singleton to store game statistics between scenes.
## Used to pass data from main game to game over screen.

# =============================================================================
# GAME STATISTICS
# =============================================================================

## Final level reached when player died
var final_level: int = 1

## Number of enemies defeated
var enemies_defeated: int = 0

## Time survived in seconds
var time_survived: float = 0.0

## Number of items collected
var items_collected: int = 0

# =============================================================================
# UTILITY METHODS
# =============================================================================

func reset_stats():
	"""Reset all statistics to default values."""
	final_level = 1
	enemies_defeated = 0
	time_survived = 0.0
	items_collected = 0
