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


@onready var draw_space = $HBoxContainer/draw_space
func _on_draw_space_draw() -> void:
	draw_space.draw_circle(mouse_pos - draw_space.position, 2, Color.WHITE)
