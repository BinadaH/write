extends Node2D

@onready var main = get_parent()

var GRID_COL = Color("505050ff")
var GRID_WEIGHT = 4
var BACK_COL = Color("#333231")
var SQUARE_SIZE = 100

func _ready():
	RenderingServer.set_default_clear_color(BACK_COL)

var draw_grid = true
func _draw() -> void:
	var cam_pos = main.cam.cam.position
	
	var screen_size = get_viewport_rect().size
	
	var first_off_x = floor((cam_pos.x - screen_size.x / 2 / main.cam.zoom) / SQUARE_SIZE)
	var first_off_y = floor((cam_pos.y - screen_size.y / 2 / main.cam.zoom) / SQUARE_SIZE)

	var n_x = round(screen_size.x / SQUARE_SIZE / main.cam.zoom) + 2
	var n_y = round(screen_size.y / SQUARE_SIZE / main.cam.zoom) + 2
	
	if draw_grid:
		for x in n_x:
			var b_pos = Vector2((first_off_x + x) * SQUARE_SIZE, cam_pos.y - screen_size.y / 2 / main.cam.zoom)
			var e_pos = Vector2((first_off_x + x) * SQUARE_SIZE, cam_pos.y + screen_size.y / 2 / main.cam.zoom)
			draw_line(b_pos, e_pos, GRID_COL, GRID_WEIGHT)
		
		
		for y in n_y:
			var b_pos = Vector2(cam_pos.x - screen_size.x / main.cam.zoom / 2, (first_off_y + y) * SQUARE_SIZE)
			var e_pos = Vector2(cam_pos.x + screen_size.x / main.cam.zoom / 2, (first_off_y + y) * SQUARE_SIZE)
			draw_line(b_pos, e_pos, GRID_COL, GRID_WEIGHT)
	else:
		#test_new back
		for x in n_x:
			for y in n_y:
				var c_x = (first_off_x + x) * SQUARE_SIZE
				var c_y = (first_off_y + y) * SQUARE_SIZE
				draw_circle(Vector2(c_x, c_y), GRID_WEIGHT * 5 / main.cam.cam.zoom.x, GRID_COL)
	

func get_grid_pos(world_pos, fac = 1) -> Vector2:
	var x = round(world_pos.x / (SQUARE_SIZE * fac)) * (SQUARE_SIZE * fac)
	var y = round(world_pos.y / (SQUARE_SIZE * fac)) * (SQUARE_SIZE * fac)
	return Vector2(x, y)
