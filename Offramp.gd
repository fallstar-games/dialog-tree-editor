extends GraphNode

@onready var destination_dropdown:OptionButton = $OptionButton
@onready var filename_container = $FileLineHBox
@onready var nodename_container = $TitleLineHBox
@onready var outcome_name_container = $OutcomeLineHBox
@onready var file_line:LineEdit = $FileLineHBox/LineEdit
@onready var title_line:LineEdit = $TitleLineHBox/LineEdit
@onready var outcome_line:LineEdit = $OutcomeLineHBox/LineEdit

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"dest_type": "SAME_TREE",
	"dest_node": "",
	"dest_outcome": "",
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
		0: #node in this tree
			node_data["dest_type"] = "SAME_TREE"
			#node_data["dest_node"] = title_line.text
			node_data["dest_outcome"] = outcome_line.text
		1: #another tree
			node_data["dest_type"] = "OUTSIDE_TREE"
			node_data["dest_node"] = file_line.text
			node_data["dest_outcome"] = outcome_line.text
		2: #terminate
			node_data["dest_type"] = "TERMINATE"
			node_data["dest_outcome"] = outcome_line.text

func _on_dest_dropdown_item_selected(index:int):
	change_mode(index)

func change_mode(idx:int = 0):

	match idx:
		0: #This Tree
			filename_container.hide()
			nodename_container.hide()
			outcome_name_container.show()

		1: #Outside Tree
			filename_container.show()
			nodename_container.hide()
			outcome_name_container.show()

		2: #Terminate
			filename_container.hide()
			nodename_container.hide()
			outcome_name_container.show()