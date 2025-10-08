extends Control
class_name XPBar

## UI component for displaying player level and experience progress.
## Shows current level and XP text.

# =============================================================================
# CONFIGURATION
# =============================================================================

## Color of all text elements
var text_color: Color = Color.WHITE

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var level_label: Label = $LevelLabel
@onready var xp_text: Label = $XPText

# =============================================================================
# RUNTIME STATE
# =============================================================================

var player_leveling_system: PlayerLeveling
var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 50

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready():
	"""Initialize the XP bar and connect to player leveling system."""
	_apply_colors()
	_update_display()

func setup(player_leveling: PlayerLeveling):
	"""Connect to the player's leveling system."""
	player_leveling_system = player_leveling
	
	# Connect to leveling system signals
	player_leveling_system.experience_gained.connect(_on_experience_gained)
	player_leveling_system.level_up.connect(_on_level_up)
	
	# Get initial values
	_update_from_leveling_system()

# =============================================================================
# COLOR MANAGEMENT
# =============================================================================

func _apply_colors():
	"""Apply colors to all UI elements."""
	level_label.modulate = text_color
	xp_text.modulate = text_color

# =============================================================================
# DISPLAY UPDATES
# =============================================================================

func _update_from_leveling_system():
	"""Update display values from the leveling system."""
	if not player_leveling_system:
		return
		
	current_level = player_leveling_system.get_current_level()
	current_exp = player_leveling_system.get_current_exp()
	exp_to_next_level = player_leveling_system.get_exp_to_next_level()
	
	_update_display()

func _update_display():
	"""Update all UI elements with current values."""
	# Update level label
	level_label.text = "Lv." + str(current_level)
	
	# Update XP text
	xp_text.text = str(current_exp) + "/" + str(exp_to_next_level)
	
	# Debug output
	print("XP Bar Update - Level: ", current_level, " XP: ", current_exp, "/", exp_to_next_level)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_experience_gained(_amount: int, _total_exp: int):
	"""Handle experience gained signal."""
	_update_from_leveling_system()

func _on_level_up(_new_level: int):
	"""Handle level up signal."""
	_update_from_leveling_system()
	_play_level_up_effect()

func _play_level_up_effect():
	"""Play visual effect for level up."""
	# Flash effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.YELLOW, 0.25)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
