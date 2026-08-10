extends LimboState

@export var player: Player

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	if not player.is_on_floor():
		dispatch(&"in_air")
		return

	if player.move_dir == Vector3.ZERO:
		dispatch(&"stop_moving")
		return

	# Apply ground velocity
	player.velocity.x = player.move_dir.x * player.speed
	player.velocity.z = player.move_dir.z * player.speed

	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		dispatch(&"in_air")
