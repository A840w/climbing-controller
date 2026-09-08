
extends Node3D

@export var debug_camera : Camera3D
@export var fps_camera : Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalVan.camera_switch.connect(_on_camera_switch)

func _on_camera_switch(target:String):

	match target:
		"fps":
			fps_camera.current = true
			debug_camera.current = false
		"debug":
			fps_camera.current = false
			debug_camera.current =  true
