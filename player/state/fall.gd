# fall_state.gd
extends LimboState

@export var player: Player

func _update(delta: float) -> void:
	# Apply gravity while falling
	player.velocity.y -= player.gravity * delta

	# Air movement / steering
	player.velocity.x = player.move_dir.x * player.speed
	player.velocity.z = player.move_dir.z * player.speed

	# Check for landing
	if player.is_on_floor():
		dispatch(&"landed") # Must match the transition event added to PlayerHSM!
