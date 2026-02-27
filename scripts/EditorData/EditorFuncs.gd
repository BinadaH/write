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
	# Cattura sia $$...$$ che $...$
	regex.compile("(?s)(\\$\\$|\\$)(.*?)\\1")
	
	var last_index = 0
	var matches = regex.search_all(text)
	
	for m in matches:
		# 1. Estrai il testo normale PRIMA del blocco LaTeX
		var text_before = text.substr(last_index, m.get_start() - last_index)
		if text_before != "":
			segments.append({
				"type": "text",
				"content": text_before
			})
		
		# 2. Estrai il blocco LaTeX
		var tag_type = m.get_string(1)
		var latex_content = m.get_string(2).strip_edges()
		segments.append({
			"type": "latex",
			"mode": "display" if tag_type == "$$" else "inline",
			"content": latex_content
		})
		
		# Aggiorna l'indice per il prossimo ciclo
		last_index = m.get_end()
	
	# 3. Estrai l'ultimo pezzo di testo dopo l'ultimo match
	var remaining_text = text.substr(last_index)
	if remaining_text != "":
		segments.append({
			"type": "text",
			"content": remaining_text
		})
		
	return segments
