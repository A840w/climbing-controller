class_name Player
extends CharacterBody3D

#region exported variables
@export var speed: float = 6.0
@export var jump_velocity: float = 4.5


@export_subgroup("Components")
@export var mouse_component: MouseComponent
@export var movement_component : MovementComponent
@export var CameraJuice : CameraJuiceComponent
@onready var state_machine: StateMachine = %StateMachine


@export_subgroup("labels")
@export var PlayerState_label: Label
@export var heading_label: Label
@export var pos_label: Label
@export var debug_val: Label
@export var camera_label : Label
#endregion

#region internal variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_dir: Vector3 = Vector3.ZERO
var current_direction: Vector3 = Vector3.FORWARD
var current_heading: String = ""
#endregion

 #region movement related functiond
func _unhandled_input(event)->void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventKey:
			if event.is_action_pressed("ui_cancel"):
				get_tree().quit()

	


func _ready() -> void:
	SignalVan.bob_value_update.connect(_on_value_update)
	Input.set_use_accumulated_input(false)
	state_machine._setup_state_machine()
	# state_machine.hsm.active_state_changed.connect(_on_active_state_changed)
	state_machine._connect_label_signal()
	state_machine._update_state_label() # Set initial text

func _input(event):
	if event.is_action_pressed("camera_fps"): # map to C+1
		SignalVan.camera_switch.emit("fps")
	elif event.is_action_pressed("camera_debug"): # map to C+2
		SignalVan.camera_switch.emit("debug")


func _process(_delta: float) -> void:

	current_direction = -global_transform.origin
	current_direction.y = 0
	current_direction = current_direction.normalized()
	update_heading_display()

func _physics_process(_delta: float) -> void:


	# Capture horizontal input relative to world/camera axes
	var input_dir := Input.get_vector("left", "right", "front", "back")
	move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#pos_label.text = str(movement_component.player.velocity)
	var vel = movement_component.player.velocity
	pos_label.text = "Velocity: (" + String.num(vel.x, 2) + ", " + String.num(vel.y, 2) + ", " + String.num(vel.z, 2) + ")"
	move_and_slide()


#endregion

#region state machine and labels

func update_heading_display() -> void:
	if current_direction.length() > 0.1:  # Avoid zero vector
		var heading = CardinalSystem.get_continuous_heading(current_direction)
		# If you have a label reference:
		heading_label.text = heading
		#print("Direction: ", current_direction, " Heading: ", heading)
	else:
		heading_label.text = "---"



func _on_value_update(sway_x, bob_y):
	debug_val.text = "X: %s, Y:%s" % [sway_x, bob_y]


# func _on_active_state_changed(current: LimboState, _previous: LimboState) -> void:
# 	# Use get_state_name() or current.name
# 	PlayerState_label.text = current.get_name()

# func _clean_name(node_name: String) -> String:
# 	return node_name.trim_suffix("HSM").trim_suffix("State").to_lower()

# func _connect_label_signal() -> void:
# 	state_machine.hsm.active_state_changed.connect(_on_state_changed)
# 	state_machine.groundedHSM.active_state_changed.connect(_on_state_changed)
# 	state_machine.airHSM.active_state_changed.connect(_on_state_changed)

# func _on_state_changed(_current: LimboState, _previous: LimboState) -> void:
# 	_update_state_label()

# func _update_state_label() -> void:
# 	## top level sub HSM
# 	var main_state : LimboState = state_machine.hsm.get_active_state()
# 	## lowest level sub HSM
# 	var leaf_state : LimboState = state_machine.hsm.get_leaf_state()

# 	var main_name : String = _clean_name(main_state.get_name()) if main_state else "None"
# 	var leaf_name : String = _clean_name(leaf_state.get_name()) if leaf_state else "None"
# 	PlayerState_label.text = "PlayerState: %s | %s" % [main_name, leaf_name]
#endregion
