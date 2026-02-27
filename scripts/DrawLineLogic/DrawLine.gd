class_name DrawLine

var curr_line = null
var line : Line2D

var current_size = 1
var curr_points = PackedVector2Array()	
var curr_pres = PackedFloat32Array()

var smoothed_pressures = PackedFloat32Array()
var smoothed_points = PackedVector2Array()

var last_smooth_point = null
var last_smooth_pressure = null

var canvas
var main : Main
var base_line: Line2D

func _init(base_line, main, canvas):
	self.main = main
	self.canvas = canvas
	self.base_line = base_line
	self.current_size = base_line.width

func create_line():
	curr_line = base_line.duplicate()
	curr_line.default_color = main.editor_data.current_col
	curr_line.width = current_size
	curr_line.width_curve = Curve.new()
	canvas.add_child(curr_line)
	var wac = WAaction.new()
	wac.set_action_add_line(curr_line, canvas)
	main.waction_manager.add_waction(wac)
	
	curr_points.append(main.editor_data.world_pos)
	curr_pres.append(main.editor_data.press)


const MIN_DISTANCE = 1
func draw_line():
	if last_smooth_pressure:
		last_smooth_pressure = last_smooth_pressure * (0.9) + main.editor_data.press * 0.1
	else:
		last_smooth_pressure = main.editor_data.press
	
	var target_point = main.editor_data.world_pos
	if last_smooth_point:
		target_point = 0.25 * main.editor_data.world_pos + 0.75 * last_smooth_point
	else:
		target_point = main.editor_data.world_pos
	
	if smoothed_points.size() > 0:
		var last_added_point = smoothed_points[-1]
		if target_point.distance_to(last_added_point) < MIN_DISTANCE:
			return
	
	last_smooth_point = target_point
	smoothed_pressures.append(last_smooth_pressure)
	smoothed_points.append(last_smooth_point)
	curr_line.points = smoothed_points
	
func done():
	if !curr_line: return
	#var x =  curr_points.size() % 4
	#while x > 0:
		#curr_line.add_point(curr_points[curr_points.size() - x])
		#x -= 1
		
	if smoothed_points.size() == 1:
		var p = smoothed_points[0]
		smoothed_points.append(p + Vector2(0.1, 0.1)) 
		smoothed_pressures.append(smoothed_pressures[0])
		curr_line.points = smoothed_points
		

	if smoothed_points.size() > 2:
		curr_line.points = simplify_points(smoothed_points, 0.5)
		
	
	#_optimize_pressure_curve(optimized_points)
	curr_line = null
	last_smooth_point = null
	last_smooth_pressure = null
	smoothed_pressures.clear()
	smoothed_points.clear()
	curr_pres.clear()
	curr_points.clear()
	
	
func simplify_points(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() < 3:
		return points

	var dmax = 0.0
	var index = 0
	var end = points.size() - 1
	
	# Trova il punto con la distanza massima dal segmento inizio-fine
	for i in range(1, end):
		var d = _get_distance_to_segment(points[i], points[0], points[end])
		if d > dmax:
			index = i
			dmax = d

	# Se la distanza è maggiore di epsilon, dividi e conquista (ricorsione)
	if dmax > epsilon:
		var left = simplify_points(points.slice(0, index + 1), epsilon)
		var right = simplify_points(points.slice(index, points.size()), epsilon)
		# Uniamo i due pezzi evitando di duplicare il punto centrale
		left.remove_at(left.size() - 1)
		left.append_array(right)
		return left
	else:
		# Altrimenti tieni solo i due estremi
		return PackedVector2Array([points[0], points[end]])

# Helper per calcolare la distanza di un punto da una retta
func _get_distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	if a == b: return p.distance_to(a)
	var l2 = a.distance_squared_to(b)
	var t = max(0, min(1, (p - a).dot(b - a) / l2))
	var projection = a + t * (b - a)
	return p.distance_to(projection)
	
var to_update_curve_line = 0
func process():
	if to_update_curve_line >= 3:
		if curr_line && last_smooth_point:
			curr_line.width_curve.clear_points()
			var num_points = curr_line.points.size()
			var dx = 1 / float(curr_line.points.size())
			curr_line.width_curve.add_point(Vector2(0, smoothed_pressures[0]))
			var sample_interval = 10
			for i in range(1, num_points):
				if i % sample_interval == 0 or i == num_points - 1:
					curr_line.width_curve.add_point(Vector2(i * dx, smoothed_pressures[i]))
			to_update_curve_line = 0
	
	to_update_curve_line += 1
	
	

var curr_straight_line = null
func create_straight_line():
	curr_straight_line = base_line.duplicate()
	curr_straight_line.width_curve = Curve.new()
	curr_straight_line.width_curve.add_point(Vector2(0, current_size))
	curr_straight_line.width_curve.add_point(Vector2(1, current_size))
	curr_straight_line.default_color = main.editor_data.current_col
	canvas.add_child(curr_straight_line)
	p1 = main.editor_data.world_pos if !main.editor_data.ctrl_pressed else main.background.get_grid_pos(main.editor_data.world_pos, 0.5)
	var wac = WAaction.new()
	wac.set_action_add_line(curr_straight_line, canvas)
	main.waction_manager.add_waction(wac)


var p1 = Vector2()
var p2 = Vector2()
func update_straight_line():
	p2 = main.editor_data.world_pos if !main.editor_data.ctrl_pressed else main.background.get_grid_pos(main.editor_data.world_pos, 0.5)
	curr_straight_line.points = [p1, p2]

func done_straight_line():
	curr_straight_line = null
