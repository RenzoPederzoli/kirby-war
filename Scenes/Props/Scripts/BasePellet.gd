extends Area2D

@onready var lifespan_timer : Timer = $LifespanTimer

@export var speed: float = 300.0
@export var base_damage: int = 10  # Base damage, will be modified by player attack stat
@export var lifetime: float = 10.0  # Seconds before the pellet is freed

var velocity: Vector2
var damage: int  # Final damage after player attack stat modification

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Free the pellet after its lifetime
	lifespan_timer.timeout.connect(_on_lifetime_timeout)
	lifespan_timer.start(lifetime)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	
func fire(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	
	# Calculate final damage using player's attack stat
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_attack"):
		damage = base_damage * player.get_attack()
	else:
		damage = base_damage

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_pellet_hit"):
		body.apply_pellet_hit(self)
		queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
