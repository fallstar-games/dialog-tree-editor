extends GraphNode

@onready var action_dropdown:OptionButton = $ActionDropdown
@onready var slot_dropdown:OptionButton = $SlotDropdown
@onready var image_id_container = $ImageInfo
@onready var image_line:LineEdit = $ImageInfo/LineEdit

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"image_slot":"MAIN",
	"image_action":"NONE",
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
	"""
	var idx = action_dropdown.selected
	match idx:
		0: #none, just set iumage
			node_data["image_action"] = "NONE"
		1: #hide
			node_data["image_action"] = "HIDE"
		2: #show and do quake effect
			node_data["image_action"] = "QUAKE"
	"""

	node_data["image_id"] = image_line.text

	var idx2 = slot_dropdown.selected
	match idx2:
		0: #main
			node_data["image_slot"] = "MAIN"
		1: #left popup
			node_data["image_slot"] = "LEFT"
		2: #right popup
			node_data["image_slot"] = "RIGHT"
		3: #background
			node_data["image_slot"] = "BG"
		#4: #full
		#	node_data["image_slot"] = "BG" #full viewport image that is shown OVER the room BG
			

func _on_action_dropdown_item_selected(index:int):
	node_data["image_action"] = action_dropdown.get_item_text(index)
	#change_mode(index)

"""func change_mode(idx:int = 0):
	match idx:
		0: #Set (and show) Image
			image_id_container.show()

		_: #Show or Hide Image
			image_id_container.hide()
"""



