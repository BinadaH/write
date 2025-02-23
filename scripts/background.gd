extends Node2D

@onready var main = get_parent()

var GRID_COL = Color.BLACK
var GRID_SIZE = 0.5
var BACK_COL = Color.SEASHELL


func _ready():
	RenderingServer.set_default_clear_color(BACK_COL)

var draw_grid = true
func _draw() -> void:
	var cam_pos = main.cam.cam.position
	var sq_size = 25
	var screen_size = get_viewport_rect().size
	
	var first_off_x = floor((cam_pos.x - screen_size.x / 2 / main.cam.zoom) / sq_size)
	var first_off_y = floor((cam_pos.y - screen_size.y / 2 / main.cam.zoom) / sq_size)

	var n_x = round(screen_size.x / sq_size / main.cam.zoom)+ 1
	var n_y = round(screen_size.y / sq_size / main.cam.zoom) + 1
	
	if draw_grid:
		for x in n_x:
			var b_pos = Vector2((first_off_x + x) * sq_size, cam_pos.y - screen_size.y / 2 / main.cam.zoom)
			var e_pos = Vector2((first_off_x + x) * sq_size, cam_pos.y + screen_size.y / 2 / main.cam.zoom)
			draw_line(b_pos, e_pos, GRID_COL, GRID_SIZE)
		
		
		for y in n_y:
			var b_pos = Vector2(cam_pos.x - screen_size.x / main.cam.zoom / 2, (first_off_y + y) * sq_size)
			var e_pos = Vector2(cam_pos.x + screen_size.x / main.cam.zoom / 2, (first_off_y + y) * sq_size)
			draw_line(b_pos, e_pos, GRID_COL, GRID_SIZE)
	else:
		#test_new back
		for x in n_x:
			for y in n_y:
				var c_x = (first_off_x + x) * sq_size
				var c_y = (first_off_y + y) * sq_size
				draw_circle(Vector2(c_x, c_y), GRID_SIZE, GRID_COL)
	
