extends CanvasLayer


var mouse_pos = Vector2()
@onready var d3 = $HBoxContainer/draw_space/edit_3d/SubViewportContainer/SubViewport/base_3d
@onready var items = $HBoxContainer/tools3d/Panel/VBoxContainer/HBoxContainer/Panel/ItemList

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = event.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	draw_space.queue_redraw()


func _on_draw_space_mouse_entered() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_draw_space_mouse_exited() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

@onready var main = get_parent()

func _on_new_btn_pressed():
	main.cam.cam.position = Vector2(0, 0)
	main.cam.zoom = 1
	main.clear_canvas()
	
@onready var open_file = $open_file
func _on_open_btn_pressed() -> void:
	open_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_file.visible = true

@onready var draw_space = $HBoxContainer/draw_space
func _on_draw_space_draw() -> void:
	draw_space.draw_circle(mouse_pos - draw_space.position, 2, main.current_col)

func _on_add_3d_pressed():
	var v = $HBoxContainer/draw_space/edit_3d/SubViewportContainer/SubViewport
	v.process_mode = Node.PROCESS_MODE_DISABLED
	var s = TextureRect.new()
	s.size.x = 100
	s.size.y = 100
	s.expand_mode = s.EXPAND_IGNORE_SIZE
	s.z_index = -1
	var img = v.get_texture().get_image()
	var img_tex = ImageTexture.create_from_image(img)
	s.texture = img_tex
	
	
	
	main.canvas.add_child(s)
	$HBoxContainer/draw_space/edit_3d.visible = false
	$HBoxContainer/tools.visible = true
	$HBoxContainer/tools3d.visible = false
	
	main.cam.process_mode = Node.PROCESS_MODE_INHERIT
	


func _on_add_3d_btn_pressed():
	var v = $HBoxContainer/draw_space/edit_3d/SubViewportContainer/SubViewport
	v.process_mode = Node.PROCESS_MODE_INHERIT
	$HBoxContainer/draw_space/edit_3d.visible = true
	$HBoxContainer/tools.visible = false
	$HBoxContainer/tools3d.visible = true
		
	main.cam.process_mode = Node.PROCESS_MODE_DISABLED
	
	
	items.clear()
	if d3 && d3.scenes:
		for s in d3.scenes.keys():
			items.add_item(s)



func _on_item_list_item_selected(index):
	d3.set_scene(items.get_item_text(index))


func _on_option_button_item_selected(index):
	d3.set_cam_mode(index)
