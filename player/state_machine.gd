extends Node
class_name StateMachine

@export var player: Player
@export_group("Main HSM")
@export_subgroup("HSM")
@export  var hsm: LimboHSM
@export var groundedHSM: LimboHSM
@export var airHSM: LimboHSM
@export_subgroup("States") 
@export var idle_state: LimboState 
@export var walk_state: LimboState 
@export var fall_state: LimboState
@export var sprint_state: LimboState
@export var crouch_state: LimboState
@export var jump_state: LimboState
@export_group("Climb HSM")
@export_subgroup("HSM")
@export var CHSM: LimboHSM
@export_subgroup("States")
@export var climb_initial_state: LimboState
@export var climb_idle_state: LimboState

@export_subgroup("States")



func _setup_state_machine() -> void:
	
	## --------------------------------------------------------------------
	##                       sub-state transtions
	## --------------------------------------------------------------------

	# Grounded movement transitions
	groundedHSM.add_transition(idle_state, walk_state, &"start_moving")
	groundedHSM.add_transition(walk_state, idle_state, &"stop_moving")
	groundedHSM.add_transition(walk_state, sprint_state, &"start_sprinting")
	groundedHSM.add_transition(sprint_state, walk_state, &"stop_sprinting")
	groundedHSM.set_initial_state(idle_state)
	# Air movement transitions
	airHSM.add_transition(jump_state, fall_state, &"falling")
	#Climb movement transitions
	
	## --------------------------------------------------------------------
	##					   sub-hsm transitions
	## --------------------------------------------------------------------
	CHSM.add_transition(climb_initial_state, climb_idle_state, &"init_complete")
	CHSM.add_transition(climb_idle_state, idle_state, &"stop_climbing")
	CHSM.set_initial_state(climb_initial_state)

	## --------------------------------------------------------------------
	##					   top-level transitions
	## --------------------------------------------------------------------
	# Grounded <-> Air transitions
	hsm.add_transition(groundedHSM, airHSM, &"in_air")
	hsm.add_transition(airHSM, groundedHSM, &"landed")
	hsm.add_transition(groundedHSM, CHSM, &"climbing")
	hsm.add_transition(airHSM, CHSM, &"climbing")
	# Grounded, air <-> Climb transitions
	hsm.add_transition(groundedHSM, CHSM, &"climb_initialize")
	hsm.add_transition(airHSM,CHSM, &"climb_initialize")
	# climb <-> grounded, air transitions
	hsm.add_transition(CHSM, groundedHSM, &"landed")
	hsm.add_transition(CHSM, airHSM, &"in_air")
	# Set starting state and initialize
	hsm.set_initial_state(groundedHSM)
	hsm.initialize(self)
	hsm.set_active(true)


#region state machine and labels 
func _clean_name(node_name: String) -> String:
	return node_name.trim_suffix("HSM").trim_suffix("State").to_lower()

func _connect_label_signal() -> void:
	hsm.active_state_changed.connect(_on_state_changed)
	groundedHSM.active_state_changed.connect(_on_state_changed)
	airHSM.active_state_changed.connect(_on_state_changed)
	CHSM.active_state_changed.connect(_on_state_changed)
func _on_state_changed(_current: LimboState, _previous: LimboState) -> void:
	_update_state_label()


func _update_state_label() -> void:
	## top level sub HSM
	var main_state : LimboState = hsm.get_active_state()
	## lowest level sub HSM
	var leaf_state : LimboState = hsm.get_leaf_state()
	
	var main_name : String = _clean_name(main_state.get_name()) if main_state else "None"
	var leaf_name : String = _clean_name(leaf_state.get_name()) if leaf_state else "None"
	player.PlayerState_label.text = "%s | %s" % [main_name, leaf_name]

#endregion
