extends Control
class_name PlayerStatsDisplay

## UI component for displaying player stats (max health, attack damage, move speed, fire rate).
## Shows current stat values and updates automatically when stats change.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var health_label: Label = $VBoxContainer/HealthContainer/HealthValue
@onready var attack_label: Label = $VBoxContainer/AttackContainer/AttackValue
@onready var move_speed_label: Label = $VBoxContainer/MoveSpeedContainer/MoveSpeedValue
@onready var fire_rate_label: Label = $VBoxContainer/FireRateContainer/FireRateValue

# =============================================================================
# RUNTIME STATE
# =============================================================================

var player_stats_system: PlayerStats

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready():
	"""Initialize the stats display."""
	pass

func setup(stats_system: PlayerStats):
	"""Connect to the player's stats system."""
	player_stats_system = stats_system
	
	# Connect to stats system signal
	player_stats_system.stat_changed.connect(_on_stat_changed)
	
	# Initialize display with current values
	_update_all_stats()

# =============================================================================
# DISPLAY UPDATES
# =============================================================================

func _update_all_stats():
	"""Update all stat displays with current values from the stats system."""
	if not player_stats_system:
		return
	
	# Update each stat display
	_update_stat_display(PlayerStats.StatType.MAX_HEALTH)
	_update_stat_display(PlayerStats.StatType.ATTACK)
	_update_stat_display(PlayerStats.StatType.MOVE_SPEED)
	_update_stat_display(PlayerStats.StatType.FIRE_RATE)

func _update_stat_display(stat_type: PlayerStats.StatType):
	"""Update the display for a specific stat."""
	if not player_stats_system:
		return
	
	var value = player_stats_system.get_stat_value(stat_type)
	var formatted_value: String
	
	# Format value based on stat type
	match stat_type:
		PlayerStats.StatType.MAX_HEALTH:
			formatted_value = str(int(value))
		PlayerStats.StatType.ATTACK:
			formatted_value = "%.1f" % value
		PlayerStats.StatType.MOVE_SPEED:
			formatted_value = "%.1f" % value
		PlayerStats.StatType.FIRE_RATE:
			formatted_value = "%.2f" % value
	
	# Update the appropriate label
	match stat_type:
		PlayerStats.StatType.MAX_HEALTH:
			if health_label:
				health_label.text = formatted_value
		PlayerStats.StatType.ATTACK:
			if attack_label:
				attack_label.text = formatted_value
		PlayerStats.StatType.MOVE_SPEED:
			if move_speed_label:
				move_speed_label.text = formatted_value
		PlayerStats.StatType.FIRE_RATE:
			if fire_rate_label:
				fire_rate_label.text = formatted_value

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_stat_changed(stat_type: PlayerStats.StatType, _old_value: float, _new_value: float):
	"""Handle stat changes from the stats system."""
	_update_stat_display(stat_type)

