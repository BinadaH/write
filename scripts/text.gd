extends MarginContainer


var text = ""
@export var min_height = 50
@export var max_height = 500
@export var curr_font_size = 20
var text_edit = null

var highlighter = CodeHighlighter.new()

func setup_highlighter():
	# Colora i blocchi LaTeX di verde
	highlighter.add_color_region("$", "$", Color.CHARTREUSE)
	highlighter.add_color_region("$$", "$$", Color.AQUAMARINE)
	
	# Colora il grassetto di giallo (per ora solo colore, il cambio font è più complesso)
	highlighter.add_color_region("**", "**", Color.YELLOW)
	
	text_edit.syntax_highlighter = highlighter

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
		setup_highlighter()
	else:
		push_error("Didn't find canvas_layer")

func render(text: String):
	if text == "":
		text_edit.queue_free()
		queue_free()
		return
	self.text = text
	var parsed_data = EditorFuncs.parse_text_and_latex(text)
	var line = HBoxContainer.new()
	for data in parsed_data:
		if data.type == "text" :
			var new_l = Label.new()
			new_l.add_theme_font_size_override("font_size", curr_font_size)
			new_l.text = data.content
			line.add_child(new_l)
		elif data.type == "latex":
			if data.mode == "inline":
				var ret : ImageTexture = GenerateLatexImg.GenerateImg(data.content, curr_font_size)
				if ret:
					var new_s = TextureRect.new()
					new_s.expand_mode = TextureRect.EXPAND_KEEP_SIZE
					new_s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					
					new_s.texture = ret
					line.add_child(new_s)
			elif data.mode == "display":
				var ret : ImageTexture = GenerateLatexImg.GenerateImg(data.content, curr_font_size * 2)
				if ret:
					var new_s = TextureRect.new()
					new_s.expand_mode = TextureRect.EXPAND_KEEP_SIZE
					new_s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					
					new_s.texture = ret
					$content.add_child(line)
					line = HBoxContainer.new()
					line.add_child(new_s)
					$content.add_child(line)
					line = HBoxContainer.new()
				
		elif data.type == "newline":
			$content.add_child(line)
			line = HBoxContainer.new()
	
	$content.add_child(line)
			
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
