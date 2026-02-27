extends Node2D
class_name Main

var draw_line_logic : DrawLine
var editor_data : EditorData
var waction_manager : WActionManager

@onready var open_file = $CanvasGroup/open_file
@onready var color_selector = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/Panel/pen_tools/color_selector
func _ready() -> void:
	EditorFuncs.set_main(self)
	$CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/Panel/pen_tools/pen_size.value = 1
	
	editor_data = EditorData.new(self)
	waction_manager = WActionManager.new()
	
	editor_data.current_tool = editor_data.TOOLS.PEN
	editor_data.current_col = Color.BLACK
	
	OS.low_processor_usage_mode_sleep_usec = 30000
	OS.low_processor_usage_mode = true
	
	draw_line_logic = DrawLine.new($Line2D, self, canvas)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		editor_data.handle_mouse_motion(event)
	elif event is InputEventMouseButton:
		editor_data.handle_mouse_button(event)
	elif event is InputEventKey:
		editor_data.handle_key(event)
	
var size = 0
var sel_rect = 0
var sel_anim = 0
func _draw():
	if selection_rect:
		draw_rect(selection_rect, background.BACK_COL.lightened(0.2), 2)
		
	#for c in selection_made:
		#var r = c._edit_get_rect()
		#draw_rect(r, Color.RED, false, 2)
	if selection_made:
		selection_made.draw(self)
		if editor_data.mouse_down:
			var c = Color.ALICE_BLUE
			c.a = 0.2
			var r = selection_made.get_rect()
			sel_anim += 1
			r.grow(sin(sel_anim))
			draw_rect(r, c, true)
		else:
			sel_anim = 0
		for o in selection_made.objs:
			var r = get_object_rect(o)
			draw_rect(r, Color.ALICE_BLUE, false, 1)
	else:
		sel_anim = 0 

var spacer_to_update_set = false
var spacer_to_update = []
func update_spacer():
	if !spacer_to_update_set && editor_data.mouse_down:
		for o in canvas.get_children():
			var r = get_object_rect(o)
			if r.position.y > editor_data.world_pos.y:
				spacer_to_update.append(o)
				
		spacer_to_update_set = true
		if spacer_to_update.size() > 0:
			var w = WAaction.new()
			w.set_action_spacer(spacer_to_update)
			waction_manager.add_waction(w)
		
	if editor_data.mouse_down:
		for i in spacer_to_update:
			i.position.y += editor_data.mouse_rel.y / cam.zoom
	else:
		spacer_to_update.clear()
		spacer_to_update_set = false
				

var selection_rect
var selection_made : ShapeBounds
var selection_waction : WAaction
var selection_moving = false
func update_selection():
	if !selection_made:
		if editor_data.mouse_down:
			if selection_rect:
				selection_rect.end = editor_data.world_pos
			else:
				selection_rect = Rect2()
				selection_rect.position = editor_data.world_pos
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
					waction_manager.wactions.push_front(selection_waction)
				
			selection_rect = null
	else:
		if editor_data.mouse_down:
			if !selection_made.handle_selected:
				if selection_made.is_cursor_inside(editor_data.world_pos):
					selection_moving = true
				elif !selection_made.calc_handle(editor_data.world_pos):
					if !selection_moving:
						clear_selection_status()
			else:
				selection_made.scale(editor_data.mouse_rel / cam.zoom, Input.is_key_pressed(KEY_SHIFT))
			if selection_moving && selection_made:
				selection_made.move(editor_data.mouse_rel / cam.zoom)
		else:
			selection_made.handle_selected = false
			selection_moving = false
			
	queue_redraw()


var dt = 0


func update_straight_line():
	if !draw_line_logic.curr_straight_line:
		if editor_data.mouse_down:
			draw_line_logic.create_straight_line()
	else:
		if editor_data.mouse_down:
			draw_line_logic.update_straight_line()
		else:
			draw_line_logic.done_straight_line()
