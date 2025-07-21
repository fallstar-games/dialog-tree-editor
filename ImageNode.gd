extends GraphNode

@onready var slot_dropdown:OptionButton = $SlotDropdown
@onready var set_hide_dropdown:OptionButton = $SetHideDropdown
@onready var target_dropdown:OptionButton = $SetImageInfo/TargetDropdown


@onready var set_image_container:Node = $SetImageInfo
@onready var set_person_container:Node = $SetImageInfo/SetPerson
@onready var set_person_big_container:Node = $SetImageInfo/SetPerson/SetPersonBig
@onready var person_main_mode_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/ModeDropdown
@onready var paperdoll_container:Node = $SetImageInfo/SetPerson/SetPersonBig/PaperdollInfo
@onready var expression_eyes_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/PaperdollInfo/ExpressionHBox/EyesDropdown
@onready var expression_mouth_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/PaperdollInfo/ExpressionHBox/MouthDropdown
@onready var paperdoll_pose_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/PaperdollInfo/PoseFramingHBox/PoseDropdown
@onready var framing_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/PaperdollInfo/PoseFramingHBox/FramingDropdown
@onready var solo_container:Node = $SetImageInfo/SetPerson/SetPersonBig/SoloInfo
@onready var solo_pose_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/SoloInfo/SoloDropdown
@onready var duo_container:Node = $SetImageInfo/SetPerson/SetPersonBig/DuoInfo
@onready var duo_pose_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonBig/DuoInfo/DuoDropdown
@onready var set_person_small_container:Node = $SetImageInfo/SetPerson/SetPersonSmall
#@onready var person_lr_mode_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonSmall/ModeDropdown
#@onready var lr_action_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonSmall/ActionDropdown
#@onready var lr_reaction_dropdown:OptionButton = $SetImageInfo/SetPerson/SetPersonSmall/ReactionDropdown
@onready var set_other_container:Node = $SetImageInfo/SetOther
@onready var person_image_id_line:LineEdit = $SetImageInfo/SetPerson/SetPersonSmall/PersonImageInfo/LineEdit
@onready var other_image_id_line:LineEdit = $SetImageInfo/SetOther/OtherImageInfo/LineEdit
@onready var effect_container:Node = $SetImageInfo/EffectInfo
@onready var effect_dropdown:OptionButton = $SetImageInfo/EffectInfo/EffectDropdown

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"image_slot":"BIG",
	"image_action":"HIDE",
	"image_target": "PERSON_ONE",
	"image_person_big_mode": "PAPERDOLL",
	"expression_eyes": "no_change",
	"expression_mouth": "no_change",
	"paperdoll_pose": "no_change",
	"solo_pose": "SITTING",
	"duo_pose": "HOLDING_HANDS",
	"framing": "no_change",
	"person_image_id": "",
	"other_image_id": "",
	"effect": "NONE",
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

	node_data["person_image_id"] = person_image_id_line.text
	node_data["other_image_id"] = other_image_id_line.text

func _on_slot_dropdown_item_selected(index:int):
	node_data["image_slot"] = slot_dropdown.get_item_text(index)
	change_slot_mode(index)

func change_slot_mode(index:int):
	match index:
		0: #Big
			set_person_big_container.show()
			set_person_small_container.hide()
			effect_container.hide()
		1: #Small
			set_person_big_container.hide()
			set_person_small_container.show()
			effect_container.show()

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

func change_person_main_mode(index:int): #modes: PAPERDOLL, SOLO, DUO
	match index:
		0: #Paperdoll
			paperdoll_container.show()
			solo_container.hide()
			duo_container.hide()
		1: #Solo
			paperdoll_container.hide()
			solo_container.show()
			duo_container.hide()
		2: #Duo
			paperdoll_container.hide()
			solo_container.hide()
			duo_container.show()

func _on_eyes_dropdown_item_selected(index:int):
	if index != 0:
		node_data["expression_eyes"] = expression_eyes_dropdown.get_item_text(index)
	else:
		node_data["expression_eyes"] = "no_change"  # Reset eyes if "None" is selected

func _on_mouth_dropdown_item_selected(index:int):
	if index != 0:
		node_data["expression_mouth"] = expression_mouth_dropdown.get_item_text(index)
	else:
		node_data["expression_mouth"] = "no_change"  # Reset mouth if "None" is selected

func _on_pose_dropdown_item_selected(index:int):
	if index != 0:
		node_data["paperdoll_pose"] = paperdoll_pose_dropdown.get_item_text(index)
	else:
		node_data["paperdoll_pose"] = "no_change"  # Reset pose if "None" is selected

func _on_framing_dropdown_item_selected(index:int):
	if index != 0:
		node_data["framing"] = framing_dropdown.get_item_text(index)
	else:
		node_data["framing"] = "no_change"  # Leave current framing if "no change" is selected

func _on_lr_mode_dropdown_item_selected(index:int):
	pass
	#node_data["image_person_lr_mode"] = person_lr_mode_dropdown.get_item_text(index)
	#change_person_lr_mode(index)

func change_person_lr_mode(index:int):
	pass
	#match index:
	#	0: #Action
	#		lr_action_dropdown.show()
	#		lr_reaction_dropdown.hide()
	#	1: #Reaction
	#		lr_action_dropdown.hide()
	#		lr_reaction_dropdown.show()

func _on_reaction_dropdown_item_selected(index:int):
	#node_data["reaction"] = lr_reaction_dropdown.get_item_text(index)
	pass

func _on_action_dropdown_item_selected(index:int):
	#node_data["action"] = lr_action_dropdown.get_item_text(index)
	pass

func _on_tween_dropdown_item_selected(index:int):
	node_data["effect"] = effect_dropdown.get_item_text(index)

func _on_duo_dropdown_item_selected(index:int):
	node_data["duo_pose"] = duo_pose_dropdown.get_item_text(index)

func _on_solo_dropdown_item_selected(index:int):
	node_data["solo_pose"] = solo_pose_dropdown.get_item_text(index)
