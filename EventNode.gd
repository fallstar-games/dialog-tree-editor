extends GraphNode

@onready var event_dropdown:OptionButton = $OptionButton
@onready var check_type_dropdown:OptionButton = $CheckInfo/CheckType
@onready var wardrobe_action_dropdown:OptionButton = $WardrobeInfo/WardrobeAction
@onready var garment_slot_dropdown:OptionButton = $WardrobeInfo/SlotID/GarmentSlot
#@onready var buy_sell_container = $ShopMode
@onready var menu_line:LineEdit = $MenuInfo/LineEdit
#@onready var buy_btn:CheckBox = $ShopMode/Buy
#@onready var sell_btn:CheckBox = $ShopMode/Sell
@onready var event_containers:Dictionary = {
	"CHECK": $CheckInfo,
	"SUBTREE": $SubTreeInfo,
	"CYCLER": $CyclerInfo,
	"RANDOM": $RandomInfo,
	"WARDROBE": $WardrobeInfo,
	"MENU": $MenuInfo
}

@onready var check_containers:Dictionary = {
	"REQUEST": $CheckInfo/RequestCheck,
	"COERCE": $CheckInfo/CoerceCheck,
	"FORCE": $CheckInfo/ForceCheck,
	"VIGOR": $CheckInfo/VigorCheck,
}

@onready var wardrobe_containers:Dictionary = {
	"WEAR_GARMENT": $WardrobeInfo/GarmentID,
	"REMOVE_GARMENT": $WardrobeInfo/SlotID,
	"WEAR_OUTFIT": $WardrobeInfo/OutfitID,
	"SAVE_OUTFIT": $WardrobeInfo/OutfitID
}

@onready var line_edits:Dictionary = {
	"request_id": $CheckInfo/RequestCheck/RequestID/LineEdit,
	"request_pass": $CheckInfo/RequestCheck/Pass/LineEdit,
	"request_fail": $CheckInfo/RequestCheck/Fail/LineEdit,
	"request_unsure": $CheckInfo/RequestCheck/Unsure/LineEdit,
	"lever_id": $CheckInfo/CoerceCheck/LeverID/LineEdit,
	"coerce_pass": $CheckInfo/CoerceCheck/Pass/LineEdit,
	"coerce_fail": $CheckInfo/CoerceCheck/Fail/LineEdit,
	"force_pass": $CheckInfo/ForceCheck/Pass/LineEdit,
	"force_fail": $CheckInfo/ForceCheck/Fail/LineEdit,
	"subtree_id": $SubTreeInfo/TreeName/LineEdit,
	"subtree_start": $SubTreeInfo/NodeName/LineEdit,
	"cycle_id": $CyclerInfo/CycleID/LineEdit,
	"outfit_id": $WardrobeInfo/OutfitID/LineEdit,
	"garment_id": $WardrobeInfo/GarmentID/LineEdit,
	"garment_slot_id": $WardrobeInfo/SlotID/LineEdit
}

@onready var output_subtree = load("res://output_subtree.tscn")
@onready var output_cycler = load("res://output_cycler.tscn")
@onready var output_random = load("res://output_random.tscn")

signal _cancel_button_pressed(output_type)

