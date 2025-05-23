class_name WAaction

enum ACTION_TYPE{
	ADDLINE,
	DELETE_OBJ,
	RESET_SCALE,
}

var type
var data

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if type == ACTION_TYPE.DELETE_OBJ:
			pass
			#if data:
				#for c in data[0]:
					#if c.find_parent("canvas"):
						#data[1].remove_child(c)

func set_action_add_line(line : Line2D, parent):
	self.type = ACTION_TYPE.ADDLINE
	self.data = [line, parent]

func set_action_delete_obj(obj, parent):
	self.type = ACTION_TYPE.DELETE_OBJ
	self.data = [obj, parent]

func set_action_reset_scale(objs):
	self.type = ACTION_TYPE.RESET_SCALE
	self.data = {}
	for o in objs:
		if o is Line2D:
			self.data[o] = o.points
		elif o is Control:
			self.data[o] = [o.get_begin(), o.get_end()]



func undo():
	if type == ACTION_TYPE.ADDLINE:
		if data[0] && data[1]:
			data[1].remove_child(data[0])
	elif type == ACTION_TYPE.DELETE_OBJ:
		for c in data[0]:
			data[1].add_child(c)
	elif type == ACTION_TYPE.RESET_SCALE:
		for o in self.data.keys():
			if o is Line2D:
				var tmp = o.points
				o.points = self.data[o]
				self.data[o] = tmp
			elif o is Control:
				var tmp = [o.get_begin(), o.get_end()]
				o.set_begin(data[o][0])
				o.set_end(data[o][1])
				self.data[o] = tmp

func redo():
	if type == ACTION_TYPE.ADDLINE:
		if data[0] && data[1]:
			data[1].add_child(data[0])
	elif type == ACTION_TYPE.DELETE_OBJ:
		for c in data[0]:
			data[1].remove_child(c)
	elif type == ACTION_TYPE.RESET_SCALE:
		for o in self.data.keys():
			if o is Line2D:
				var tmp = o.points
				o.points = self.data[o]
				self.data[o] = tmp
			elif o is Control:
				var tmp = [o.get_begin(), o.get_end()]
				o.set_begin(data[o][0])
				o.set_end(data[o][1])
				self.data[o] = tmp

func clear_data():
	if type == ACTION_TYPE.ADDLINE:
		data[0].queue_free()
	
