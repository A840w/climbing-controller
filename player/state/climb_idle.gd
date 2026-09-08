extends LimboState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _update(_delta: float) -> void:
	if Input.is_action_just_pressed("cancel_climb"):
		dispatch(&"stop_climbing")