extends LimboState
@export var player: Player
@export var movement: MovementComponent

func _enter() -> void:
 	# agent refers to the node passed during hsm.initialize(self)
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.velocity = Vector3.ZERO
func _update(_delta: float) -> void:
	player.velocity = Vector3.ZERO
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
	if Input.is_action_just_pressed("climb"):
		dispatch(&"climb_initialize")
		# if player.is_on_floor():
		# 	dispatch(&"landed")
		# else:
		# 	dispatch(&"in_air")
		return
