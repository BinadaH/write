extends Node2D


var pos = Vector2()
var world_pos = Vector2()
var mouse_down = false
var line : Line2D
var curr_line = null
var press = 0
var current_col = Color.WHITE

var wactions = []
const MAX_UNDO_COUNT = 20


enum TOOLS{
	PEN,
	HAND,
	SELECT
}

var current_tool

@onready var open_file = $CanvasGroup/open_file

func _ready() -> void:
	line = $Line2D
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
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
		draw_rect(selection_rect, Color.ANTIQUE_WHITE, false, 2)
	
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
			
			var wac = WAaction.new()
			wac.set_action_add_line(curr_line)
			
			if wactions.size() > MAX_UNDO_COUNT:
				wactions.resize(MAX_UNDO_COUNT - 1)
			wactions.push_front(wac)
			
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
		c.queue_free()
	selection_made.clear()
	queue_redraw()
