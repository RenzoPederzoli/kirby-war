extends Node
class_name PlayerStats

## Stat management system for player-modifiable statistics.
## Handles base values and modifiers from items for stats that players can upgrade.

# =============================================================================
# STAT DEFINITIONS
# =============================================================================

## Enum defining all player-modifiable stats
enum StatType {
	FIRE_RATE,    # Time between shots in seconds
	ATTACK,       # Attack damage
	MOVE_SPEED,   # Movement speed multiplier (affects terminal velocity for now)
	MAX_HEALTH    # Maximum health/hearts
}

## Base stat values - these are the starting values for each stat
const BASE_STATS: Dictionary = {
	StatType.FIRE_RATE: 0.2,
	StatType.ATTACK: 1.0,
	StatType.MOVE_SPEED: 1.0,
	StatType.MAX_HEALTH: 3.0
}

## Stat names for easy reference and debugging
const STAT_NAMES: Dictionary = {
	StatType.FIRE_RATE: "Fire Rate",
	StatType.ATTACK: "Attack",
	StatType.MOVE_SPEED: "Move Speed",
	StatType.MAX_HEALTH: "Max Health"
}

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Current base values for each stat
var base_values: Dictionary = {}

## Additive modifiers from items (applied first)
var additive_modifiers: Dictionary = {}

