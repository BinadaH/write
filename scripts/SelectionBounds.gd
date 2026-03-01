class_name ShapeBounds


var points = []
const handle_r = 20
const handle_size_squared = handle_r * handle_r
var origin = Vector2()

var objs

func set_objs(obj_array):
	objs = obj_array
	
func _init(rect : Rect2):
	create_rect(rect.position, rect.end)

func add_point(point : Vector2):
	points.append(point)
	
func create_rect(p1 : Vector2, p2 : Vector2):
	points.clear()
	add_point(p1)
	add_point(p1 + Vector2(p2.x - p1.x, 0))
	add_point(p2)
	add_point(p1 + Vector2(0, p2.y - p1.y))
	
	origin = p1
	
	#for p in points:
		#origin += p
	#origin /= points.size()

var curr_handle = 0
var handle_selected = false
func calc_handle(mouse_pos : Vector2):
	for p in range(points.size()):
		if (points[p] - mouse_pos).length_squared() < handle_size_squared:
			curr_handle = p
			handle_selected = true
			origin = points[(p + 2) % 4]
			return points[p]
	return null

var r = Rect2()
func is_cursor_inside(mouse_pos : Vector2):
	r.position = points[0]
	r.end = points[2]
	return r.has_point(mouse_pos)

func get_handle():
	return points[curr_handle]

func draw(canvas : Node2D):
	#canvas.draw_primitive(points, [], [])

		
	canvas.draw_line(points[0], points[1], Color.ALICE_BLUE, 3)
	canvas.draw_line(points[1], points[2], Color.ALICE_BLUE, 3)
	canvas.draw_line(points[2], points[3], Color.ALICE_BLUE, 3)
	canvas.draw_line(points[3], points[0], Color.ALICE_BLUE, 3)
	for p in range(points.size()):
		var col = Color.SKY_BLUE if (handle_selected && p == curr_handle) else Color.ALICE_BLUE
		canvas.draw_circle(points[p], handle_r, col)
		
	#print(points)

func scale(rel : Vector2, proportional : bool):
	if handle_selected:
		var k
		if proportional:
			k = ((points[curr_handle] + rel) - origin).length() / (points[curr_handle] - origin).length()
		else:
			k = ((points[curr_handle] + rel) - origin) / (points[curr_handle] - origin)
			if is_nan(k.x) || is_inf(k.x):
				k = Vector2(1, k.y)
			if is_nan(k.y) || is_inf(k.y):
				k = Vector2(k.x, 1)
		
		var old_points = points.duplicate()
		for i in range(points.size()):
			points[i] = k * (points[i] - origin) + origin
		
		if get_rect().get_area() < 20:
			points = old_points
		else:
			for obj in objs:
				if obj is Line2D:
					for i in range(obj.points.size()):
						obj.points[i] = k * (obj.points[i] - origin) + origin
				elif obj && obj.is_in_group("text"):
					obj.curr_font_size *= k.y if !proportional else k
					obj.position = k * (obj.position - origin) + origin
					obj.render(obj.text)
				elif obj is Control:
					obj.size *= k
					#obj.size.x = max(obj.size.x, 10)
					#obj.size.y = max(obj.size.y, 10)
					
					obj.position = k * (obj.position - origin) + origin
				
					
				

func move(rel : Vector2):
	for i in points.size():
		points[i] += rel
	
	for obj in objs:
		if obj is Line2D:
			for i in range(obj.points.size()):
				obj.points[i] += rel
		elif obj is Control:
			obj.position += rel

func get_rect() -> Rect2:
	return Rect2(points[0], points[2] - points[0])

func merge(b : Rect2):
	var r = get_rect().merge(b)
	points[0] = r.position
	points[1] = Vector2(r.end.x, r.position.y)
	points[2] = r.end
	points[3] = Vector2(r.position.x, r.end.y)
	
