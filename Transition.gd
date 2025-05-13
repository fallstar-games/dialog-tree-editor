extends GraphNode


@onready var locale_line:LineEdit = $LocaleContainer/LineEdit
@onready var time_line:LineEdit = $HBoxContainer/LineEdit
@onready var person_opt:OptionButton = $HBoxContainer3/PersonOption
@onready var person_line:LineEdit = $HBoxContainer3/PersonID
@onready var focus_opt:OptionButton = $HBoxContainer4/FocusOption

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"room_id": "",
	"time_forward": 0,
	"person_id": "",
	"person_type": 0, # 0 = main person, 1 = other person
	"focus_change": 0, # 0 = no change, 1 = focus on, 2 = focus off
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
	node_data["time_forward"] = time_line.text.to_int()
	node_data["person_id"] = person_line.text



func _on_focus_option_item_selected(index:int):
	node_data["focus_change"] = index

func _on_person_option_item_selected(index:int):
	node_data["person_type"] = index
