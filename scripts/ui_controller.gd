extends CanvasLayer


var mouse_pos = Vector2()

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
