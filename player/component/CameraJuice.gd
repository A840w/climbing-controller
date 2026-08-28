extends Node
class_name  CameraJuiceComponent


##exports
@export_group("variables")
@export var camera_pivot : Node3D
@export var bounce_curve: Curve
@export var sway_curve: Curve
@export var bob_amplitude := 0.03
@export var sway_amplitude := 0.02
@export_group("Componenets")
@export var player : Player
@export var movement : MovementComponent
@export var camera_base_pos: Marker3D  
## variables 
var bob_amount : float =  10

var step_phase: float = 0.0
var recover_speed : float = 10.0
var bob_y
var sway_x
var base_position : Vector3 
## functions!
func _ready() -> void:
	base_position = camera_base_pos.position
	print(base_position)

func update_camera_bob(delta: float) -> void:
	var player_velocity : Vector3 = movement.player.velocity
	var flat_velocity := Vector3(player_velocity.x, 0.0, player_velocity.z)
	var current_speed : float = flat_velocity.length()


	var target_offset = Vector3.ZERO	
	var is_moving : bool = current_speed > 0.1
	if is_moving == true:
		step_phase += delta * current_speed / 6 
		step_phase = fmod(step_phase, 1.0) 

		bob_y = bounce_curve.sample(step_phase)* bob_amplitude
		sway_x = sway_curve.sample(step_phase)*sway_amplitude * bob_amount
		target_offset = Vector3(-sway_x,bob_y, 0.0)
		SignalVan.bob_value_update.emit(sway_x, bob_y)
	else:
		target_offset = Vector3.ZERO

	var target_position = base_position + target_offset

	camera_pivot.position = camera_pivot.position.lerp(
		target_position,
		delta * recover_speed
	)
	




	
