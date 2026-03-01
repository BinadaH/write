extends Node2D
class_name Main

var draw_line_logic : DrawLine
var editor_data : EditorData
var waction_manager : WActionManager

@onready var text_size_selector = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/pen_tools/text_size
@onready var pen_size_selector = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/pen_tools/pen_size

@onready var file_manager = $file_manager

@onready var open_file = $CanvasGroup/open_file
@onready var color_selector = $CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/pen_tools/color_selector
func _ready() -> void:
	Input.set_custom_mouse_cursor(load("res://sprites/custom_cursor.png"))
	Input.use_accumulated_input = false
	
	get_tree().root.content_scale_factor = 1.2
	EditorFuncs.set_main(self)
	
	editor_data = EditorData.new(self)
	waction_manager = WActionManager.new()
	
	editor_data.current_tool = editor_data.TOOLS.PEN
	editor_data.current_col = Color.BLACK
	
	OS.low_processor_usage_mode_sleep_usec = 30000
	OS.low_processor_usage_mode = true
	
	draw_line_logic = DrawLine.new($Line2D, self, canvas)
	$CanvasGroup/HBoxContainer/tools/Panel/VBoxContainer/pen_tools/pen_size.value = draw_line_logic.current_size

	var cl = Callable(editor_data, "set_text_size")
	var text_cl = text_size_selector.get_children()
	var sizes = [
		background.SQUARE_SIZE * 2,
		background.SQUARE_SIZE,
		background.SQUARE_SIZE * 0.5
	]
	for child_i in range(text_cl.size()):
		text_cl[child_i].connect("pressed", cl.bind(sizes[child_i]))

	editor_data.curr_text_size = sizes[1]

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
	# CASO A: Non c'è ancora una selezione attiva (Siamo in modalità "Cerca/Disegna Rettangolo")
	if !selection_made:
		if editor_data.mouse_down:
			if !selection_rect:
				# Inizio del rettangolo
				selection_rect = Rect2(editor_data.world_pos, Vector2.ZERO)
			else:
				# Aggiornamento del rettangolo (usiamo .abs() per gestire trascinamenti in ogni direzione)
				var start_pos = selection_rect.position
				selection_rect = Rect2(start_pos, editor_data.world_pos - start_pos)
		else:
			# RILASCIO DEL MOUSE: Calcoliamo cosa c'è dentro
			if selection_rect and selection_rect.size.length() > 5: # Evitiamo micro-click
				_perform_area_selection()
			selection_rect = null # Reset dopo il calcolo
			
	# CASO B: La selezione esiste già (Siamo in modalità "Muovi/Scala")
	else:
		_handle_existing_selection()
	
	queue_redraw()

# --- Funzioni di supporto per pulizia ---

func _perform_area_selection():
	var found_objs = []
	var combined_rect : Rect2
	var area = selection_rect.abs()

	for child in canvas.get_children():
		var obj_rect = get_object_rect(child)
		# Usiamo intersects per rendere la selezione più naturale
		if area.intersects(obj_rect):
			found_objs.append(child)
			combined_rect = combined_rect.merge(obj_rect) if found_objs.size() > 1 else obj_rect
			
	if found_objs.size() > 0:
		selection_made = ShapeBounds.new(combined_rect)
		selection_made.set_objs(found_objs)
		
		# Registriamo l'azione per l'undo solo se abbiamo trovato qualcosa
		var sw = WAaction.new()
		sw.set_action_reset_scale(found_objs)
		waction_manager.wactions.push_front(sw)

