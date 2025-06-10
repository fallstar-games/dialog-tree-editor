extends GraphNode

@onready var slot_dropdown:OptionButton = $SlotDropdown
@onready var set_hide_dropdown:OptionButton = $SetHideDropdown
@onready var target_dropdown:OptionButton = $SetImageInfo/TargetDropdown


@onready var set_image_container:Node = $SetImageInfo
@onready var set_person_container:Node = $SetImageInfo/SetPerson
@onready var set_person_main_container:Node = $SetImageInfo/SetPerson/SetPersonMain
@onready var person_main_mode_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonMain/ModeDropdown
@onready var expression_container:Node = $SetImageInfo/SetPerson/SetPersonMain/ExpressionInfo
@onready var expression_eyes_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonMain/ExpressionInfo/EyesHBox/EyesDropdown
@onready var expression_mouth_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonMain/ExpressionInfo/MouthHBox/MouthDropdown
@onready var pose_container:Node = $SetImageInfo/SetPerson/SetPersonMain/PoseInfo
@onready var pose_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonMain/PoseInfo/PoseDropdown
@onready var set_person_lr_container:Node = $SetImageInfo/SetPerson/SetPersonLR
@onready var person_lr_mode_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonLR/ModeDropdown
@onready var lr_action_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonLR/ActionDropdown
@onready var lr_reaction_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonLR/ReactionDropdown
@onready var set_other_container:Node = $SetImageInfo/SetOther
@onready var image_id_line:LineEdit = $SetImageInfo/SetOther/ImageInfo/LineEdit
@onready var tween_dropdown:OptionButton = $SetImageInfo/TweenInfo/TweenDropdown

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"image_slot":"MAIN",
	"image_action":"HIDE",
	"image_target": "PERSON1",
	"image_person_main_mode": "EXPRESSION",
	"expression_eyes":0, #0 = no change, 1 = open, etc.
	"expression_mouth":0, #0 = no change, 1 = smile, etc.
	"pose": "",
	"image_person_lr_mode": "ACTION",
	"action": "KISS_TONGUE",
	"reaction": "SHOCKED",
	"image_id": "",
	"tween": "NONE",
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

	node_data["image_id"] = image_id_line.text

func _on_slot_dropdown_item_selected(index:int):
	node_data["image_slot"] = slot_dropdown.get_item_text(index)
	change_slot_mode(index)

func change_slot_mode(index:int):
	match index:
		0: #Main
			set_person_main_container.show()
			set_person_lr_container.hide()
		1, 2: #Left Popup, Right Popup
			set_person_main_container.hide()
			set_person_lr_container.show()

func _on_set_hide_dropdown_item_selected(index:int):
	node_data["image_action"] = set_hide_dropdown.get_item_text(index)
	change_set_hide_mode(index)

func change_set_hide_mode(index:int):
	match index:
		0: #Hide Image
			set_image_container.hide()
		1: #Set Image
			set_image_container.show()

func _on_target_dropdown_item_selected(index:int):
	node_data["image_target"] = target_dropdown.get_item_text(index)
	change_target_mode(index)

func change_target_mode(index:int):
	match index:
		0, 1: #Person 1, Person 2
			set_person_container.show()
			set_other_container.hide()
		2: #Other
			set_person_container.hide()
			set_other_container.show()

func _on_main_mode_dropdown_item_selected(index:int):
	node_data["image_person_main_mode"] = person_main_mode_dropdown.get_item_text(index)
	change_person_main_mode(index)

func change_person_main_mode(index:int):
	match index:
		0: #Expression
			expression_container.show()
			pose_container.hide()
		1: #Pose
			expression_container.hide()
			pose_container.show()

func _on_eyes_dropdown_item_selected(index:int):
	node_data["expression_eyes"] = index

func _on_mouth_dropdown_item_selected(index:int):
	node_data["expression_mouth"] = index

func _on_pose_dropdown_item_selected(index:int):
	if index != 0:
		node_data["pose"] = pose_dropdown.get_item_text(index)
	else:
		node_data["pose"] = ""  # Reset pose if "None" is selected

func _on_lr_mode_dropdown_item_selected(index:int):
	node_data["image_person_lr_mode"] = person_lr_mode_dropdown.get_item_text(index)
	change_person_lr_mode(index)

func change_person_lr_mode(index:int):
	match index:
		0: #Action
			lr_action_dropdown.show()
			lr_reaction_dropdown.hide()
		1: #Reaction
			lr_action_dropdown.hide()
			lr_reaction_dropdown.show()

func _on_reaction_dropdown_item_selected(index:int):
	node_data["reaction"] = lr_reaction_dropdown.get_item_text(index)

func _on_action_dropdown_item_selected(index:int):
	node_data["action"] = lr_action_dropdown.get_item_text(index)

func _on_tween_dropdown_item_selected(index:int):
	node_data["tween"] = tween_dropdown.get_item_text(index)
