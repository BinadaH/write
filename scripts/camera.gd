extends Node2D

var cam :Camera2D


var m_rel = Vector2()
var new_pos = Vector2()
var last_pos = Vector2()
var move = false

const cam_speed = 0
var zoom = 1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass
		#print(new_pos)
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			move = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = min(4, zoom + 0.1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = max(1, zoom - 0.1)
		
			
func _ready() -> void:
	cam = $camera
	zoom = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.

@onready var main = get_parent()
func _process(delta: float) -> void:
	m_rel = main.pos - last_pos
	if Input.is_action_pressed("cam_move") || (main.current_tool == main.TOOLS.HAND && main.mouse_down):
		cam.position -= m_rel / zoom

	last_pos = main.pos
	
	cam.zoom = Vector2(zoom, zoom)
	
func _on_v_slider_value_changed(value: float) -> void:
	zoom = max(1, min(4, value))
	