var snap_enabled : bool = true
var drag_start_mouse_pos : Vector2 = Vector2.ZERO
var drag_start_obj_pos : Vector2 = Vector2.ZERO
func _handle_existing_selection():
	if editor_data.mouse_down:
		# --- FASE 1: Rilevamento Inizio Trascinamento ---
		if !selection_moving and !selection_made.handle_selected:
			if selection_made.calc_handle(editor_data.world_pos):
				pass
			elif selection_made.is_cursor_inside(editor_data.world_pos):
				selection_moving = true
				# Memorizziamo le posizioni iniziali "pure" (senza snap)
				drag_start_mouse_pos = editor_data.world_pos
				drag_start_obj_pos = selection_made.points[0]
			else:
				clear_selection_status()
				return

		# --- FASE 2: Esecuzione Scaling ---
		if selection_made.handle_selected:
			selection_made.scale(editor_data.mouse_rel / cam.zoom, Input.is_key_pressed(KEY_SHIFT))

		# --- FASE 3: Esecuzione Movimento (STABILE) ---
		elif selection_moving:
			# Calcoliamo quanto si è spostato il mouse in totale dall'inizio del click
			var total_mouse_delta = editor_data.world_pos - drag_start_mouse_pos
			
			# La posizione "teorica" dove dovrebbe trovarsi l'oggetto ora
			var desired_pos = drag_start_obj_pos + total_mouse_delta
			
			if snap_enabled:
				# Applichiamo lo snap alla posizione desiderata finale
				var snapped_pos = background.get_grid_pos(desired_pos)
				
				# Il movimento RELATIVO necessario è: (Posizione Snappata Finale) - (Posizione Attuale dell'oggetto)
				var current_obj_pos = selection_made.points[0]
				var snap_rel = snapped_pos - current_obj_pos
				
				if snap_rel != Vector2.ZERO:
					selection_made.move(snap_rel)
			else:
				# Movimento fluido basato sul delta del mouse (originale)
				selection_made.move(editor_data.mouse_rel / cam.zoom)
				
	else:
		# Reset totale al rilascio
		selection_moving = false
		selection_made.handle_selected = false
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

#func get_object_rect(obj) -> Rect2:
	#if obj:
		#var r = obj._edit_get_rect()
		#r.position += obj.position
		#return r
	#return Rect2()
	
func get_objects_rect(objs : Array) -> Rect2:
	var new_rect = null
	for o in objs:
		var r = get_object_rect(o)
		new_rect = r.merge(new_rect) if new_rect else r
		
	return new_rect
	
func get_object_rect(obj) -> Rect2:
	if !obj: return Rect2()
	
	var r = Rect2()
	
	if obj is Line2D:
		if obj.points.size() > 0:
			# Creiamo un rettangolo che parte dal primo punto
			r = Rect2(obj.points[0], Vector2.ZERO)
			# Espandiamo il rettangolo per includere tutti gli altri punti
			# .expand() è un metodo super ottimizzato del motore
			for p in obj.points:
				r = r.expand(p)
			
			# Aggiungiamo lo spessore della linea
			r = r.grow(obj.width / 2.0)
			# Applichiamo la posizione dell'oggetto
			r.position += obj.position
			
	elif obj is Control:
		# I nodi Control (UI) hanno già il calcolo dei bounds a runtime
		r = obj.get_global_rect()
		
	elif obj is Sprite2D:
		if obj.texture:
			var s = obj.texture.get_size() * obj.scale
			# Se lo sprite è centrato (default), il rettangolo parte da -metà dimensione
			r = Rect2(-s/2, s)
			r.position += obj.position
			
	# .abs() corregge eventuali dimensioni negative (fondamentale per Rect2)
	return r.abs()
		
var copied_pos = Vector2()
var copied_items = []
func handle_copy():
	copied_items.clear()
	if selection_made && selection_made.objs.size() > 0:
		for obj in selection_made.objs:
			var dupli = obj.duplicate()
			if dupli.is_in_group("text"):
				dupli.text = obj.text
				dupli.curr_font_size = obj.curr_font_size
			copied_items.append(dupli)
			
		copied_pos = selection_made.points[0]
	DisplayServer.clipboard_set("")

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
			if cd.is_in_group("text"):
				cd.text = c.text
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
	if selection_made:
		if selection_made.calc_handle(editor_data.world_pos):
			return
		if !selection_made.is_cursor_inside(editor_data.world_pos) && !editor_data.ctrl_pressed:
			clear_selection_status()
	
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
