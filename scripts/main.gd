extends Node2D


var pos = Vector2()
var world_pos = Vector2()
var mouse_down = false
var line : Line2D
var curr_line = null
var press = 0
var current_col = Color.WHITE
@onready var current_size = $Line2D.width

var wactions = []
const MAX_UNDO_COUNT = 20

var mouse_rel = Vector2.ZERO
var mouse_vel = Vector2.ZERO

enum TOOLS{
	PEN,
	HAND,
	SELECT
}

var current_tool

@onready var open_file = $CanvasGroup/open_file

func _ready() -> void:
	line = $Line2D
	$CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/HBoxContainer/Panel/pen_tools/pen_size.value = current_size
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
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = event.pressed
			if !event.pressed && selection_rect:
				update_selection()
		elif event.pressed && event.button_index == MOUSE_BUTTON_RIGHT:
			if current_tool == TOOLS.SELECT:
				clear_selection_status()
				
	elif event is InputEventKey:
		if event.pressed && event.ctrl_pressed && event.keycode == KEY_Z:
			var wa = wactions.pop_front()
			if wa:
				wa.undo()
		elif event.pressed && event.keycode == KEY_ESCAPE:
			if current_tool == TOOLS.SELECT:
				clear_selection_status()


			
var curr_pres = []

func _draw():
	if selection_rect:
		draw_rect(selection_rect, background.BACK_COL.darkened(0.2), 2)
	
	for c in selection_made:
		var r = c._edit_get_rect()
		draw_rect(r, Color.RED, false, 2)

var selection_rect = null
var selection_made = []
func update_selection():
	if mouse_down:
		if selection_rect:
			selection_rect.end = world_pos
		else:
			selection_rect = Rect2()
			selection_rect.position = world_pos
	else:
		if selection_rect:
			for c in canvas.get_children():
				var r = c._edit_get_rect()
				if selection_rect.abs().encloses(r):
					selection_made.append(c)
		
		selection_rect = null
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
			wac.set_action_add_line(curr_line)
			
			
			if wactions.size() > MAX_UNDO_COUNT:
				wactions.resize(MAX_UNDO_COUNT - 1)
			wactions.push_front(wac)
			
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


func _process(delta: float) -> void:
	$CanvasGroup/Label.text = str(delta)
	background.queue_redraw()
	dt += delta
	
	
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
	selection_made.clear()
	selection_rect = null


@onready var sec_tools = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/sec_tools
func change_tool(tool : TOOLS):
	if current_tool == TOOLS.SELECT:
		clear_selection_status()
		
	if tool == TOOLS.SELECT:
		sec_tools.visible = true
	else:
		sec_tools.visible = false
		
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
	for c in selection_made:
		canvas.remove_child(c)
		var wac = WAaction.new()
		wac.set_action_delete_obj(c, canvas)
		wactions.push_front(wac)
		
	selection_made.clear()
	queue_redraw()


func _on_h_slider_value_changed(value):
	current_size = value
