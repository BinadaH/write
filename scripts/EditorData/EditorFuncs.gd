extends Node

var main : Main
var temp_path = OS.get_user_data_dir() + "/latex_temp"

func set_main(main : Main):
	self.main = main
	if not DirAccess.dir_exists_absolute(temp_path):
		DirAccess.make_dir_absolute(temp_path)

func get_screen_to_world_pos(mouse_pos : Vector2) -> Vector2:
	return main.cam.cam.position + (mouse_pos - main.get_viewport_rect().size / 2) / main.cam.zoom 

func get_world_to_screen_pos(world_pos : Vector2) -> Vector2:
	return (world_pos - main.cam.cam.position) * main.cam.zoom + (main.get_viewport_rect().size / 2)


func parse_text_and_latex(text: String):
	var segments = []
	var regex = RegEx.new()
	regex.compile("(?s)(\\$\\$|\\$)(.*?)\\1")
	
	var last_index = 0
	var matches = regex.search_all(text)
	
	for m in matches:
		# --- GESTIONE TESTO PRIMA DEL LATEX ---
		var text_chunk = text.substr(last_index, m.get_start() - last_index)
		if text_chunk != "":
			# Dividiamo il testo per ogni \n
			var sub_parts = text_chunk.split("\n", true)
			for i in range(sub_parts.size()):
				if sub_parts[i] != "":
					segments.append({"type": "text", "content": sub_parts[i]})
				# Se non è l'ultimo elemento, qui c'era un \n
				if i < sub_parts.size() - 1:
					segments.append({"type": "newline"})
		
		# --- GESTIONE BLOCCO LATEX ---
		var tag_type = m.get_string(1)
		var content = m.get_string(2).strip_edges()
		segments.append({
			"type": "latex",
			"mode": "display" if tag_type == "$$" else "inline",
			"content": content
		})
		
		last_index = m.get_end()
	
	# --- GESTIONE TESTO RIMANENTE ---
	var final_chunk = text.substr(last_index)
	if final_chunk != "":
		var sub_parts = final_chunk.split("\n", true)
		for i in range(sub_parts.size()):
			if sub_parts[i] != "":
				segments.append({"type": "text", "content": sub_parts[i]})
			if i < sub_parts.size() - 1:
				segments.append({"type": "newline"})
				
	return segments