func update_line():
	if editor_data.mouse_down:
		if !draw_line_logic.curr_line:
			#creating the line on mouse down
			draw_line_logic.create_line()
		else:
			#updating the line that was previously created
			
			draw_line_logic.draw_line()
	else:
		#On mouse release, if line exists -> reset the state
		draw_line_logic.done()



var buf = []

func _process(delta: float) -> void:
	$CanvasGroup/Label.text = str(delta)
	background.queue_redraw()
	dt += delta
	
	$CanvasGroup/MarginContainer/VBoxContainer/cam_zoom.value = cam.zoom
	editor_data.ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
	var start_time_us = Time.get_ticks_usec()
	draw_line_logic.process()
	editor_data.process()
	var end_time_us = Time.get_ticks_usec()

	var not_low_processor_mode = Input.is_action_pressed("cam_move") || (editor_data.current_tool == editor_data.TOOLS.HAND && editor_data.mouse_down) || draw_line_logic.curr_line
	OS.low_processor_usage_mode = !not_low_processor_mode
	
@onready var background = $background
@onready var canvas = $canvas
@onready var cam = $camera


func clear_canvas():
	for c in canvas.get_children():
		c.queue_free()
	
func clear_selection_status():
	selection_made = null
	selection_rect = null
	queue_redraw()



var last_cont_btns = null
@onready var del_btn = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/GridContainer/del_btn
func _on_pen_btn_pressed():
	editor_data.change_tool(editor_data.TOOLS.PEN, del_btn)
	
func _on_hand_btn_pressed():
	editor_data.change_tool(editor_data.TOOLS.HAND, del_btn)

func _on_select_btn_pressed():
	editor_data.change_tool(editor_data.TOOLS.SELECT, del_btn)
	
func _on_color_picker_button_color_changed(color):
	editor_data.current_col = color

func _on_del_btn_pressed():
	if selection_made:
		for c in selection_made.objs:
			canvas.remove_child(c)
		var wac = WAaction.new()
		wac.set_action_delete_obj(selection_made.objs, canvas)
		waction_manager.add_waction(wac)
			
		selection_made = null
		queue_redraw()


func _on_h_slider_value_changed(value):
	if draw_line_logic:
		draw_line_logic.current_size = value


func _on_file_index_pressed(index):
	if index == 0:
		$file_manager._on_save_btn_pressed()
	elif index == 1:
		$CanvasGroup._on_open_btn_pressed()
	elif index == 2:
		$CanvasGroup._on_new_btn_pressed()

func _on_line_btn_pressed():
	editor_data.change_tool(editor_data.TOOLS.LINE, del_btn)


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
	#print(copied_items)

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
		s.position = editor_data.world_pos if on_mouse else (cam.cam.position - s.size / 2)
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
		selection_made.move((editor_data.world_pos if on_mouse else (cam.cam.position - r.size / 2)) - copied_pos)
		queue_redraw()
		wac.set_action_paste(new_data, canvas)
	waction_manager.add_waction(wac)

func single_click_selection():
	for child in canvas.get_children():
		var new_rect = get_object_rect(child)
		if new_rect.has_point(editor_data.world_pos):
			if selection_made && selection_made.objs.has(child):
				#print(selection_made.objs)
				continue
			var selection_waction = WAaction.new()
			#selection_rect = new_rect
			if selection_made && editor_data.ctrl_pressed:
				selection_made.merge(new_rect)
				selection_made.objs.append(child)
				selection_waction.set_action_reset_scale(selection_made.objs)
			else:
				selection_made = ShapeBounds.new(new_rect)
				selection_made.set_objs([child])
				selection_waction.set_action_reset_scale([child])
				
			waction_manager.wactions.push_front(selection_waction)
			update_selection()
			break


func _on_text_btn_pressed():
	editor_data.change_tool(editor_data.TOOLS.TEXT, del_btn)