var output_subtree_count: int = 0
var output_cycler_count: int = 0
var output_random_count: int = 0

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"event_type":"CHECK",
	"check_type": "REQUEST",
	"request_id": "",
	"lever_id": "",
	"outcome_pass": "",
	"outcome_fail": "",
	"outcome_unsure": "",
	"subtree_id": "",
	"subtree_start": "",
	"subtree_outputs": {},
	"cycle_id": "",
	"cycler_outputs": [],
	"random_outputs": {},
	"wardrobe_action": "WEAR_GARMENT",
	"outfit_id": "",
	"garment_id": "",
	"garment_slot_id": "PANTIES",
	"menu_id":"",
	#"letter_id":"",
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

	#var idx = event_dropdown.selected
	#node_data["event_type"] = event_dropdown.get_item_text(idx)
	
	match node_data["event_type"]:
		"CHECK":
			match node_data["check_type"]:
				"REQUEST":
					node_data["request_id"] = line_edits["request_id"].text
					node_data["outcome_pass"] = line_edits["request_pass"].text
					node_data["outcome_fail"] = line_edits["request_fail"].text
					node_data["outcome_unsure"] = line_edits["request_unsure"].text
				"COERCE":
					node_data["lever_id"] = line_edits["lever_id"].text
					node_data["outcome_pass"] = line_edits["coerce_pass"].text
					node_data["outcome_fail"] = line_edits["coerce_fail"].text
				"FORCE":
					node_data["outcome_pass"] = line_edits["force_pass"].text
					node_data["outcome_fail"] = line_edits["force_fail"].text
		"SUBTREE":
			node_data["subtree_id"] = line_edits["subtree_id"].text
			node_data["subtree_start"] = line_edits["subtree_start"].text
			if output_subtree_count > 0:
				node_data["subtree_outputs"] = {}
				for output in event_containers["SUBTREE"].get_children():
					if "OutputSubtree" in output.name:
						var outcome_name = output.get_node("OutcomeLine").text
						var target_node = output.get_node("TargetLine").text
						node_data["subtree_outputs"][outcome_name] = target_node
		"CYCLER":
			node_data["cycle_id"] = line_edits["cycle_id"].text
			if output_cycler_count > 0:
				node_data["cycler_outputs"] = []
				for output in event_containers["CYCLER"].get_children():
					if "OutputCycler" in output.name:
						#var cycle_index = output.get_node("IntLine").text
						var target_key = output.get_node("TargetLine").text
						node_data["cycler_outputs"].append(target_key)
		"RANDOM":
			if output_random_count > 0:
				node_data["random_outputs"] = {}
				for output in event_containers["RANDOM"].get_children():
					if "OutputRandom" in output.name:
						var target_weight = output.get_node("IntLine").text
						var target_node = output.get_node("TargetLine").text
						node_data["random_outputs"][target_node] = target_weight

		"WARDROBE":
			match node_data["wardrobe_action"]:
				"WEAR_GARMENT":
					node_data["garment_id"] = line_edits["garment_id"].text
				#"REMOVE_GARMENT":
				#	node_data["garment_slot_id"] = line_edits["garment_slot_id"].text
				"WEAR_OUTFIT":
					node_data["outfit_id"] = line_edits["outfit_id"].text
				"SAVE_OUTFIT":
					node_data["outfit_id"] = line_edits["outfit_id"].text


func change_mode(idx:int = 0):
	# Hide all containers first
	for container in event_containers.values():
		container.hide()

	event_containers[event_dropdown.get_item_text(idx)].show()

func change_check_mode(idx:int = 0):
	# Hide all check containers first
	for container in check_containers.values():
		container.hide()

	check_containers[check_type_dropdown.get_item_text(idx)].show()

func change_wardrobe_mode(idx:int = 0):
	# Hide all wardrobe containers first
	for container in wardrobe_containers.values():
		container.hide()

	wardrobe_containers[wardrobe_action_dropdown.get_item_text(idx)].show()

func _on_event_dropdown_item_selected(index:int):
	node_data["event_type"] = event_dropdown.get_item_text(index)
	change_mode(index)

func _on_check_type_item_selected(index:int):
	node_data["check_type"] = check_type_dropdown.get_item_text(index)
	change_check_mode(index)

func _on_wardrobe_action_item_selected(index:int):
	node_data["wardrobe_action"] = wardrobe_action_dropdown.get_item_text(index)
	change_wardrobe_mode(index)

func _on_add_output_button_pressed(output_type):
	if output_type == "subtree":
		output_subtree_count += 1
		var new_output = output_subtree.instantiate()
		new_output.name = "OutputSubtree" + str(output_subtree_count)
		print("adding new output node named: " + new_output.name)
		event_containers["SUBTREE"].add_child(new_output)
	elif output_type == "cycler":
		output_cycler_count += 1
		var new_output = output_cycler.instantiate()
		new_output.name = "OutputCycler" + str(output_cycler_count)
		event_containers["CYCLER"].add_child(new_output)
	elif output_type == "random":
		output_random_count += 1
		var new_output = output_random.instantiate()
		new_output.name = "OutputRandom" + str(output_random_count)
		event_containers["RANDOM"].add_child(new_output)
	else:
		push_error("Unknown output type: " + output_type)

func _on_cancel_button_pressed(output_type):
	if "subtree" in output_type:
		output_subtree_count -= 1
	elif "cycler" in output_type:
		output_cycler_count -= 1
	elif "random" in output_type:
		output_random_count -= 1

func _on_garment_slot_item_selected(index:int):
	node_data["garment_slot_id"] = garment_slot_dropdown.get_item_text(index)
