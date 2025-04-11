extends GraphNode

@onready var action_dropdown:OptionButton = $ActionDropdown
@onready var slot_dropdown:OptionButton = $SlotDropdown
@onready var image_id_container = $ImageInfo
@onready var image_line:LineEdit = $ImageInfo/LineEdit

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"image_slot":"CENTER",
	"image_action":"SET",
	"image_id": "",
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

	var idx = action_dropdown.selected
	match idx:
		0: #set
			node_data["image_action"] = "SET"
			node_data["image_id"] = image_line.text
		1: #show
			node_data["image_action"] = "SHOW"
		2: #hide
			node_data["image_action"] = "HIDE"

	var idx2 = slot_dropdown.selected
	match idx2:
		0: #left
			node_data["image_slot"] = "LEFT"
		1: #center
			node_data["image_slot"] = "CENTER"
		2: #right
			node_data["image_slot"] = "RIGHT"
		3: #all
			node_data["image_slot"] = "ALL"
		4: #full
			node_data["image_slot"] = "FULL" #full viewport image that is shown OVER the room BG
			

func _on_action_dropdown_item_selected(index:int):
	change_mode(index)

func change_mode(idx:int = 0):
	match idx:
		0: #Set (and show) Image
			image_id_container.show()

		_: #Show or Hide Image
			image_id_container.hide()




