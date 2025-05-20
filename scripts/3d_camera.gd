extends Node3D


var curr_dist = 1
var a_y = 0
var a_x = 0
var middle_down = false
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			curr_dist -= 0.5
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			curr_dist += 0.5
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			middle_down = event.pressed
	if event is InputEventMouseMotion:
		if middle_down:
			a_x -= event.relative.y * 0.01
			a_y -= event.relative.x * 0.01
			
func _process(delta):
	if $Camera3D.projection == Camera3D.ProjectionType.PROJECTION_ORTHOGONAL:
		$Camera3D.size = curr_dist + curr_dist
	else:
		$Camera3D.position.z = curr_dist
	rotation.y = a_y
	rotation.x = a_x
