extends Node2D


var last_pos = Vector2()
var new_pos = Vector2()
@onready var canvas = $CanvasLayer/SubViewportContainer/SubViewport/Node2D

var c = Curve2D.new()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		new_pos = event.position
		c.add_point(new_pos)
		$Line2D.points = c.get_baked_points()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	canvas.queue_redraw()
	
func _on_node_2d_draw() -> void:
	Curve2D.new()
	canvas.draw_line(last_pos, new_pos, Color.WHITE, 1)
	last_pos = new_pos
