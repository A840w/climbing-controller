extends Node
class_name  CameraJuiceComponent


##exports
@export_group("variables")
@export var camera_pivot : Node3D
@export var bounce_curve: Curve
@export var sway_curve: Curve
@export_group("Componenets")
@export var player : Player
@export var movement : MovementComponent
#@onready var player: CharacterBody3D = $'../..'
## variables 
var bob_amount : float =  10

var step_phase
var recover_speed : float = 10.0
var y_val
var x_val
var amp_refq : float = 10

## functions!


func update_camera_bob(delta: float) -> void:
	var player_velocity : Vector3 = movement.player.velocity
	var flat_velocity := Vector3(player_velocity.x, 0.0, player_velocity.z)
	var current_speed : float = flat_velocity.length()



	var target_offset = Vector3.ZERO	
	var is_moving : bool = current_speed > 0.1

	if is_moving == true:
		step_phase =+delta * current_speed * amp_refq
		step_phase = fmod(step_phase, 1.0) 

		x_val = bounce_curve.sample(step_phase) if bounce_curve else 0.0
		y_val = sway_curve.sample(step_phase) if sway_curve else 0.0
		target_offset = Vector3(x_val,y_val, 0.0)
		SignalVan.bob_value_update.emit(x_val, y_val)
	else:
		step_phase = 0.0
		target_offset = Vector3.ZERO

	camera_pivot.position = camera_pivot.position.lerp(target_offset, delta * recover_speed)



	
