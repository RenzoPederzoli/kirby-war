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

func generate_loot_choices(count: int) -> Array:
	"""
	Generate a specified number of unique loot choices using weighted random selection.
	Ensures no duplicate items unless they are stackable.
	
	Args:
		count: Number of loot choices to generate
		
	Returns:
		Array of LootItem resources
	"""
	var choices: Array = []
	var available_items = loot_items.duplicate()
	
	for i in range(count):
		if available_items.is_empty():
			break
		
		# Select item using weighted random
		var selected_item = _weighted_random_select(available_items)
		choices.append(selected_item)
		
		# Remove non-stackable items from available pool
		if not selected_item.stackable:
			available_items.erase(selected_item)
	
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
	"""Automatically load all .tres item files from the items directory."""
	var items_dir = "res://items/"
	
	# Check if the items directory exists
	if not DirAccess.dir_exists_absolute(items_dir):
		print("Items directory not found: ", items_dir)
		return
	
	# Get all files in the items directory
	var dir = DirAccess.open(items_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only load .tres files
			if file_name.ends_with(".tres"):
				var item_path = items_dir + file_name
				var item_resource = load(item_path)
				
				# Verify it's a LootItem
				if item_resource and item_resource is LootItem:
					loot_items.append(item_resource)
					print("Loaded designer item: ", item_resource.item_name, " from ", file_name)
				else:
					print("Warning: ", file_name, " is not a valid LootItem")
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		print("Total items loaded from disk: ", loot_items.size())
	else:
		print("Could not open items directory: ", items_dir)
