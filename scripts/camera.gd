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
			zoom = min(MAX_CAM_ZOOM, zoom + 0.1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = max(MIN_CAM_ZOOM, zoom - 0.1)
		

const MIN_CAM_ZOOM = 0.15
const MAX_CAM_ZOOM = 1
func _ready() -> void:
	cam = $camera
	zoom = 0.05

# Called every frame. 'delta' is the elapsed time since the previous frame.

@onready var main : Main = get_parent()
func _process(delta: float) -> void:
	m_rel = main.editor_data.pos - last_pos
	if Input.is_action_pressed("cam_move") || (main.editor_data.current_tool == main.editor_data.TOOLS.HAND && main.editor_data.mouse_down):
		cam.position -= m_rel / zoom

	last_pos = main.editor_data.pos
	
	cam.zoom = Vector2(zoom, zoom)
	
func _on_v_slider_value_changed(value: float) -> void:
	zoom = max(MIN_CAM_ZOOM, min(MAX_CAM_ZOOM, value))
	
