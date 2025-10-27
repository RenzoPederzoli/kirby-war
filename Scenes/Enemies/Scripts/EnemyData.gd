class_name EnemyData
extends Resource

## Generic enemy configuration data for creating different enemy types.
## This allows for easy configuration of enemy behavior without code changes.

# =============================================================================
# BASIC PROPERTIES
# =============================================================================

@export var enemy_name: String = "Enemy"
@export var texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)
@export var sprite_offset: Vector2 = Vector2(0, 0)
@export var sprite_modulate: Color = Color.WHITE

# =============================================================================
# MOVEMENT CONFIGURATION
# =============================================================================

@export var movement_type: String = "bouncing"  # "bouncing", "patrol", "stationary", "following"
@export var speed: float = 100.0
@export var min_speed: float = 50.0
@export var max_speed: float = 200.0
@export var gravity_scale: float = 0.2
@export var friction: float = 0.0
@export var bounce: float = 1.0

# =============================================================================
# COMBAT CONFIGURATION
# =============================================================================

@export var max_health: int = 50
@export var contact_damage: int = 1
@export var xp_reward: int = 25
@export var vulnerable_to_bullets: bool = true
@export var vulnerable_to_jumping: bool = false

# =============================================================================
# COLLISION CONFIGURATION
# =============================================================================

@export var collision_radius: float = 8.0
@export var collision_shape: String = "circle"  # "circle" or "rectangle"
@export var touch_damage_radius: float = 9.0

# =============================================================================
# ANIMATION CONFIGURATION
# =============================================================================

@export var animation_type: String = "sphere"  # "sphere", "golem", etc.
@export var animation_speed: float = 1.0
@export var animation_loop: bool = true
