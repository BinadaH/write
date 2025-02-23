class_name WAaction

enum ACTION_TYPE{
	ADDLINE,
	DELETE_OBJ
}

var type
var data

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if type == ACTION_TYPE.DELETE_OBJ:
			if data:
				data[0].queue_free()

func set_action_add_line(line : Line2D):
	self.type = ACTION_TYPE.ADDLINE
	self.data = line

func set_action_delete_obj(obj, parent):
	self.type = ACTION_TYPE.DELETE_OBJ
	self.data = [obj, parent]

func undo():
	if type == ACTION_TYPE.ADDLINE:
		if data:
			data.queue_free()
	elif type == ACTION_TYPE.DELETE_OBJ:
		data[1].add_child(data[0])
		data = null
