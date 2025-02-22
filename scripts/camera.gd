extends Node2D

var cam :Camera2D

var new_pos = Vector2()
var last_pos = Vector2()
var move = false

const cam_speed = 0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if move:
			new_pos = last_pos - event.relative
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			move = event.pressed

func _ready() -> void:
	cam = $camera

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	if Input.is_action_pressed("cam_move"):
		last_pos = lerp(last_pos, new_pos, 1)
		cam.position = last_pos
		


func _on_v_slider_value_changed(value: float) -> void:
	cam.zoom = Vector2(value, value)