## Multiplicative modifiers from items (applied after additive)
var multiplicative_modifiers: Dictionary = {}

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when any stat changes
signal stat_changed(stat_type: StatType, old_value: float, new_value: float)

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the stats system with a reference to the player."""
	player = player_node
	_initialize_base_values()

func _initialize_base_values():
	"""Set up initial base values for all stats."""
	for stat_type in StatType.values():
		base_values[stat_type] = BASE_STATS[stat_type]
		additive_modifiers[stat_type] = 0.0
		multiplicative_modifiers[stat_type] = 1.0

# =============================================================================
# STAT ACCESS
# =============================================================================

func get_stat_value(stat_type: StatType) -> float:
	"""
	Get the current calculated value of a stat.
	
	Args:
		stat_type: The stat to get the value for
		
	Returns:
		The final calculated stat value: (base + additive) * multiplicative
	"""
	var base_value = base_values.get(stat_type, 0.0)
	var additive = additive_modifiers.get(stat_type, 0.0)
	var multiplicative = multiplicative_modifiers.get(stat_type, 1.0)
	
	return (base_value + additive) * multiplicative

func get_base_stat_value(stat_type: StatType) -> float:
	"""Get the base value of a stat (without modifiers)."""
	return base_values.get(stat_type, 0.0)

# =============================================================================
# STAT MODIFICATION
# =============================================================================

func set_base_stat(stat_type: StatType, value: float):
	"""
	Set the base value of a stat.
	
	Args:
		stat_type: The stat to modify
		value: The new base value
	"""
	var old_value = get_stat_value(stat_type)
	base_values[stat_type] = value
	var new_value = get_stat_value(stat_type)
	
	if old_value != new_value:
		stat_changed.emit(stat_type, old_value, new_value)

func add_stat_modifier(stat_type: StatType, amount: float):
	"""
	Add an additive modifier to a stat.
	
	Args:
		stat_type: The stat to modify
		amount: The amount to add
	"""
	var old_value = get_stat_value(stat_type)
	additive_modifiers[stat_type] += amount
	var new_value = get_stat_value(stat_type)
	
	if old_value != new_value:
		stat_changed.emit(stat_type, old_value, new_value)

func multiply_stat_modifier(stat_type: StatType, multiplier: float):
	"""
	Add a multiplicative modifier to a stat.
	
	Args:
		stat_type: The stat to modify
		multiplier: The multiplier to apply
	"""
	var old_value = get_stat_value(stat_type)
	multiplicative_modifiers[stat_type] *= multiplier
	var new_value = get_stat_value(stat_type)
	
	if old_value != new_value:
		stat_changed.emit(stat_type, old_value, new_value)

# =============================================================================
# ITEM EFFECT MANAGEMENT
# =============================================================================

func apply_item_effect(item: LootItem):
	"""
	Apply an item's effect to the stats system.

	Args:
		item: The LootItem containing effect data
	"""
	if not item.effect_data.has("stat"):
		print("Warning: Item '", item.item_name, "' has no stat in effect_data")
		return

	var stat_name = item.effect_data["stat"]
	var modifier = item.effect_data.get("modifier", 0.0)
	var effect_type = item.effect_data.get("effect_type", "additive")

	# Handle "all" stats case
	if stat_name.to_lower() == "all":
		_apply_effect_to_all_stats(item, modifier, effect_type)
		return

	# Handle "combat" stats case (excludes health)
	if stat_name.to_lower() == "combat":
		_apply_effect_to_combat_stats(item, modifier, effect_type)
		return

	var stat_type = _get_stat_type_from_name(stat_name)

	# Check if it's a valid stat name (not the default fallback)
	var valid_stat_names = ["fire_rate", "shoot_rate", "attack_speed", "attack", "damage", "move_speed", "speed", "movement_speed", "max_health", "health", "hearts"]
	if not stat_name.to_lower() in valid_stat_names:
		print("Warning: Unknown stat '", stat_name, "' in item '", item.item_name, "'")
		return

	_apply_single_stat_effect(stat_type, modifier, effect_type, item.item_name, stat_name)

func _apply_single_stat_effect(stat_type: StatType, modifier: float, effect_type: String, item_name: String, stat_name: String):
	"""Apply an effect to a single stat."""
	match effect_type:
		"additive":
			add_stat_modifier(stat_type, modifier)
		"multiplicative":
			multiply_stat_modifier(stat_type, modifier)
		"set_base":
			set_base_stat(stat_type, modifier)
		_:
			print("Warning: Unknown effect_type '", effect_type, "' in item '", item_name, "'")
			return

	print("Applied effect from '", item_name, "': ", stat_name, " ", effect_type, " ", modifier)
	print("New ", stat_name, ": ", get_stat_value(stat_type))

func _apply_effect_to_all_stats(item: LootItem, modifier: float, effect_type: String):
	"""Apply an effect to all stats at once."""
	print("Applying '", item.item_name, "' effect to ALL stats:")

	for stat_type in StatType.values():
		var stat_name = get_stat_name(stat_type)
		_apply_single_stat_effect(stat_type, modifier, effect_type, item.item_name, stat_name)

func _apply_effect_to_combat_stats(item: LootItem, modifier: float, effect_type: String):
	"""Apply an effect to combat stats (excludes MAX_HEALTH for integer-based hearts)."""
	print("Applying '", item.item_name, "' effect to COMBAT stats:")

	for stat_type in StatType.values():
		# Skip health since it's integer-based (hearts)
		if stat_type == StatType.MAX_HEALTH:
			continue
		var stat_name = get_stat_name(stat_type)
		_apply_single_stat_effect(stat_type, modifier, effect_type, item.item_name, stat_name)

# =============================================================================
# UTILITY METHODS
# =============================================================================

func _get_stat_type_from_name(stat_name: String) -> StatType:
	"""
	Convert a stat name string to a StatType enum value.
	
	Args:
		stat_name: The stat name to convert
		
	Returns:
		The corresponding StatType, or FIRE_RATE as default if not found
	"""
	match stat_name.to_lower():
		"fire_rate", "shoot_rate", "attack_speed":
			return StatType.FIRE_RATE
		"attack", "damage":
			return StatType.ATTACK
		"move_speed", "speed", "movement_speed":
			return StatType.MOVE_SPEED
		"max_health", "health", "hearts":
			return StatType.MAX_HEALTH
		_:
			return StatType.FIRE_RATE  # Default fallback

func get_stat_name(stat_type: StatType) -> String:
	"""Get the display name for a stat type."""
	return STAT_NAMES.get(stat_type, "Unknown")

func print_all_stats():
	"""Print all current stat values to console for debugging."""
	print("\n📊 PLAYER STATS:")
	for stat_type in StatType.values():
		var stat_name = get_stat_name(stat_type)
		var base_value = get_base_stat_value(stat_type)
		var additive = additive_modifiers.get(stat_type, 0.0)
		var multiplicative = multiplicative_modifiers.get(stat_type, 1.0)
		var final_value = get_stat_value(stat_type)
		
		print("  ", stat_name, ": ", final_value, " (base: ", base_value, ", +", additive, ", x", multiplicative, ")")
	print()
