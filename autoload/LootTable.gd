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

func _weighted_random_select(items: Array):
	"""
	Select a random item from the array using weighted selection.
	
	Args:
		items: Array of LootItem resources
		
	Returns:
		Randomly selected LootItem based on weights
	"""
	if items.is_empty():
		return null
	
	# Calculate total weight
	var total_weight: float = 0.0
	for item in items:
		total_weight += item.weight
	
	# Generate random number
	var random_value = randf() * total_weight

    # Find the selected item
	var current_weight: float = 0.0
	for item in items:
		current_weight += item.weight
		if random_value <= current_weight:
			return item
	
	# Fallback (should never reach here)
	return items[0]

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
	
	As player levels up:
	- Common items (rarity 0-1) become LESS common
	- Rare items (rarity 2-4) become MORE common
	
	Args:
		item: The LootItem to calculate weight for
		player_level: Current player level
		
	Returns:
		Effective weight for random selection
	"""
	var base_weight = item.weight
	var rarity = item.rarity
	
	# Rarity scaling: each tier is half as likely as the previous
	var rarity_scaling = pow(0.5, rarity)
	
	# Level scaling: higher rarities benefit more from level progression
	# Formula: (1 + (level-1) * 0.15) ^ (rarity - 2)
	# This makes rarity 0-1 get penalized at higher levels
	# And rarity 2-4 get boosted at higher levels
	var level_factor = 1.0 + (player_level - 1) * 0.15
	var level_scaling = pow(level_factor, rarity - 2)
	
	var effective_weight = base_weight * rarity_scaling * level_scaling
	
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
