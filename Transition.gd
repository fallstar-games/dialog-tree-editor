extends GraphNode


@onready var locale_line:LineEdit = $LocaleContainer/LineEdit
@onready var time_line:LineEdit = $HBoxContainer/LineEdit

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"room_id": "",
	"time_forward": 0,
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
