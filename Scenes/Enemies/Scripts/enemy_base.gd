extends RigidBody2D
class_name EnemyBase

@export var max_health: int = 20
@export var contact_damage: int = 5

@export var min_spawn_speed: float = 80.0
@export var max_spawn_speed: float = 120.0     # random ±deg on bounce to vary direction

@export var min_speed: float = 75.0
@export var keepalive_jitter_deg: float = 3.0

var health: int

@onready var touch_damage: Area2D = $TouchDamage

func _ready() -> void:
    health = max_health
    if is_instance_valid(touch_damage):
        touch_damage.body_entered.connect(_on_touch_damage_body_entered);

    # Randomize initial velocity
    var angle := randf_range(0.05, PI - 0.05) # small margin to avoid perfectly horizontal
    var spawn_speed := randf_range(min_spawn_speed, max_spawn_speed)
    var dir := Vector2.RIGHT.rotated(angle)   # unit direction vector
    set_initial_velocity(dir * spawn_speed)

func _physics_process(_delta: float) -> void:
    var v := linear_velocity
    var speed := v.length()
    if speed < min_speed:
        var dir := v.normalized() if speed > 0.0 else Vector2.RIGHT.rotated(randf() * TAU)
        # small random nudge so it doesn’t stick on edges
        var jitter := deg_to_rad(randf_range(-keepalive_jitter_deg, keepalive_jitter_deg))
        linear_velocity = dir.rotated(jitter) * min_speed

func set_initial_velocity(v: Vector2) -> void:
    linear_velocity = v

# Called by your pellet (see your BasePellet.fire/impact flow)
func apply_pellet_hit(pellet: Node) -> void:
    if "damage" in pellet:
        _take_damage(pellet.damage)

func _take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    queue_free()

func _on_touch_damage_body_entered(body: Node) -> void:
    # TODO: Player contact damage; define your own API on the player
    if body.has_method("apply_enemy_contact"):
        body.apply_enemy_contact(self, contact_damage)
