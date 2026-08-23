extends Node
class_name MouseComponent

#exports
@export_range(1, 100, 1) var mouse_sensitivity: int = 50
@export_range(-89.0, 89.0) var min_pitch: float = -80.0
@export_range(-89.0, 89.0) var max_pitch: float = 80.0
@export var camera_pivot: Node3D
@export var player: Player

var _accumilated__motion : Vector2 = Vector2.ZERO
var _frame_motion: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			capture_mouse()
		return

	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		release_mouse()
		return
	if event is InputEventMouseMotion:
		var viewport_transfrom: Transform2D = get_tree().root.get_final_transform()
		var motion: Vector2 = event.xformed_by(viewport_transfrom).relative

		_accumilated__motion += motion
		aim_look(motion)

func _process(delta: float) -> void:
	_frame_motion = _accumilated__motion
	_accumilated__motion =Vector2.ZERO


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func aim_look(motion: Vector2) -> void:
	var degrees_per_unit: float = 0.001
	
	motion *= mouse_sensitivity
	motion *= degrees_per_unit

	#motion *= mouse_sensitivity
	#motion *= degrees_per_unit

	add_yaw(motion.x)
	add_pitch(motion.y)
	pitch_clamp()


func add_yaw(amount) -> void:
	if is_zero_approx(amount):
		return
	player.rotate_object_local(Vector3.DOWN, deg_to_rad(amount))
	player.orthonormalize()

func add_pitch(amount) -> void:
	if is_zero_approx(amount):
		return
	camera_pivot.rotate_object_local(Vector3.LEFT, deg_to_rad(amount))
	camera_pivot.orthonormalize()

func pitch_clamp() -> void:
	if camera_pivot.rotation.x > deg_to_rad(min_pitch) and camera_pivot.rotation.x < deg_to_rad(max_pitch):
		return
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	camera_pivot.orthonormalize()

func get_mouse_motion() -> Vector2:
	return _frame_motion