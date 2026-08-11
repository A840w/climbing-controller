extends LimboState

@export var player: Player
@export var movement: MovementComponent
func _update(delta: float) -> void:
	if not player.is_on_floor():
		dispatch(&"in_air")
		return

	if player.move_dir == Vector3.ZERO:
		dispatch(&"stop_moving")
		return
	
	if not Input.is_action_pressed("sprint"):
		dispatch(&"stop_sprinting")
		return

	if Input.is_action_just_pressed("jump"):
		movement.execute_jump()
		dispatch(&"in_air")
		return
	

	# Apply ground sprint velocity
	movement.apply_ground_movement(player.move_dir, delta, movement.sprint_speed)
	movement.apply_friction(delta)

	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		dispatch(&"in_air")
