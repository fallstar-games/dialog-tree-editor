extends GraphNode

#var node_type = "node"

#@export var text : CodeEdit
@onready var text = $Text/TextEdit
@onready var character_opt = $SpeakerHBox/SpeakerVBox/OptionButton
#@onready var line_asset = $LineAsset/LineEdit
#@onready var speaker = $SpeakerHBox/SpeakerVBox/LineEdit
#@onready var image_type_opt = $LineAsset/HBoxContainer/ImageType
#@onready var image_id_line = $LineAsset/HBoxContainer/LineEdit
#@onready var image_effect_opt = $LineAsset/HBoxContainer/ImageEffect
@onready var eyes_opt = $Expression
@onready var mouth_opt = $LowerExpression
@onready var pose_dropdown = $Pose


var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"speaker": 0, #0 = narrator, 1 = main person, 2 = other person, 3 = SMS, 4 = App
	"eyes": 0, #0 = none
	"mouth": 0, #0 = none
	"pose": "", #"" = none
	"text": "",
	#"image_type": 0, #0 = none, 1 = main, 2 = popup
	#"image_id": "",
	#"image_effect": "none",
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
	
	#node_data["speaker"] = speaker.text
	node_data["text"] = text.text
	#node_data["image_id"] = image_id_line.text


#func _on_image_effect_item_selected(index:int):
#	node_data["image_effect"] = image_effect_opt.get_item_text(index)

#func _on_image_type_item_selected(index:int):
#	node_data["image_type"] = index


func _on_expression_item_selected(index:int):
	node_data["eyes"] = index
	if index == 0:
		mouth_opt.hide()
		pose_dropdown.hide()
	else:
		mouth_opt.show()
		pose_dropdown.show()


func _on_lower_expression_item_selected(index:int):
	node_data["mouth"] = index


func _on_pose_item_selected(index:int):
	if index != 0:
		node_data["pose"] = pose_dropdown.get_item_text(index)
	else:
		node_data["pose"] = ""  # Reset pose if "None" is selected
