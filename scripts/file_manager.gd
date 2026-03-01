extends Node

@onready var main : Main = get_parent()
var current_canvas_data = {}
var current_path = ""
@export var current_file_path_label : Label
@export var current_file_path_label_animations : AnimationPlayer
func _ready():
	if !current_file_path_label:
		push_error("current_file_path_label Not Set")
		
func new_file():
	if main.get_viewport().gui_get_focus_owner():
		main.get_viewport().gui_get_focus_owner().release_focus()
	current_path = ""
	current_canvas_data = {}
	current_file_path_label.text = "new file"
	

func _on_save_btn_pressed() -> void:
	main.clear_selection_status()
	
	var data = {
		"lines": [],
		"imgs": [],
		"text": []
	}

	for child in main.canvas.get_children():
		if child is Line2D and child.width_curve:
			var press_points = []
			for i in child.width_curve.point_count:
				# Corretto: prendiamo la coordinata Y del punto della curva
				press_points.append(child.width_curve.get_point_position(i).y)
			
			data["lines"].append({
				"points": child.points,     # Salvato come Array[Vector2] nativo
				"pos": child.position,
				"press": press_points,
				"col": child.default_color, # Salvato come Color nativo
				"width": child.width
			})
			
		elif child is TextureRect:
			data["imgs"].append({
				"p": child.position,
				"t": child.texture.get_image().save_png_to_buffer() # Buffer RAW, no Base64
			})
			
		elif child.is_in_group("text"):
			data["text"].append({
				"p": child.position,
				"t": child.text,
				"f": child.curr_font_size,
				"col": child.curr_color
			})

	main.open_file.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	current_canvas_data = data
	if current_path:
		save_canvas_data(current_path)
	else:
		main.open_file.visible = true

func _on_open_file_file_selected(path: String) -> void:
	if main.get_viewport().gui_get_focus_owner():
		main.get_viewport().gui_get_focus_owner().release_focus()
	current_path = path
	var file_name = path.get_file()
	var dir_name = path.get_base_dir().get_file()
	current_file_path_label.text = dir_name + "/" + file_name
	
	if main.open_file.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		save_canvas_data(path)
	else:
		_load_canvas(path)
	
func save_canvas_data(path):
	var f = FileAccess.open(path, FileAccess.WRITE)
	var success = false
	if f:
		success = f.store_var(current_canvas_data, true) # Serializzazione binaria completa
		f.close()
	if success:
		current_file_path_label_animations.play("saved_success")
	else:
		current_file_path_label_animations.play("saved_failed")
		
func _load_canvas(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.READ)
	if !f: return
	var data = f.get_var(true) # Carica il dizionario con i tipi originali
	f.close()
	
	main.clear_selection_status()
	main.clear_canvas()
	main.open_file.visible = false
	
	# Ricostruzione Linee
	for l in data.get("lines", []):
		var l_d = main.draw_line_logic.base_line.duplicate()
		main.canvas.add_child(l_d)
		l_d.position = l["pos"]
		l_d.points = l["points"] 
		l_d.default_color = l["col"]
		l_d.width = l["width"]
		
		l_d.width_curve = Curve.new()
		var p_count = l["press"].size()
		for i in range(p_count):
			var x_pos = float(i) / max(1, p_count - 1)
			l_d.width_curve.add_point(Vector2(x_pos, l["press"][i]))

	# Ricostruzione Immagini (Latex o altro)
	for img in data.get("imgs", []):
		var r = TextureRect.new()
		r.position = img["p"]
		var im = Image.new()
		im.load_png_from_buffer(img["t"])
		r.texture = ImageTexture.create_from_image(im)
		main.canvas.add_child(r)

	# Ricostruzione Testi
	var text_scene = load("res://scenes/text.tscn")
	for txt in data.get("text", []):
		var new_text = text_scene.instantiate()
		new_text.position = txt["p"]
		new_text.curr_font_size = txt["f"]
		main.canvas.add_child(new_text)
		new_text.render(txt["t"])
		if txt.has("col"):
			new_text.curr_color = txt["col"]
			new_text.modulate = new_text.curr_color
		
