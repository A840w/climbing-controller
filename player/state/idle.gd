extends LimboState
@export var player: Player
@export var movement: MovementComponent

func _enter() -> void:
 	# agent refers to the node passed during hsm.initialize(self)
	player.velocity.x = 0.0
	player.velocity.z = 0.0

func _update(delta: float) -> void:
	if not player.is_on_floor():
		dispatch(&"in_air")
		return

	if player.move_dir != Vector3.ZERO:
		dispatch(&"start_moving")
		return
	
	if Input.is_action_pressed("sprint"):
		dispatch(&"start_sprinting")
		return


	if Input.is_action_just_pressed("jump"):
		movement.execute_jump()
		dispatch(&"in_air")
		return
