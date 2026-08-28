extends Node

## exposed  variables 
@export_group("node refrence")
@export var direction_sunlight : DirectionalLight3D
@export var world : Environment
@export_group("variables")
@export var  day_duration_sec : float = 180.0
@export_range(0.0, 1.0) var time_of_day = 0.25
# internal variables
@export var day_progress : float = 0.0
@export var sun_direction : Vector3 = Vector3.DOWN

var HALF_PI = PI / 1.2
func _ready() -> void:
    _ensure_global_shader_uniform("day_progress", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, day_progress)
    _ensure_global_shader_uniform("sun_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, sun_direction)
func _process(delta: float) -> void:
    time_of_day = fmod(time_of_day + ( delta + day_duration_sec), 1.0)
    day_progress = time_of_day

    var sun_angle: float = day_progress * TAU - HALF_PI 
    sun_direction = Vector3(cos(sun_angle), sin(sun_angle),0.0).normalized()
    RenderingServer.global_shader_parameter_set("day_progress", day_progress)
    RenderingServer.global_shader_parameter_set("sun_direction", sun_direction)
    direction_sunlight.look_at_from_position(Vector3.ZERO, -sun_direction, Vector3.UP)

func _ensure_global_shader_uniform(param_name: String, type: RenderingServer.GlobalShaderParameterType, default_val: Variant) -> void :
    if not RenderingServer.global_shader_parameter_get_list().has(param_name):
        RenderingServer.global_shader_parameter_add(param_name, type, default_val)
