class_name EditorData

var pos = Vector2()
var world_pos = Vector2()
var mouse_down = false

var press = 0

var ctrl_pressed = false



var mouse_rel = Vector2.ZERO
var mouse_vel = Vector2.ZERO

enum TOOLS{
	PEN,
	HAND,
	SELECT,
	LINE,
	SPACER,
	TEXT
}

var current_tool
var current_col = Color.WHITE

var main : Main

func _init(main):
	self.main = main

func handle_mouse_motion(event):
	mouse_rel = event.relative
	pos = event.position 
	world_pos = main.get_screen_to_world_pos(pos)
	
	press = max(event.pressure, 0.3)

	if current_tool == TOOLS.PEN:
		main.update_line()
	elif current_tool == TOOLS.SELECT:
		main.update_selection()
	elif current_tool == TOOLS.LINE:
		main.update_straight_line()
	elif current_tool == TOOLS.SPACER:
		main.update_spacer()

func handle_mouse_button(event):
	if event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
		if event.pressed:
			if current_tool == TOOLS.SELECT:
				main.single_click_selection()
			elif main.selection_rect:
				main.update_selection()
			
			if current_tool == TOOLS.TEXT:
				var new_tedit = TextEdit.new()
				new_tedit.size = Vector2(200, 100)
				new_tedit.position = world_pos
				main.canvas.add_child(new_tedit)
				new_tedit.grab_focus()
				
				
				var new_t_s = load("res://scenes/text.tscn")
				var new_t = new_t_s.instantiate()
				main.canvas.add_child(new_t)
				new_t.position = world_pos
				
				var set_text = func ():
					var curr_text = new_tedit.text
					if curr_text == "":
						new_t.queue_free()
					else:
						new_t.text = new_tedit.text
						new_t.render()
					new_tedit.queue_free()
				
				new_tedit.connect("focus_exited", set_text)
				
	elif event.pressed && event.button_index == MOUSE_BUTTON_RIGHT:
		if current_tool == TOOLS.SELECT:
			main.clear_selection_status()

func handle_key(event):
	if event.pressed && event.ctrl_pressed:
		if event.keycode == KEY_C:
			main.handle_copy()
		else:
			main.clear_selection_status()
			if event.keycode == KEY_Y or (event.shift_pressed && event.keycode == KEY_Z):
				main.waction_manager.redo_waction()
			elif event.keycode == KEY_Z:
				main.waction_manager.undo_waction()
			elif event.keycode == KEY_V:
				#paste
				main.handle_paste()

	if event.pressed && event.keycode == KEY_DELETE:
		main._on_del_btn_pressed()
	
	elif event.pressed && event.keycode == KEY_ESCAPE:
		if current_tool == TOOLS.SELECT:
			main.clear_selection_status()

func change_tool(tool : TOOLS, del_btn):
	main.clear_selection_status()
	if tool == TOOLS.SELECT:
		del_btn.disabled = false
	else:
		del_btn.disabled = true
		
	current_tool = tool
