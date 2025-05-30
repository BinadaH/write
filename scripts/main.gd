extends Node2D


var pos = Vector2()
var world_pos = Vector2()
var mouse_down = false
var line : Line2D
var curr_line = null
var press = 0
var current_col = Color.WHITE
var ctrl_pressed = false
@onready var current_size = $Line2D.width

var wactions = []
var wactions_redo = []
const MAX_UNDO_COUNT = 20

var mouse_rel = Vector2.ZERO
var mouse_vel = Vector2.ZERO

enum TOOLS{
	PEN,
	HAND,
	SELECT,
	LINE,
	SPACER
}

var current_tool

@onready var open_file = $CanvasGroup/open_file
@onready var color_selector = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/Panel/pen_tools/color_selector
func _ready() -> void:
	line = $Line2D
	$CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/Panel/pen_tools/pen_size.value = current_size
	current_tool = TOOLS.PEN
	current_col = Color.BLACK
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_rel = event.relative
		pos = event.position 
		world_pos = get_screen_to_world_pos(pos)
		press = max(event.pressure, 0.3)
		
		if current_tool == TOOLS.PEN:
			update_line()
		elif current_tool == TOOLS.SELECT:
			update_selection()
		elif current_tool == TOOLS.LINE:
			update_straight_line()
		elif current_tool == TOOLS.SPACER:
			update_spacer()
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = event.pressed
			if event.pressed:
				if current_tool == TOOLS.SELECT:
					single_click_selection()
				elif selection_rect:
					update_selection()
								
		elif event.pressed && event.button_index == MOUSE_BUTTON_RIGHT:
			if current_tool == TOOLS.SELECT:
				
				clear_selection_status()
				
	elif event is InputEventKey:
		if event.pressed && event.ctrl_pressed:
			if event.keycode == KEY_C:
				handle_copy()
			else:
				clear_selection_status()
				if event.keycode == KEY_Y or (event.shift_pressed && event.keycode == KEY_Z):
					redo_waction()
				elif event.keycode == KEY_Z:
					undo_waction()
				elif event.keycode == KEY_V:
					#paste
					handle_paste()
				
			
		if event.pressed && event.keycode == KEY_DELETE:
			_on_del_btn_pressed()
		
		elif event.pressed && event.keycode == KEY_ESCAPE:
			if current_tool == TOOLS.SELECT:
				clear_selection_status()


			
var curr_pres = []


func _draw():
	if selection_rect:
		draw_rect(selection_rect, background.BACK_COL.lightened(0.2), 2)
		
	#for c in selection_made:
		#var r = c._edit_get_rect()
		#draw_rect(r, Color.RED, false, 2)
	if selection_made:
		selection_made.draw(self)
		for o in selection_made.objs:
			var r = get_object_rect(o)
			draw_rect(r, Color.ALICE_BLUE, false, 1)

var spacer_to_update_set = false
var spacer_to_update = []
func update_spacer():
	if !spacer_to_update_set && mouse_down:
		for o in canvas.get_children():
			var r = get_object_rect(o)
			if r.position.y > world_pos.y:
				spacer_to_update.append(o)
				
		spacer_to_update_set = true
		if spacer_to_update.size() > 0:
			var w = WAaction.new()
			w.set_action_spacer(spacer_to_update)
			add_waction(w)
		
	if mouse_down:
		for i in spacer_to_update:
			i.position.y += mouse_rel.y / cam.zoom
	else:
		spacer_to_update.clear()
		spacer_to_update_set = false
				

var selection_rect
var selection_made : ShapeBounds
var selection_waction : WAaction
func update_selection():
	if !selection_made:
		if mouse_down:
			if selection_rect:
				selection_rect.end = world_pos
			else:
				selection_rect = Rect2()
				selection_rect.position = world_pos
		else:
			if selection_rect:
				var new_rect = null
				var objs = []
				var selection_waction = WAaction.new()
				for c in canvas.get_children():
					var r = get_object_rect(c)
					if selection_rect.abs().encloses(r):
						new_rect = new_rect.merge(r) if new_rect else r
						objs.append(c)
						
				if new_rect && new_rect.size:
					selection_made = ShapeBounds.new(new_rect)
					selection_made.set_objs(objs)
					selection_waction.set_action_reset_scale(objs)
					wactions.push_front(selection_waction)
				
			selection_rect = null
	else:
		if mouse_down:
			if !selection_made.handle_selected:
				if selection_made.is_cursor_inside(world_pos):
					selection_made.move(mouse_rel / cam.zoom)
				elif !selection_made.calc_handle(world_pos):
					clear_selection_status()
					
			else:
				selection_made.scale(mouse_rel / cam.zoom, Input.is_key_pressed(KEY_SHIFT))
		else:
			selection_made.handle_selected = false
			
	queue_redraw()

