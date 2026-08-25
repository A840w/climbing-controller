extends Node
class_name MovementComponent

@export var player: Player
@export_group("Movement Settings")
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var acceleration: float = 12.0
@export var friction: float = 16.0
@export_group("Jump Settings")
@export var jump_velocity: float = 4.5
@export var air_control: float = 0.5

# internal variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func apply_gravity(delta: float) -> void:
    if not player.is_on_floor():
        player.velocity.y -= gravity * delta

func apply_ground_movement(input_dir: Vector3, delta: float , speed : float = walk_speed) -> void:
    var target_velocity = input_dir * speed
    
    player.velocity.x = lerp(player.velocity.x, target_velocity.x, acceleration * delta)
    player.velocity.z = lerp(player.velocity.z, target_velocity.z, acceleration * delta)

    

func apply_friction(delta: float) -> void:
    player.velocity.x = move_toward(player.velocity.x, 0.0, friction * delta)
    player.velocity.z = move_toward(player.velocity.z, 0.0, friction * delta)

func apply_air_movement(input_dir: Vector3, delta: float) -> void:
    var target_velocity = input_dir * walk_speed
    player.velocity.x = lerp(player.velocity.x, target_velocity.x, air_control * delta)
    player.velocity.z = lerp(player.velocity.z, target_velocity.z, air_control * delta)
    

func execute_jump() -> void:
    #if player.is_on_floor():
     player.velocity.y = jump_velocity
