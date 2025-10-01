extends Area2D

@export var speed: float = 300.0
@export var damage: int = 10

var velocity: Vector2

func _ready() -> void:
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

func _on_body_entered(body: Node) -> void:
    if body.has_method("apply_pellet_hit"):
        body.apply_pellet_hit(self)
        queue_free()