func calc_c(p0, p1, p2, p3, t):
	return 0.5 * (2 * p1 + (-p0 + p2)*t + (2*p0 - 5*p1 + 4*p2 - p3)* t * t + (-p0 + 3*p1 - 3* p2 + p3)* t* t* t)

var A = 0.5
func calc_t(p0, p1):
	return pow((p0 - p1).length(), A)

var dt = 0
var curr_points = []

const velocity_factor = 10
func exponential_moving_average(points, alpha=0.9):
	var smoothed_points = []
	smoothed_points.append(points[0])  # Initialize with the first point
	
	for i in range(1, len(points)):
		# Get the previous smoothed point
		var prev_smoothed = smoothed_points[-1]
		
		# Calculate the smoothed x and y values
		var smoothed_x = alpha * points[i].x + (1 - alpha) * prev_smoothed.x
		var smoothed_y = alpha * points[i].y + (1 - alpha) * prev_smoothed.y
		
		# Create a new Point object with the smoothed coordinates
		smoothed_points.append(Vector2(smoothed_x, smoothed_y))
	
	return smoothed_points
	
	
var curr_straight_line = null
var p1 = Vector2()
var p2 = Vector2()
func update_straight_line():
	if !curr_straight_line:
		if mouse_down:
			curr_straight_line = $Line2D.duplicate()
			curr_straight_line.width_curve = Curve.new()
			curr_straight_line.width_curve.add_point(Vector2(0, current_size))
			curr_straight_line.width_curve.add_point(Vector2(1, current_size))
			curr_straight_line.default_color = current_col
			canvas.add_child(curr_straight_line)
			p1 = world_pos
			
			var wac = WAaction.new()
			wac.set_action_add_line(curr_straight_line, canvas)
			add_waction(wac)
	else:
		if mouse_down:
			p2 = world_pos
			curr_straight_line.points = [p1, p2]
		else:
			curr_straight_line = null
	
func update_line():
	if mouse_down:
			#if curr_line.points.size() == 0 || (curr_line.points[curr_line.points.size()- 1] - world_pos).length() > 5 / cam.zoom:
		if curr_line:
			curr_line.width_curve = Curve.new()
			curr_points.append(world_pos)
			curr_pres.append(press)
			
			
			var smoothed_pressures = []
			var alpha = 0.1  # Smoothing factor for EMA
			
			for i in range(curr_pres.size()):
				if i == 0:
					smoothed_pressures.append(curr_pres[i])
				else:
					smoothed_pressures.append(smoothed_pressures[i - 1] * (1 - alpha) + curr_pres[i] * alpha)

			var dx = 1 / float(curr_line.points.size())

			for i in smoothed_pressures.size():
				var pdx = (i * curr_line.points.size() / smoothed_pressures.size()) * dx
				var ppres = smoothed_pressures[i]
				
				curr_line.width_curve.add_point(Vector2(pdx, ppres))
			
				
			
			var draw_points = exponential_moving_average(curr_points, 0.25)
			
			var arr = PackedVector2Array(draw_points)
			if Input.is_action_pressed("ui_left"):
				curr_line.points = curr_points
			else:
				curr_line.points = arr
			
			#curr_line.width_curve.add_point(Vector2(curr_line.points.size() * dx, press))
			
		else:
			

			
			curr_line = line.duplicate()
			curr_line.default_color = current_col
			curr_line.width = current_size 
			canvas.add_child(curr_line)
			var wac = WAaction.new()
			wac.set_action_add_line(curr_line, canvas)
			add_waction(wac)
			
	else:
		if curr_line:
			var x =  curr_points.size() % 4
			print(x)
			while x > 0:
				curr_line.add_point(curr_points[curr_points.size() - x])
				x -= 1
			curr_line = null
			curr_pres = []
			curr_points = []


func add_waction(waction : WAaction):
	if wactions.size() > MAX_UNDO_COUNT:
		wactions.resize(MAX_UNDO_COUNT - 1)
	wactions.push_front(waction)
	for w in wactions_redo:
		w.clear_data()
	wactions_redo.clear()

func _process(delta: float) -> void:
	$CanvasGroup/Label.text = str(delta)
	background.queue_redraw()
	dt += delta
	
	$CanvasGroup/MarginContainer/VBoxContainer/cam_zoom.value = cam.zoom
	ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
	
	#print(get_viewport_rect().size / 2.0 / cam.zoom)
	
