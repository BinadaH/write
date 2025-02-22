extends Node2D


var pos = Vector2()
var world_pos = Vector2()
var mouse_down = false
var line : Line2D
var curr_line = null
var press = 0

func _ready() -> void:
	line = $Line2D
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pos = event.position 
		world_pos = get_screen_to_world_pos(pos)
		press = max(event.pressure, 0.3)
		update_line()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = event.pressed

			
var curr_pres = []

var dt = 0

func update_line():
	if mouse_down:
		if curr_line:
			#if curr_line.points.size() == 0 || (curr_line.points[curr_line.points.size()- 1] - world_pos).length() > 0.5 / cam.zoom:
			curr_line.width_curve = Curve.new()
			var dx = 1 / float(curr_line.points.size()+2)
			
			for i in curr_line.points.size():
				var pdx =i * dx
				var ppres = curr_pres[i]
				
				curr_line.width_curve.add_point(Vector2(pdx, ppres))
				
			
			curr_line.add_point(world_pos)
			curr_line.width_curve.add_point(Vector2(curr_line.points.size() * dx, press))
			curr_pres.append(press)
		else:
			curr_line = line.duplicate()
			canvas.add_child(curr_line)
	else:
		curr_line = null
		curr_pres = []

func _process(delta: float) -> void:
	background.queue_redraw()
	#print(get_viewport_rect().size / 2.0 / cam.zoom)
	
@onready var background = $background
@onready var canvas = $canvas
@onready var cam = $camera


func get_screen_to_world_pos(mouse_pos : Vector2) -> Vector2:
	var cam_pos = cam.cam.position
	var screen_size = get_viewport_rect().size
	var world_pos = cam_pos + (mouse_pos - screen_size / 2) / cam.zoom#mouse_pos / cam.zoom + (cam_pos - screen_size / cam.zoom / 2 )
	
	return world_pos

var draw_grid = false
func _on_background_draw() -> void:

	
	var cam_pos = cam.cam.position
	var sq_size = 25
	var screen_size = get_viewport_rect().size
	
	var first_off_x = floor((cam_pos.x - screen_size.x / 2 / cam.zoom) / sq_size)
	var first_off_y = floor((cam_pos.y - screen_size.y / 2 / cam.zoom) / sq_size)

	var n_x = round(screen_size.x / sq_size / cam.zoom)+ 1
	var n_y = round(screen_size.y / sq_size / cam.zoom) + 1
	
	if draw_grid:
		for x in n_x:
			var b_pos = Vector2((first_off_x + x) * sq_size, cam_pos.y - screen_size.y / 2 / cam.zoom)
			var e_pos = Vector2((first_off_x + x) * sq_size, cam_pos.y + screen_size.y / 2 / cam.zoom)
			background.draw_line(b_pos, e_pos, Color.WHITE)
		
		
		for y in n_y:
			var b_pos = Vector2(cam_pos.x - screen_size.x / cam.zoom / 2, (first_off_y + y) * sq_size)
			var e_pos = Vector2(cam_pos.x + screen_size.x / cam.zoom / 2, (first_off_y + y) * sq_size)
			background.draw_line(b_pos, e_pos, Color.WHITE)
	else:
		#test_new back
		for x in n_x:
			for y in n_y:
				var c_x = (first_off_x + x) * sq_size
				var c_y = (first_off_y + y) * sq_size
				background.draw_circle(Vector2(c_x, c_y), 2, Color.WHITE)
	


var data_to_save = {
		"lines": []
	}
func _on_save_btn_pressed() -> void:
	for child in canvas.get_children():
		if child is Line2D:
			var press_points = []
			for i in child.width_curve.point_count:
				press_points.append(child.width_curve.get_point_position(i)[1])
			data_to_save["lines"].append(
				{
					"points": Array(child.points),
					"press":press_points
				}
			) 
	
	
	open_file.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	open_file.visible = true
	data_to_save = JSON.stringify(data_to_save)

	

@onready var open_file = $CanvasGroup/open_file
func _on_open_btn_pressed() -> void:
	open_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_file.visible = true
	
func _on_open_file_file_selected(path: String) -> void:
	if open_file.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(data_to_save)
		f.close()
	else:
		for c in canvas.get_children():
			c.queue_free()
			
		open_file.visible = false
		
		var f = FileAccess.open(path, FileAccess.READ)
		var str = f.get_as_text()
		f.close()
		
		var data = JSON.parse_string(str)
		for l in data["lines"]:
			var l_d = line.duplicate()
			canvas.add_child(l_d)
			l_d.width_curve = Curve.new()
			for p in l["points"]:
				var a = p.split(",")
				var x = a[0].trim_prefix("(")
				var y = a[1].trim_suffix(")")
				var c = Vector2(int(x), int(y))
				l_d.add_point(c)
				
			var dx = float(1)/l["points"].size()
			var d = 0
			for p in l["press"]:
				l_d.width_curve.add_point(Vector2(dx * d, p))
				d += 1
