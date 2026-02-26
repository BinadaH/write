class_name WActionManager

var wactions = []
var wactions_redo = []
const MAX_UNDO_COUNT = 20

func undo_waction():
	#undo
	var wa = wactions.pop_front()
	if wa:
		wa.undo()
		wactions_redo.push_front(wa)

func redo_waction():
	#redo
	var wa = wactions_redo.pop_front()
	if wa:
		wa.redo()
		wactions.push_front(wa)

func add_waction(waction : WAaction):
	if wactions.size() > MAX_UNDO_COUNT:
		wactions.resize(MAX_UNDO_COUNT - 1)
	wactions.push_front(waction)
	for w in wactions_redo:
		w.clear_data()
	wactions_redo.clear()
