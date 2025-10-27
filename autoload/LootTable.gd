extends Node

## Autoload singleton that manages the loot table and generates random item choices.
## Provides weighted random selection and ensures no duplicate items in single generation.

# =============================================================================
# LOOT TABLE DATA
# =============================================================================

## Complete array of all available loot items
var loot_items: Array = []

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready():
	"""Initialize the loot table with predefined items."""
	_load_items_from_disk()

# =============================================================================
# LOOT GENERATION
# =============================================================================

func generate_loot_choices(count: int, player_level: int = 1) -> Array:
	"""
	Generate a specified number of unique loot choices using weighted random selection.
	Ensures no duplicate items unless they are stackable.
	
	Args:
		count: Number of loot choices to generate
		player_level: Current player level (affects rarity weighting)
		
	Returns:
		Array of LootItem resources
	"""
	var choices: Array = []
	var available_items = loot_items.duplicate()
	
	# Calculate level-aware effective weights for each item
	var weighted_items = []
	for item in available_items:
		var effective_weight = _calculate_level_aware_weight(item, player_level)
		weighted_items.append({"item": item, "weight": effective_weight})
	
	for i in range(count):
		if weighted_items.is_empty():
			break
		
		# Select item using level-aware weighted random
		var selected_data = _weighted_random_select_items(weighted_items)
		var selected_item = selected_data["item"]
		choices.append(selected_item)
		
		# Remove non-stackable items from available pool
		if not selected_item.stackable:
			var index = 0
			while index < weighted_items.size():
				if weighted_items[index]["item"] == selected_item:
					weighted_items.remove_at(index)
					break
				index += 1
	
	return choices

func _weighted_random_select_items(weighted_items: Array):
	"""
	Select a random item from a weighted array structure.
	
	Args:
		weighted_items: Array of dictionaries with "item" and "weight" keys
		
	Returns:
		Dictionary containing the selected item
	"""
	if weighted_items.is_empty():
		return null
	
	# Calculate total weight
	var total_weight: float = 0.0
	for item_data in weighted_items:
		total_weight += item_data["weight"]
	
	# Generate random number
	var random_value = randf() * total_weight

	# Find the selected item
	var current_weight: float = 0.0
	for item_data in weighted_items:
		current_weight += item_data["weight"]
		if random_value <= current_weight:
			return item_data
	
	# Fallback (should never reach here)
	return weighted_items[0]

func _calculate_level_aware_weight(item: LootItem, player_level: int) -> float:
	"""
	Calculate effective weight for an item based on its rarity and player level.
	
	The weight determines how likely an item is to be selected during loot generation.
	Rarity scaling makes higher-tier items exponentially rarer, while level scaling
	allows rare items to become more common as the player progresses.
	
	Args:
		item: The LootItem to calculate weight for
		player_level: Current player level
		
	Returns:
		Effective weight for random selection
	"""
	var base_weight = item.weight
	var rarity = item.rarity
	
	# Rarity scaling: each tier is 4x rarer than the previous
	# Common=1.0, Uncommon=0.25, Rare=0.0625, Epic=0.0156, Legendary=0.0039
	var rarity_scaling = pow(0.25, rarity)
	
	# Level scaling: adjusts weights based on player progression
	# Factor increases by 5% per level, creating a gradual progression curve
	var level_factor = 1.0 + (player_level - 1) * 0.05
	
	# Apply level-based adjustments differently by rarity tier
	# Lower rarities get penalties at higher levels, higher rarities get bonuses
	var level_scaling = 1.0
	if rarity <= 1:
		# Common/Uncommon items become less likely as player levels up
		level_scaling = pow(1.0 / level_factor, 0.3)
	elif rarity >= 3:
		# Epic/Legendary items become more likely as player levels up
		level_scaling = pow(level_factor, (rarity - 2) * 0.6)
	
	var effective_weight = base_weight * rarity_scaling * level_scaling
	
	# Epic/Legendary items have zero weight below level 3
	# This ensures these powerful items only appear after some progression
	if rarity >= 3 and player_level < 3:
		effective_weight = 0.0
	
	return effective_weight

# =============================================================================
# UTILITY METHODS
# =============================================================================

func get_item_by_name(item_name: String):
	"""Get a loot item by its name."""
	for item in loot_items:
		if item.item_name == item_name:
			return item
	return null

func get_items_by_type(type: String) -> Array:
	"""Get all items of a specific type."""
	var filtered_items: Array = []
	for item in loot_items:
		if item.item_type == type:
			filtered_items.append(item)
	return filtered_items

func _load_items_from_disk():
	"""Automatically load all .tres item files from the items directory and subdirectories."""
	var items_dir = "res://items/"
	
	# Check if the items directory exists
	if not DirAccess.dir_exists_absolute(items_dir):
		print("Items directory not found: ", items_dir)
		return
	
	# Recursively load items from root and subdirectories
	_load_items_recursive(items_dir)
	
	print("Total items loaded from disk: ", loot_items.size())

func _load_items_recursive(dir_path: String):
	"""Recursively load all .tres files from directory and subdirectories."""
	var dir = DirAccess.open(dir_path)
	if not dir:
		print("Could not open directory: ", dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir_path + file_name
		
		# If it's a directory, recurse into it
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_load_items_recursive(full_path + "/")
		# If it's a .tres file, load it
		elif file_name.ends_with(".tres"):
			var item_resource = load(full_path)
			
			# Verify it's a LootItem
			if item_resource and item_resource is LootItem:
				loot_items.append(item_resource)
				print("Loaded item: ", item_resource.item_name, " (Rarity ", item_resource.rarity, ") from ", file_name)
			else:
				print("Warning: ", file_name, " is not a valid LootItem")
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
