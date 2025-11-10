extends Node

func _ready() -> void:
    var tex := preload("res://Scenes/ui/crosshair.png")
    Input.set_custom_mouse_cursor(
        tex,
        Input.CURSOR_ARROW,              # shape type (default arrow)
        Vector2(32, 32)  # hotspot (pivot)
    )

