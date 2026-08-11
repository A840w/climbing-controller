extends LimboState

@export var player: Player
@export var movement : MovementComponent
func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	if not player.is_on_floor():
		dispatch(&"in_air")
		return

	# transitons
	if player.move_dir == Vector3.ZERO:
		dispatch(&"stop_moving")
		return

	if Input.is_action_pressed("sprint"):
		dispatch(&"start_sprinting")
		return

	if Input.is_action_just_pressed("jump"):
		movement.execute_jump()
		dispatch(&"in_air")
		return

	# Apply ground velocity
	movement.apply_ground_movement(player.move_dir, delta, movement.walk_speed)
	movement.apply_friction(delta)


