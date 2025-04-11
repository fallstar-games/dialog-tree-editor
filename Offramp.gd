extends GraphNode

@onready var destination_dropdown:OptionButton = $OptionButton
@onready var filename_container = $FileLineHBox
@onready var nodename_container = $TitleLineHBox
@onready var mapname_container = $MapLineHBox
@onready var file_line:LineEdit = $FileLineHBox/LineEdit
@onready var title_line:LineEdit = $TitleLineHBox/LineEdit
@onready var map_line:LineEdit = $MapLineHBox/LineEdit

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"dest_type": "DIALOGTREE",
	"dest_node": "",
	"dest_map": "",
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

	var idx = destination_dropdown.selected
	match idx:
		0: #target dialog node
			node_data["dest_type"] = "DIALOGTREE"
			node_data["dest_node"] = file_line.text + "." + title_line.text
		1: #target travel map
			node_data["dest_type"] = "TRAVELMAP"
			node_data["dest_map"] = map_line.text

func _on_dest_dropdown_item_selected(index:int):
	change_mode(index)

func change_mode(idx:int = 0):

	match idx:
		0: #Dialogue Tree
			filename_container.show()
			nodename_container.show()
			mapname_container.hide()

		1: #Travel Map
			filename_container.hide()
			nodename_container.hide()
			mapname_container.show()
