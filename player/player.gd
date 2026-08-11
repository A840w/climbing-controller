class_name Player
extends CharacterBody3D

#region exported variables
@export var speed: float = 6.0
@export var jump_velocity: float = 4.5


@export_subgroup("Components")
@export var mouse_component: MouseComponent
@onready var movement_component : MovementComponent
@onready var state_machine: StateMachine = %StateMachine

@export_subgroup("labels")
@export var PlayerState_label: Label
@export var heading_label: Label
@export var pos_label: Label
#endregion

#region internal variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_dir: Vector3 = Vector3.ZERO
#endregion

 #region movement related functiond 
func _unhandled_input(event)->void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventKey:
			if event.is_action_pressed("ui_cancel"):
				get_tree().quit()
		 
		if event is InputEventMouseButton:
			if event.button_index == 1:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		return
	
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		return
	
	if event is InputEventMouseMotion:
		mouse_component.aim_look(event)


func _ready() -> void:
	Input.set_use_accumulated_input(false)
	state_machine._setup_state_machine()
	# state_machine.hsm.active_state_changed.connect(_on_active_state_changed)
	state_machine._connect_label_signal()
	state_machine._update_state_label() # Set initial text


func _physics_process(delta: float) -> void:
	# Capture horizontal input relative to world/camera axes
	var input_dir := Input.get_vector("left", "right", "front", "back")
	move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	pos_label.text = "%.1f" % move_dir.length()
	move_and_slide()

#endregion

#region state machine and labels 

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