@onready var background = $background
@onready var canvas = $canvas
@onready var cam = $camera

func get_screen_to_world_pos(mouse_pos : Vector2) -> Vector2:
	var cam_pos = cam.cam.position
	var screen_size = get_viewport_rect().size
	var world_pos = cam_pos + (mouse_pos - screen_size / 2) / cam.zoom#mouse_pos / cam.zoom + (cam_pos - screen_size / cam.zoom / 2 )
	
	return world_pos

func clear_canvas():
	for c in canvas.get_children():
		c.queue_free()
	
	
func clear_selection_status():
	selection_made = null
	selection_rect = null
	queue_redraw()


func change_tool(tool : TOOLS):
	clear_selection_status()
		
	if tool == TOOLS.SELECT:
		$CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/GridContainer/del_btn.disabled = false
	else:
		$CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/GridContainer/del_btn.disabled = true
		
	current_tool = tool

var last_cont_btns = null
func _on_pen_btn_pressed():
	change_tool(TOOLS.PEN)
	
func _on_hand_btn_pressed():
	change_tool(TOOLS.HAND)

func _on_select_btn_pressed():
	change_tool(TOOLS.SELECT)
	
func _on_color_picker_button_color_changed(color):
	current_col = color

func _on_del_btn_pressed():
	if selection_made:
		for c in selection_made.objs:
			canvas.remove_child(c)
		var wac = WAaction.new()
		wac.set_action_delete_obj(selection_made.objs, canvas)
		add_waction(wac)
			
		selection_made = null
		queue_redraw()


func _on_h_slider_value_changed(value):
	current_size = value


func _on_file_index_pressed(index):
	if index == 0:
		$file_manager._on_save_btn_pressed()
	elif index == 1:
		$CanvasGroup._on_open_btn_pressed()
	elif index == 2:
		$CanvasGroup._on_new_btn_pressed()


func _on_line_btn_pressed():
	change_tool(TOOLS.LINE)

func undo_waction():
	#undo
	var wa = wactions.pop_front()
	if wa:
		wa.undo()
		wactions_redo.push_front(wa)

func redo_waction():
	#redo
	var wa = wactions_redo.pop_front()
	if wa:
		wa.redo()
		wactions.push_front(wa)
		
func get_object_rect(obj) -> Rect2:
	var r = obj._edit_get_rect()
	r.position += obj.position
	return r

func get_objects_rect(objs : Array) -> Rect2:
	var new_rect = null
	for o in objs:
		var r = get_object_rect(o)
		new_rect = r.merge(new_rect) if new_rect else r
		
	return new_rect
	
var copied_pos = Vector2()
var copied_items = []
func handle_copy():
	if selection_made:
		copied_items = selection_made.objs.duplicate()
		DisplayServer.clipboard_set("")
		copied_pos = selection_made.points[0]
	print(copied_items)

func handle_paste(on_mouse = true):
	var wac = WAaction.new()
	if DisplayServer.clipboard_has_image():
		var img = DisplayServer.clipboard_get_image()
		var tex = ImageTexture.create_from_image(img)
		var s = TextureRect.new()
		s.expand_mode = s.EXPAND_IGNORE_SIZE
		s.size = tex.get_size()
		s.z_index = -1
		s.texture = tex
		s.position = world_pos if on_mouse else (cam.cam.position - s.size / 2)
		canvas.add_child(s)
		wac.set_action_paste([s], canvas)
	elif copied_items.size() > 0:
		var new_data = []
		for c in copied_items:
			var cd = c.duplicate()
			canvas.add_child(cd)
			new_data.append(cd)
		var r = get_objects_rect(new_data)
		selection_made = ShapeBounds.new(r)
		selection_made.set_objs(new_data)
		selection_made.move((world_pos if on_mouse else (cam.cam.position - r.size / 2)) - copied_pos)
		queue_redraw()
		wac.set_action_paste(new_data, canvas)
	add_waction(wac)

func single_click_selection():
	for child in canvas.get_children():
		var new_rect = get_object_rect(child)
		if new_rect.has_point(world_pos):
			if selection_made && selection_made.objs.has(child):
				print(selection_made.objs)
				continue
			var selection_waction = WAaction.new()
			#selection_rect = new_rect
			if selection_made && ctrl_pressed:
				selection_made.merge(new_rect)
				selection_made.objs.append(child)
				selection_waction.set_action_reset_scale(selection_made.objs)
			else:
				selection_made = ShapeBounds.new(new_rect)
				selection_made.set_objs([child])
				selection_waction.set_action_reset_scale([child])
				
			wactions.push_front(selection_waction)
			update_selection()
			break
