extends Node
class_name PlayerLoot

## Handles all loot-related functionality including loot generation and item management.
## Manages the player's active item collection and generates loot choices on level up.

# =============================================================================
# RUNTIME STATE
# =============================================================================

## Array of currently active items the player has acquired
var active_items: Array = []

# =============================================================================
# NODE REFERENCES
# =============================================================================

var player: CharacterBody2D

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when loot choices are generated
signal loot_choices_generated(choices: Array)

## Emitted when an item is added to the player's collection
signal item_added(item)

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(player_node: CharacterBody2D):
	"""Initialize the loot system with a reference to the player."""
	player = player_node

func initialize():
	"""Initialize the loot system after the player is ready."""
	# Connect to the leveling system's level up signal
	if player.leveling_system:
		player.leveling_system.level_up.connect(_on_level_up)
		print("Loot system connected to leveling system")

# =============================================================================
# LOOT GENERATION
# =============================================================================

func _on_level_up(new_level: int):
	"""
	Handle level up event by generating loot choices.
	
	Args:
		new_level: The new level the player reached
	"""
	print("\n=== LEVEL UP! ===")
	print("Player reached level ", new_level)
	
	# Generate three loot choices with level-aware rarity scaling
	var loot_choices = LootTable.generate_loot_choices(3, new_level)

	# Emit signal for potential UI systems
	loot_choices_generated.emit(loot_choices)

	# Print loot choices to console with formatting
	_print_loot_choices(loot_choices)

	var picked = await UIManager.show_loot_choices(loot_choices)
	
	print("Picked: ", picked.item_name, " (Rarity ", picked.rarity, ")")
	
	# Apply the item effect to the player's stats
	player.stats_system.apply_item_effect(picked)
	
	# Add the item to the player's collection
	add_item(picked)

func _print_loot_choices(choices: Array):
	"""
	Print the loot choices to console with nice formatting.
	
	Args:
		choices: Array of LootItem resources to display
	"""
	print("\n🎁 LOOT CHOICES:")
	
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	
	for i in range(choices.size()):
		var item = choices[i]
		var choice_number = i + 1
		var stackable_text = " (Stackable)" if item.stackable else ""
		var rarity_text = " [" + rarity_names[clamp(item.rarity, 0, 4)] + "]" if item.rarity >= 0 and item.rarity <= 4 else ""
		
		print("  ", choice_number, ") ", item.item_name, stackable_text, rarity_text)
		print("     ", item.description)
		print("     Type: ", item.item_type)
		print()

# =============================================================================
# ITEM MANAGEMENT
# =============================================================================

func add_item(item):
	"""
	Add an item to the player's active collection.
	
	Args:
		item: The LootItem to add
	"""
	active_items.append(item)
	item_added.emit(item)
	print("Added item: ", item.item_name, " to player's collection")

func remove_item(item) -> bool:
	"""
	Remove an item from the player's active collection.
	
	Args:
		item: The LootItem to remove
		
	Returns:
		True if item was removed, false if not found
	"""
	var index = active_items.find(item)
	if index != -1:
		active_items.remove_at(index)
		print("Removed item: ", item.item_name, " from player's collection")
		return true
	return false

func get_active_items() -> Array:
	"""Get a copy of the player's active items."""
	return active_items.duplicate()

func get_items_by_type(type: String) -> Array:
	"""
	Get all active items of a specific type.
	
	Args:
		type: The item type to filter by
		
	Returns:
		Array of LootItem resources of the specified type
	"""
	var filtered_items: Array = []
	for item in active_items:
		if item.item_type == type:
			filtered_items.append(item)
	return filtered_items

func has_item(item_name: String) -> bool:
	"""
	Check if the player has a specific item.
	
	Args:
		item_name: Name of the item to check for
		
	Returns:
		True if the player has the item, false otherwise
	"""
	for item in active_items:
		if item.item_name == item_name:
			return true
	return false

func get_item_count(item_name: String) -> int:
	"""
	Get the count of a specific item (useful for stackable items).
	
	Args:
		item_name: Name of the item to count
		
	Returns:
		Number of instances of the item the player has
	"""
	var count = 0
	for item in active_items:
		if item.item_name == item_name:
			count += 1
	return count

# =============================================================================
# UTILITY METHODS
# =============================================================================

func print_active_items():
	"""Print all currently active items to console."""
	print("\n📦 ACTIVE ITEMS:")
	if active_items.is_empty():
		print("  No active items")
	else:
		for i in range(active_items.size()):
			var item = active_items[i]
			print("  ", i + 1, ") ", item.item_name, " - ", item.description)
	print()

func get_total_stat_modifier(stat_name: String) -> float:
	"""
	Calculate the total modifier for a specific stat from all active items.
	
	Args:
		stat_name: The stat to calculate modifiers for
		
	Returns:
		Total modifier value (can be additive or multiplicative based on item design)
	"""
	var total_modifier = 0.0
	for item in active_items:
		if item.effect_data.has("stat") and item.effect_data["stat"] == stat_name:
			if item.effect_data.has("modifier"):
				total_modifier += item.effect_data["modifier"]
	return total_modifier
