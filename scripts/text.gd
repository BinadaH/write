extends Node2D


var text = ""

func render():
	var new_l = Label.new()
	new_l.text = text
	add_child(new_l)

	print(text)
