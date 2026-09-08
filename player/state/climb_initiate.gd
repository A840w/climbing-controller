extends LimboState
class_name ClimbInitializeState

@export var player: Player

func _enter() -> void:
	# Zero out velocity upon latching onto wall
	player.velocity = Vector3.ZERO

func _update(_delta: float) -> void:
	# In full mechanics, you'd wait for wall-snap alignment / animations here.
	# For testing, we dispatch 'init_complete' immediately on frame 1.
	dispatch(&"init_complete")
