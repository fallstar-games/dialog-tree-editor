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
@onready var eyes_opt = $PaperDollInfo/ExpressionHBox/Expression
@onready var mouth_opt = $PaperDollInfo/ExpressionHBox/LowerExpression
@onready var pose_dropdown = $PaperDollInfo/PoseFrameHBox/Pose
@onready var framing_dropdown = $PaperDollInfo/PoseFrameHBox/Framing
#@onready var pose_framing_parent = $PaperDollInfo/PoseFrameHBox
#@onready var expression_parent = $PaperDollInfo/ExpressionHBox
@onready var paperdoll_parent = $PaperDollInfo
@onready var solo_parent = $SoloInfo
@onready var solo_dropdown = $SoloInfo/SoloDropdown
@onready var duo_parent = $DuoInfo
@onready var duo_dropdown = $DuoInfo/DuoDropdown
@onready var image_type_dropdown = $ImageTypeHBox/ImageType
@onready var image_type_parent = $ImageTypeHBox
@onready var room_designator_parent = $RoomDesignator
@onready var room_line = $RoomDesignator/LineEdit


var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"speaker": 0, #0 = narrator, 1 = main person, 2 = other person, 3 = SMS, 4 = App
	"image_type": "no_change", #"" = no image, "PAPERDOLL", "SOLO", "DUO"
	"expression_eyes": "no_change", #0 = none
	"expression_mouth": "no_change", #0 = none
	"paperdoll_pose": "no_change", #"" = none
	"framing": "no_change",
	"solo_pose": "SITTING",
	"duo_pose": "HOLDING_HANDS", 
	"text": "",
	#"image_id": "",
	#"image_effect": "none",
	"room_id": "",
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
	change_speaker_mode(index)

func change_speaker_mode(index):
	match index:
		0: # Narrator
			image_type_parent.hide()
			room_designator_parent.show()
		1, 2: # Main person or other person
			image_type_parent.show()
			room_designator_parent.hide()
		_: # SMS or App
			image_type_parent.hide()
			room_designator_parent.hide()

func update_data():
	node_data["offset_x"] = position_offset.x
	node_data["offset_y"] = position_offset.y

	node_data["room_id"] = room_line.text
	node_data["text"] = text.text

func _on_image_type_item_selected(index:int):
	if index != 0:
		node_data["image_type"] = image_type_dropdown.get_item_text(index)
	else:
		node_data["image_type"] = "no_change"  # Reset image type if "No Image" is selected
	change_image_type_mode(index)

func change_image_type_mode(index:int):
	match index:
		0: # No image
			paperdoll_parent.hide()
			solo_parent.hide()
			duo_parent.hide()
		1: # Paperdoll
			paperdoll_parent.show()
			solo_parent.hide()
			duo_parent.hide()
		2: # Solo
			paperdoll_parent.hide()
			solo_parent.show()
			duo_parent.hide()
		3: # Duo
			paperdoll_parent.hide()
			solo_parent.hide()
			duo_parent.show()

func _on_expression_item_selected(index:int):
	if index != 0:
		node_data["expression_eyes"] = eyes_opt.get_item_text(index)
	else:
		node_data["expression_eyes"] = "no_change"  # Reset eyes if "None" is selected


func _on_lower_expression_item_selected(index:int):
	if index != 0:
		node_data["expression_mouth"] = mouth_opt.get_item_text(index)
	else:
		node_data["expression_mouth"] = "no_change"  # Reset mouth if "None" is selected


func _on_pose_item_selected(index:int):
	if index != 0:
		node_data["paperdoll_pose"] = pose_dropdown.get_item_text(index)
	else:
		node_data["paperdoll_pose"] = "no_change"  # Reset pose if "None" is selected


func _on_framing_item_selected(index:int):
	if index != 0:
		node_data["framing"] = framing_dropdown.get_item_text(index)
	else:
		node_data["framing"] = "no_change"  # Leave current framing if "no change" is selected



func _on_duo_dropdown_item_selected(index:int):
	node_data["duo_pose"] = duo_dropdown.get_item_text(index)

func _on_solo_dropdown_item_selected(index:int):
	node_data["solo_pose"] = solo_dropdown.get_item_text(index)
