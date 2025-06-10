extends GraphNode


@onready var locale_line:LineEdit = $LocaleContainer/LineEdit
@onready var fade_line:LineEdit = $TransitionTimeContainer/FadeLine
@onready var wait_line:LineEdit = $TransitionTimeContainer/WaitLine
@onready var main_person_line:LineEdit = $Person1Container/PersonID
@onready var second_person_line:LineEdit = $Person2Container/PersonID
@onready var person_2_container:Node = $Person2Container

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"room_id": "",
	"fade_time": 0,
	"wait_time": 0,
	"main_person_id": "",
	"second_person_id": "",
	#"person_type": 0, # 0 = main person, 1 = other person
	#"focus_change": 0, # 0 = no change, 1 = focus on, 2 = focus off
	"go to": []
}

func _on_close_request():
	get_parent().remove_node(self)

func _on_dragged(from, to):
	position_offset = to

func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize

func update_data():
	
	node_data["offset_x"] = position_offset.x
	node_data["offset_y"] = position_offset.y
	node_data["room_id"] = locale_line.text
	node_data["fade_time"] = fade_line.text.to_float()
	node_data["wait_time"] = wait_line.text.to_float()
	node_data["main_person_id"] = main_person_line.text
	node_data["second_person_id"] = second_person_line.text

func _on_focus_option_item_selected(index:int):
	node_data["focus_change"] = index

func _on_person_option_item_selected(index:int):
	node_data["person_type"] = index


func _on_person_id_text_changed(new_text):
	show_hide_person_2()

func show_hide_person_2():
	if main_person_line.text != "":
		person_2_container.show()
	else:
		person_2_container.hide()
