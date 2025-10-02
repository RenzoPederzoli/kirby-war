extends Button

var is_muted: bool = true

func _ready() -> void:
    text = "Mute"
    pressed.connect(_on_pressed)
    _apply_state()

func _on_pressed() -> void:
    is_muted = !is_muted
    _apply_state()

func _apply_state() -> void:
    var buses_to_toggle: Array[StringName] = []
    if buses_to_toggle.is_empty():
        buses_to_toggle.append(&"Master")

    for bus_name in buses_to_toggle:
        var i := AudioServer.get_bus_index(bus_name)
        AudioServer.set_bus_mute(i, is_muted)

    text = "Unmute" if is_muted else "Mute"