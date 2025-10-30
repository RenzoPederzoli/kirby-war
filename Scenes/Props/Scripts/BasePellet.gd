extends Area2D

@export var speed: float = 300.0
@export var base_damage: int = 10  # Base damage, will be modified by player attack stat

var velocity: Vector2
var damage: int  # Final damage after player attack stat modification

func _ready() -> void:
    # Set collision mask to detect enemies on layer 4
    collision_mask = 4
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position += velocity * delta
    
    # Free the pellet if it's outside the viewport
    var viewport_size = get_viewport().get_visible_rect().size
    if position.x < -50 or position.x > viewport_size.x + 50 or \
       position.y < -50 or position.y > viewport_size.y + 50:
        queue_free()

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