extends GraphNode

#var node_type = "node"

#@export var text : CodeEdit
@onready var text = $Text/TextEdit
@onready var character_opt = $SpeakerHBox/SpeakerVBox/OptionButton
#@onready var line_asset = $LineAsset/LineEdit
#@onready var speaker = $SpeakerHBox/SpeakerVBox/LineEdit
@onready var image_type_opt = $LineAsset/HBoxContainer/OptionButton
@onready var image_id = $LineAsset/HBoxContainer/LineEdit
@onready var image_effect_opt = $LineAsset/HBoxContainer/OptionButton2


var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	#"character": "",
	"speaker": 0, #1 = main person, 2 = other person
	"text": "",
	#"line asset": "",
	"node title": "",
	"go to": []
}

func _on_close_request():

	# Delegate node removal to parent as its the orchestrator
	get_parent().remove_node(self)


func _on_dragged(from, to):
	position_offset = to
	
func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize
	
func _on_option_button_item_selected(index):
	node_data["speaker"] = index

func update_data():
	node_data["offset_x"] = position_offset.x
	node_data["offset_y"] = position_offset.y
	
	#node_data["character"] = speaker.text
	#node_data["speaker"] = speaker.text
	node_data["text"] = text.text
	#node_data["line asset"] = line_asset.text

