extends GraphNode

@onready var key_line:LineEdit = $LineEdit

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"string_key": "",
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

	node_data["string_key"] = key_line.text
