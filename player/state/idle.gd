extends LimboState

@export var player: Player

func _enter() -> void:
	# agent refers to the node passed during hsm.initialize(self)
	player.velocity.x = 0.0
	player.velocity.z = 0.0

func _update(delta: float) -> void:
	# Check for air transition first
	if not player.is_on_floor():
		dispatch(&"in_air")
		return

	# Check for move transition
	if player.move_dir != Vector3.ZERO:
		dispatch(&"start_moving")
		return

	# Handle Jump input
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		dispatch(&"in_air")	
# func _ready() -> void:
# 	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass
