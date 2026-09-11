extends Node3D

@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -60.0 # Degrees looking down
@export var max_pitch: float = 60.0  # Degrees looking up

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        # Rotate target left/right (Y axis)
        rotate_y(-event.relative.x * mouse_sensitivity)
        
        # Pitch target up/down (X axis)
        var current_pitch = rotation_degrees.x
        var new_pitch = clamp(current_pitch - event.relative.y * mouse_sensitivity * 50, min_pitch, max_pitch)
        rotation_degrees.x = new_pitch

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)