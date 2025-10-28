extends Resource
class_name LootItem

## Resource class defining loot items with properties for name, description, type, and effects.
## Used by the loot table system for generating random item choices.

# =============================================================================
# ITEM PROPERTIES
# =============================================================================

## Display name of the item
@export var item_name: String

## Description of what the item does
@export var description: String

## Type of item: "stat_upgrade", "passive_ability", "active_ability"
@export var item_type: String

## Whether this item can be acquired multiple times
@export var stackable: bool = false

## Weight for weighted random selection (higher = more likely to be chosen)
@export var weight: float = 1.0

## Rarity tier (0-4, where 0 is lowest rarity)
@export var rarity: int = 0

## Sprite texture for the item icon
@export var sprite: Texture2D

## Data describing the item's effect (e.g., {"stat": "speed", "modifier": 0.1})
@export var effect_data: Dictionary

# =============================================================================
# CONSTRUCTOR
# =============================================================================

func _init(name: String = "", desc: String = "", type: String = "", can_stack: bool = false, item_weight: float = 1.0, item_rarity: int = 0, item_sprite: Texture2D = null, effect: Dictionary = {}):
	item_name = name
	description = desc
	item_type = type
	stackable = can_stack
	weight = item_weight
	rarity = item_rarity
	sprite = item_sprite
	effect_data = effect
