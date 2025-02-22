extends Node2D


var last_pos = Vector2()
var new_pos = Vector2()
@onready var canvas = $CanvasLayer/SubViewportContainer/SubViewport/Node2D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		new_pos = event.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	canvas.queue_redraw()
	
func _on_node_2d_draw() -> void:
	canvas.draw_line(last_pos, new_pos, Color.WHITE, 1)
	last_pos = new_pos
