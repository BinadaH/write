extends Node3D

@onready var scenes = {
	"coords": preload("res://scenes/3d_scenes/coords_3d.tscn")
}

func set_scene(scene):
	for a in $scene.get_children():
		a.queue_free()
	
	var ins = scenes[scene].instantiate()
	$scene.add_child(ins)

func set_cam_mode(mode):
	$camera/Camera3D.projection = mode
