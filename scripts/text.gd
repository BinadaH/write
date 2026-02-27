extends MarginContainer


var text = ""
@export var min_height = 50
@export var max_height = 500
@export var curr_font_size = 20
var text_edit = null

func _ready():
	var cl = get_tree().get_nodes_in_group("ui_canvas_group")
	if cl && cl[0]:
		text_edit = TextEdit.new()
		text_edit.add_to_group("text_edit")
		text_edit.position = position
		text_edit.custom_minimum_size = Vector2(0, 0)
		text_edit.add_theme_font_size_override("font_size", curr_font_size)
		cl[0].add_child(text_edit)
		
		text_edit.scroll_fit_content_height = true
		text_edit.scroll_fit_content_width = true
		
		text_edit.set_meta("target_text", self)
		
		text_edit.connect("focus_exited", Callable(self, "_on_text_edit_focus_exited"))
		text_edit.connect("gui_input", Callable(self, "_on_text_edit_gui_input"))
	else:
		push_error("Didn't find canvas_layer")

func render(text: String):
	if text == "":
		text_edit.queue_free()
		queue_free()
		return
		
	var parsed_data = EditorFuncs.parse_text_and_latex(text)
	
	for data in parsed_data:
		if data.type == "text" :
			var new_l = Label.new()
			new_l.add_theme_font_size_override("font_size", curr_font_size)
			new_l.text = data.content
			$content.add_child(new_l)
		elif data.type == "latex":
			pass
			
func edit_text():
	for child in $content.get_children():
		$content.remove_child(child)
	text_edit.grab_focus()
	text_edit.visible = true
	
func _on_text_edit_focus_exited():
	text_edit.visible = false
	render(text_edit.text)

func _on_text_edit_gui_input(event):
	if event is InputEventKey:
		if event.pressed && event.ctrl_pressed:
			if event.keycode == KEY_PLUS:
				curr_font_size += 5
				text_edit.add_theme_font_size_override("font_size", curr_font_size)

			elif event.keycode == KEY_MINUS:
				curr_font_size = max(10, curr_font_size - 5)
				text_edit.add_theme_font_size_override("font_size", curr_font_size)

			elif event.keycode == KEY_ENTER:
				text_edit.release_focus()
		if event.pressed && event.keycode == KEY_ESCAPE:
			text_edit.release_focus()
