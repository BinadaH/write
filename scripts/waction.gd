class_name WAaction

enum ACTION_TYPE{
	ADDLINE
}

var type
var data



func set_action_add_line(line : Line2D):
	self.type = ACTION_TYPE.ADDLINE
	self.data = line

func undo():
	if type == ACTION_TYPE.ADDLINE:
		if data:
			data.queue_free()
		
