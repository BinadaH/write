extends Node


@onready var main = get_parent()

var data_to_save = {
		"lines": []
}
func _on_save_btn_pressed() -> void:
	for child in main.canvas.get_children():
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
	
	
	main.open_file.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	main.open_file.visible = true
	data_to_save = JSON.stringify(data_to_save)

	



func _on_open_file_file_selected(path: String) -> void:
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
				var c = Vector2(int(x), int(y))
				l_d.add_point(c)
				
			var dx = float(1)/l["points"].size()
			var d = 0
			for p in l["press"]:
				l_d.width_curve.add_point(Vector2(dx * d, p))
				d += 1
