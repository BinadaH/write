extends Node2D

func calc_c(p0, p1, p2, p3, t):
	return 0.5 * (2 * p1 + (-p0 + p2)*t + (2*p0 - 5*p1 + 4*p2 - p3)* t * t + (-p0 + 3*p1 - 3* p2 + p3)* t* t* t)

var A = 0.5
func calc_t(p0, p1):
	return pow((p0 - p1).length(), A)


var to_draw = false
var pos = Vector2.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		pos = event.position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			to_draw = event.pressed

var curr_points = []
var curr_line : Line2D
#func _draw():
	#var points = get_children()
	#var t0 = calc_t(points, 0)
	#var t1 = calc_t(points, 1)
	#
	#var t = 0
	#var last = points[1].position
	#while t < 1:
		#var new = calc_c(points[0].position, points[1].position, points[2].position, points[3].position, t)
		#draw_line(last, new, Color.WHITE, 4)
		#last = new
		#t += 0.1

func exponential_moving_average(points, alpha=0.1):
	var smoothed_points = []
	smoothed_points.append(points[0])  # Initialize with the first point
	
	for i in range(1, len(points)):
		# Get the previous smoothed point
		var prev_smoothed = smoothed_points[-1]
		
		# Calculate the smoothed x and y values
		var smoothed_x = alpha * points[i].x + (1 - alpha) * prev_smoothed.x
		var smoothed_y = alpha * points[i].y + (1 - alpha) * prev_smoothed.y
		
		# Create a new Point object with the smoothed coordinates
		smoothed_points.append(Vector2(smoothed_x, smoothed_y))
	
	return smoothed_points
	
var dt = 0
func _process(delta):
	$Label.text = str(Performance.get_monitor(Performance.TIME_PROCESS))
	dt += delta
	if dt < 0.0025:
		return
	dt = 0
	if to_draw:
		if !curr_line:
			curr_line = $line.duplicate()
			add_child(curr_line)
		
		curr_points.append(pos)
		
		var draw_points = exponential_moving_average(curr_points, 0.3)
		#for i in range(0, curr_points.size() - 4):
			#var t1 = float(calc_t(curr_points[i], curr_points[i + 1]))
			#var t2 = float(calc_t(curr_points[i + 1], curr_points[i + 2])) + t1
			#var t = t1
			#while t < t2:
				#var n_t = (t - t1)/(t2 - t1)
				#var new = calc_c(curr_points[i], curr_points[i+1], curr_points[i+2], curr_points[i+3], n_t)
				#draw_points.append(new)
				##draw_line(last, new, Color.WHITE, 4)
				#t += 0.1
			#
			
		var arr = PackedVector2Array(draw_points)
		arr.insert(0, curr_points[0])
		curr_line.points = arr
		curr_line.add_point(pos)

	else:
		curr_points = []
		curr_line = null
	
