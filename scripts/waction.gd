class_name WAaction

enum ACTION_TYPE{
	ADDLINE,
	DELETE_OBJ,
	RESET_SCALE
}

var type
var data

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if type == ACTION_TYPE.DELETE_OBJ:
			if data && data[0].find_parent("canvas"):
				data[0].queue_free()

func set_action_add_line(line : Line2D):
	self.type = ACTION_TYPE.ADDLINE
	self.data = line

func set_action_delete_obj(obj, parent):
	self.type = ACTION_TYPE.DELETE_OBJ
	self.data = [obj, parent]

func set_action_reset_scale(objs):
	self.type = ACTION_TYPE.RESET_SCALE
	self.data = {}
	for o in objs:
		if o is Line2D:
			self.data[o] = o.points

func undo():
	if type == ACTION_TYPE.ADDLINE:
		if data:
			data.queue_free()
	elif type == ACTION_TYPE.DELETE_OBJ:
		data[1].add_child(data[0])
		data = null
	elif type == ACTION_TYPE.RESET_SCALE:
		for o in self.data.keys():
			if o is Line2D:
				o.points = self.data[o]
		
