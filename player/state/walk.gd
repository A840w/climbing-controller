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

	if player.move_dir == Vector3.ZERO:
		dispatch(&"stop_moving")
		return

	# Apply ground velocity
	var speed =  movement.walk_speed
	movement.apply_ground_movement(player.move_dir, delta, speed)
	movement.apply_friction(delta)

	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		dispatch(&"in_air")
