extends Node


@onready var main = get_parent()

var data_to_save = {
		"lines": []
}
func _on_save_btn_pressed() -> void:
	main.clear_selection_status()
	data_to_save = {
		"lines": [],
		"imgs": []
	}
	for child in main.canvas.get_children():
		if child is Line2D:
			if !child.width_curve:
				continue
			var press_points = []
			for i in child.width_curve.point_count:
				press_points.append(child.width_curve.get_point_position(i)[1])
			var points = Array(child.points)
			for p in range(points.size()):
				points[p] += child.position
			
			data_to_save["lines"].append(
				{
					"points": points,
					"press":press_points,
					"col": [
						child.default_color.r,
						child.default_color.g,
						child.default_color.b,
						child.default_color.a
					],
					"width": child.width
				}
			) 
		elif child is TextureRect:
			data_to_save["imgs"].append({
				"p": child.position,
				"t": Marshalls.raw_to_base64(child.texture.get_image().save_png_to_buffer())
			})
	
	
	main.open_file.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	main.open_file.visible = true
	data_to_save = JSON.stringify(data_to_save)

	



func _on_open_file_file_selected(path: String) -> void:
	main.clear_selection_status()
	main.wactions.clear()
	if main.open_file.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(data_to_save)
		f.close()
	else:
		main.clear_canvas()
		main.open_file.visible = false
		
		var f = FileAccess.open(path, FileAccess.READ)
		var str = f.get_as_text()
		f.close()
		
		var data = JSON.parse_string(str)
		for l in data["lines"]:
			var l_d = main.line.duplicate()
			main.canvas.add_child(l_d)
			l_d.width_curve = Curve.new()
			for p in l["points"]:
				var a = p.split(",")
				var x = a[0].trim_prefix("(")
				var y = a[1].trim_suffix(")")
				var c = Vector2(float(x), float(y))
				l_d.add_point(c)
				
			var dx = 1/float(l["points"].size())
			var d = 0
			for p in l["press"]:
				l_d.width_curve.add_point(Vector2(dx * d * l["points"].size() / l["press"].size(), p))
				d += 1
			
			l_d.default_color = Color(l["col"][0], l["col"][1], l["col"][2], l["col"][3])
			l_d.width = l["width"]
	
		if data.keys().has("imgs"):
			for img in data["imgs"]:
				var r = TextureRect.new()
				var a = img["p"].split(",")
				var x = a[0].trim_prefix("(")
				var y = a[1].trim_suffix(")")
				r.position = Vector2(float(x), float(y))
				var im = Image.new()
				var err = im.load_png_from_buffer(Marshalls.base64_to_raw(img["t"]))
				print(err)
				r.texture = ImageTexture.create_from_image(im)
				main.canvas.add_child(r)
