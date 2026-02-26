extends CanvasLayer


var mouse_pos = Vector2()
@onready var d3 = $HBoxContainer/draw_space/edit_3d/SubViewportContainer/SubViewport/base_3d
@onready var items = $HBoxContainer/tools3d/Panel/VBoxContainer/HBoxContainer/Panel/ItemList

@onready var quick_cols = $HBoxContainer/tools/Panel/VBoxContainer/quick_cols.get_children()


var color_palette = [
	Color("#E0E1CF"), #light
	Color("#EB9486"), #orange
	Color("#903A4B"), #red
	Color("#B8B8F3"), #purple
	Color("#2274A5"), #
	Color.BLACK,
]

func _ready():
	var cl = Callable(self, "change_col")
	
	var i = 0
	for ch in quick_cols:
		ch.connect("pressed", cl.bind(i))
		var s = StyleBoxFlat.new()
		s.bg_color = color_palette[i]
		var s2 : StyleBoxFlat = s.duplicate()
		s2.border_color = Color.BLACK
		s2.set_border_width_all(5)
		
		ch.add_theme_stylebox_override("normal", s)
		ch.add_theme_stylebox_override("pressed", s)
		ch.add_theme_stylebox_override("hover", s)
		#ch.add_theme_stylebox_override("focus", s)
		ch.add_theme_stylebox_override("disabled", s2)
		i += 1
		
		
var last_quick_col = 0
func change_col(index):
	quick_cols[last_quick_col].disabled = false
	quick_cols[index].disabled = true
	main.editor_data.current_col = quick_cols[index].get_theme_stylebox("normal").bg_color
	main.color_selector.color = main.editor_data.current_col 
	last_quick_col = index
	
	if main.editor_data.current_tool != main.editor_data.TOOLS.PEN and main.editor_data.current_tool != main.editor_data.TOOLS.LINE:
		main.editor_data.change_tool(main.editor_data.TOOLS.PEN, main.del_btn)
		
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = event.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	draw_space.queue_redraw()


			
func _on_draw_space_mouse_entered() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func _on_draw_space_mouse_exited() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

@onready var main : Main = get_parent()

func _on_new_btn_pressed():
	main.cam.cam.position = Vector2(0, 0)
	main.cam.zoom = 1
	main.waction_manager.wactions.clear()
	main.clear_canvas()
	
	
@onready var open_file = $open_file
func _on_open_btn_pressed() -> void:
	open_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_file.visible = true

@onready var draw_space = $HBoxContainer/draw_space
func _on_draw_space_draw() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		draw_space.draw_circle(mouse_pos - draw_space.position, 2, main.editor_data.current_col)

func _on_add_3d_pressed():
	toggle_3d()
	
	var s = TextureRect.new()
	s.size.x = 100
	s.size.y = 100
	s.expand_mode = s.EXPAND_IGNORE_SIZE
	s.z_index = -1
	
	var img = v.get_texture().get_image()
	var img_tex = ImageTexture.create_from_image(img)
	s.texture = img_tex
	s.position = main.cam.cam.position
	
	main.canvas.add_child(s)




@onready var v = $HBoxContainer/draw_space/edit_3d/SubViewportContainer/SubViewport
func _on_add_3d_btn_pressed():
	toggle_3d()
	items.clear()
	if d3 && d3.scenes:
		for s in d3.scenes.keys():
			items.add_item(s)


func toggle_3d():
	if v.process_mode == Node.PROCESS_MODE_INHERIT:
		v.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		v.process_mode = Node.PROCESS_MODE_INHERIT
		
	$HBoxContainer/draw_space/edit_3d.visible = !$HBoxContainer/draw_space/edit_3d.visible
	$HBoxContainer/tools.visible = !$HBoxContainer/tools.visible
	$HBoxContainer/tools3d.visible = !$HBoxContainer/tools3d.visible
	
	if main.cam.process_mode == Node.PROCESS_MODE_INHERIT:
		main.cam.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		main.cam.process_mode = Node.PROCESS_MODE_INHERIT

func _on_item_list_item_selected(index):
	d3.set_scene(items.get_item_text(index))


func _on_option_button_item_selected(index):
	d3.set_cam_mode(index)


func _on_file_index_pressed(index):
	pass # Replace with function body.


func _on_select_btn_2_pressed():
	pass # Replace with function body.


func _on_undo_btn_pressed():
	main.waction_manager.undo_waction()


func _on_redo_btn_pressed():
	main.waction_manager.redo_waction()

func _on_spacer_btn_pressed():
	main.editor_data.change_tool(main.editor_data.TOOLS.SPACER, main.del_btn)

func _on_copy_btn_pressed():
	main.handle_copy()

func _on_paste_btn_pressed():
	main.handle_paste(false)
