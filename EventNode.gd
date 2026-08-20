extends GraphNode

@onready var event_dropdown:OptionButton = $OptionButton
@onready var check_type_dropdown:OptionButton = $CheckInfo/CheckType
@onready var split_type_dropdown:OptionButton = $SplitInfo/SplitType
@onready var wardrobe_action_dropdown:OptionButton = $WardrobeInfo/WardrobeAction
@onready var garment_slot_dropdown:OptionButton = $WardrobeInfo/SlotID/GarmentSlot
@onready var action_target_dropdown:OptionButton = $SplitInfo/SplitAction/TargetPerson/ActionTarget
@onready var permission_target_dropdown:OptionButton = $SplitInfo/SplitPermission/TargetPerson/PermissionTarget
@onready var enthusiasm_target_dropdown:OptionButton = $SplitInfo/SplitEnthusiasm/TargetPerson/EnthusiasmTarget
@onready var single_stat_target_dropdown:OptionButton = $SplitInfo/SplitSingleStat/TargetPerson/SingleStatTarget
@onready var subtree_type_dropdown:OptionButton = $SubTreeInfo/SubTreeType
@onready var line_entry_type_dropdown:OptionButton = $LineEntryInfo/LineEntryType
@onready var menu_type_dropdown:OptionButton = $MenuInfo/MenuSelect/MenuType
@onready var outfitter_info_container:VBoxContainer = $MenuInfo/OutfitterInfo
@onready var reaction_target_dropdown:OptionButton = $ReactionInfo/TargetPerson/ReactionTarget
@onready var resource_type_dropdown:OptionButton = $SplitInfo/SplitReactionStrength/ResourceType/ResourceType
@onready var reaction_should_trigger_checkbox:CheckBox = $SplitInfo/SplitReactionStrength/TriggerReaction/CheckBox
@onready var heart_level_target_dropdown:OptionButton = $SplitInfo/SplitHeartLevel/TargetPerson/HeartLevelTarget
#@onready var buy_sell_container = $ShopMode
#@onready var menu_line:LineEdit = $MenuInfo/LineEdit
#@onready var buy_btn:CheckBox = $ShopMode/Buy
#@onready var sell_btn:CheckBox = $ShopMode/Sell
@onready var event_containers:Dictionary = {
	"SPLIT": $SplitInfo,
	"CHECK": $CheckInfo,
	"SUBTREE": $SubTreeInfo,
	"CYCLER": $CyclerInfo,
	#"RANDOM": $RandomInfo,
	"WARDROBE": $WardrobeInfo,
	"MENU": $MenuInfo,
	"LINE_ENTRY": $LineEntryInfo,
	"REACTION": $ReactionInfo
}

@onready var subtree_containers:Dictionary = {
	"STANDARD": $SubTreeInfo/StandardInfo,
	"NEGOTIATION": $SubTreeInfo/NegotiationInfo
}

@onready var check_containers:Dictionary = {
	"REQUEST": $CheckInfo/RequestCheck,
	"COERCE": $CheckInfo/CoerceCheck,
	"FORCE": $CheckInfo/ForceCheck,
	"VIGOR": $CheckInfo/VigorCheck,
}

@onready var split_containers:Dictionary = {
	"BOOL": $SplitInfo/SplitBool,
	"INT": $SplitInfo/SplitInt,
	"RANDOM": $SplitInfo/SplitRandom,
	"ACTION_TEST": $SplitInfo/SplitAction,
	"REACTION_STRENGTH": $SplitInfo/SplitReactionStrength,
	"HEART_LEVEL": $SplitInfo/SplitHeartLevel,
	"STRING": $SplitInfo/SplitString,
	"PERMISSION_CHECK": $SplitInfo/SplitPermission,
	"ENTHUSIASM_CHECK": $SplitInfo/SplitEnthusiasm,
	"SINGLE_STAT": $SplitInfo/SplitSingleStat,
}

@onready var wardrobe_containers:Dictionary = {
	"WEAR_GARMENT": $WardrobeInfo/GarmentID,
	"REMOVE_GARMENT": $WardrobeInfo/SlotID,
	"WEAR_OUTFIT": $WardrobeInfo/OutfitID,
	"SAVE_OUTFIT": $WardrobeInfo/OutfitID
}

@onready var line_edits:Dictionary = {
	#"request_id": $CheckInfo/RequestCheck/RequestID/LineEdit,
	#"request_pass": $CheckInfo/RequestCheck/Pass/LineEdit,
	#"request_fail": $CheckInfo/RequestCheck/Fail/LineEdit,
	#"request_unsure": $CheckInfo/RequestCheck/Unsure/LineEdit,
	#"lever_id": $CheckInfo/CoerceCheck/LeverID/LineEdit,
	#"coerce_pass": $CheckInfo/CoerceCheck/Pass/LineEdit,
	#"coerce_fail": $CheckInfo/CoerceCheck/Fail/LineEdit,
	#"force_pass": $CheckInfo/ForceCheck/Pass/LineEdit,
	#"force_fail": $CheckInfo/ForceCheck/Fail/LineEdit,
	"split_bool_var_id": $SplitInfo/SplitBool/VarCall/LineEdit,
	"split_true_outcome": $SplitInfo/SplitBool/TrueOutcome/LineEdit,
	"split_false_outcome": $SplitInfo/SplitBool/FalseOutcome/LineEdit,
	"split_else_outcome": $SplitInfo/SplitInt/ElseOutcome/LineEdit,
	"split_int_var_id": $SplitInfo/SplitInt/VarCall/LineEdit,
	"split_string_var_id": $SplitInfo/SplitString/VarCall/LineEdit,
	"split_string_else_outcome": $SplitInfo/SplitString/ElseOutcome/LineEdit,
	"split_action_id": $SplitInfo/SplitAction/ActionID/LineEdit,
	"split_action_crit_success": $SplitInfo/SplitAction/CritSuccess/LineEdit,
	"split_action_crit_success_alt": $SplitInfo/SplitAction/CritSuccessAlt/LineEdit,
	"split_action_success": $SplitInfo/SplitAction/Success/LineEdit,
	"split_action_success_alt": $SplitInfo/SplitAction/SuccessAlt/LineEdit, 
	"split_action_fail": $SplitInfo/SplitAction/Fail/LineEdit,
	"split_action_weak_fail": $SplitInfo/SplitAction/WeakFail/LineEdit,
	"split_action_crit_fail": $SplitInfo/SplitAction/CritFail/LineEdit,
	"split_permission_action_id": $SplitInfo/SplitPermission/ActionID/LineEdit,
	"split_permission_diff_crit": $SplitInfo/SplitPermission/Difficulties/Crit,
	"split_permission_diff_success": $SplitInfo/SplitPermission/Difficulties/Success,
	"split_permission_diff_objection": $SplitInfo/SplitPermission/Difficulties/Objection,
	"split_permission_outcomes": {
		"crit_heat": $SplitInfo/SplitPermission/OutputsHeat/CritHeat,
		"yes_heat": $SplitInfo/SplitPermission/OutputsHeat/YesHeat,
		"crit_love": $SplitInfo/SplitPermission/OutputsLove/CritLove,
		"yes_love": $SplitInfo/SplitPermission/OutputsLove/YesLove,
		"crit_obey": $SplitInfo/SplitPermission/OutputsObey/CritObey,
		"yes_obey": $SplitInfo/SplitPermission/OutputsObey/YesObey,
		"objection": $SplitInfo/SplitPermission/OutputsFail/Objection,
		"refusal": $SplitInfo/SplitPermission/OutputsFail/Refusal
	},
	"split_enthusiasm_action_id": $SplitInfo/SplitEnthusiasm/ActionID/LineEdit,
	"split_enthusiasm_breakpoints": {
		"low": $SplitInfo/SplitEnthusiasm/BaseBreakpoints/HBoxContainer/LowBreakpoint,
		"high": $SplitInfo/SplitEnthusiasm/BaseBreakpoints/HBoxContainer/HighBreakpoint,
	},
	"split_enthusiasm_outcomes": {
		"high": $SplitInfo/SplitEnthusiasm/OutputHigh/LineEdit,
		"medium": $SplitInfo/SplitEnthusiasm/OutputMedium/LineEdit,
		"low": $SplitInfo/SplitEnthusiasm/OutputLow/LineEdit,
	},
	"split_single_stat_action_id": $SplitInfo/SplitSingleStat/ActionID/LineEdit,
	"split_single_stat_outcomes": {
		"crit": $SplitInfo/SplitSingleStat/OutputLoves/LineEdit,
		"pass": $SplitInfo/SplitSingleStat/OutputLikes/LineEdit,
		"fail": $SplitInfo/SplitSingleStat/OutputDislikes/LineEdit,
	},
	"split_reaction_id": $SplitInfo/SplitReactionStrength/ReactionID/LineEdit,
	"split_reaction_subtree": $SplitInfo/SplitReactionStrength/Subtree/LineEdit,
	"split_heart_level_subtree": $SplitInfo/SplitHeartLevel/Subtree/LineEdit,
	"reaction_id": $ReactionInfo/ReactionID/LineEdit,
	"reaction_novelty_counter": $ReactionInfo/NoveltyCounter/LineEdit,
	"subtree_id": $SubTreeInfo/StandardInfo/TreeName/LineEdit,
	"subtree_start": $SubTreeInfo/StandardInfo/NodeName/LineEdit,
	"neg_action_id": $SubTreeInfo/NegotiationInfo/ActionID/LineEdit,
	"neg_subtree_id": $SubTreeInfo/NegotiationInfo/TreeName/LineEdit,
	"neg_subtree_start": $SubTreeInfo/NegotiationInfo/NodeName/LineEdit,
	"neg_subtree_success": $SubTreeInfo/NegotiationInfo/OutcomeSuccess/LineEdit,
	"neg_subtree_no_patience": $SubTreeInfo/NegotiationInfo/OutcomeNoPatience/LineEdit,
	"neg_subtree_aborted": $SubTreeInfo/NegotiationInfo/OutcomeAborted/LineEdit,
	#"letter_id": $LetterInfo/LineEdit,
	#"cycle_id": $CyclerInfo/CycleID/LineEdit,
	"wardrobe_girl_id": $WardrobeInfo/GirlID/LineEdit,
	"outfit_id": $WardrobeInfo/OutfitID/LineEdit,
	"garment_id": $WardrobeInfo/GarmentID/LineEdit,
	"garment_slot_id": $WardrobeInfo/SlotID/LineEdit,
	#"menu_id": $MenuInfo/LineEdit,
	"outfitter_outfit_id": $MenuInfo/OutfitterInfo/OutfitID/LineEdit,
	"outfitter_output_yes_love": $MenuInfo/OutfitterInfo/YesLove/LineEdit,
	"outfitter_output_yes_obey": $MenuInfo/OutfitterInfo/YesObey/LineEdit,
	"outfitter_output_object": $MenuInfo/OutfitterInfo/Object/LineEdit,
	"outfitter_output_refuse": $MenuInfo/OutfitterInfo/Refuse/LineEdit,
	"outfitter_output_abort": $MenuInfo/OutfitterInfo/Abort/LineEdit,
	"line_entry_target_var": $LineEntryInfo/HBoxContainer/LineEdit
}

@onready var output_subtree = load("res://output_subtree.tscn")
@onready var output_cycler = load("res://output_cycler.tscn")
@onready var output_random = load("res://output_random.tscn")
@onready var output_greater = load("res://output_greater.tscn")
@onready var output_split_string = load("res://output_split_string.tscn")
@onready var weighted_attribute = load("res://weighted_attribute.tscn")
@onready var girl_resource_line = load("res://girl_resource_line.tscn")
@onready var player_resource_line = load("res://player_resource_line.tscn")

signal _cancel_button_pressed(output_type)

var output_subtree_count: int = 0
var output_cycler_count: int = 0
var output_random_count: int = 0
var output_greater_count: int = 0
var output_split_string_count: int = 0
var attribute_permission_count: int = 0
var attribute_enthusiasm_count: int = 0
var attribute_reaction_count: int = 0
var girl_resource_reaction_count: int = 0
var player_resource_reaction_count: int = 0

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"event_type":"SPLIT",
	"split_type": "BOOL",
	"split_bool_var_id": "",
	"split_int_var_id": "",
	"split_string_var_id": "",
	"split_true_outcome": "",
	"split_false_outcome": "",
	"split_greater_outcomes": {},
	"split_else_outcome": "",
	"split_string_else_outcome": "",
	"split_string_outcomes": {},
	"split_random_outcomes": {},
	"split_action_id": "",
	"split_action_target": "MAIN_PERSON",
	"split_action_outcomes": {},
	"split_permission_target": "MAIN_PERSON",
	"split_permission_action_id": "",
	"split_permission_difficulties": {
		"crit": "",
		"success": "",
		"objection": ""
	},
	"split_permission_attributes": {},
	"split_permission_outcomes": {},
	"split_enthusiasm_target": "MAIN_PERSON",
	"split_enthusiasm_action_id": "",
	"split_enthusiasm_breakpoints": {"low": "25", "high": "125"},
	"split_enthusiasm_attributes": {},
	"split_enthusiasm_outcomes": {},
	"split_single_stat_target": "MAIN_PERSON",
	"split_single_stat_action_id": "",
	"split_single_stat_attribute": {},
	"split_single_stat_outcomes": {},
	"split_reaction_id": "",
	"split_reaction_target": "MAIN_PERSON",
	"split_reaction_should_trigger": true,
	"split_resource_type": "player_money",
	"split_reaction_subtree": "",
	"split_heart_level_target": "MAIN_PERSON",
	"split_heart_level_subtree": "",
	#"check_type": "REQUEST",
	#"request_id": "",
	#"lever_id": "",
	#"outcome_pass": "",
	#"outcome_fail": "",
	#"outcome_unsure": "",
	"reaction_target": "MAIN_PERSON",
	"reaction_id": "",
	"reaction_novelty_counter": "",
	"reaction_girl_resources": {"love": "15", "heat":"low:10"},
	"reaction_player_resources": {},
	"reaction_attributes": {},
	"subtree_type": "STANDARD",
	"subtree_id": "",
	"subtree_start": "",
	"subtree_outputs": {},
	"neg_subtree_id": "",
	"neg_subtree_start": "",
	"neg_action_id": "",
	"neg_subtree_success": "",
	"neg_subtree_no_patience": "",
	"neg_subtree_aborted": "",
	#"cycle_id": "",
	#"cycler_outputs": [],
	#"random_outputs": {},
	"wardrobe_action": "WEAR_GARMENT",
	"wardrobe_girl_id": "",
	"outfit_id": "",
	"garment_id": "",
	"garment_slot_id": "PANTIES",
	#"menu_id":"",
	"menu_type": "OUTFITTER",
	"outfitter_outfit_id": "",
	"outfitter_output_yes_love": "",
	"outfitter_output_yes_obey": "",
	"outfitter_output_object": "",
	"outfitter_output_refuse": "",
	"outfitter_output_abort": "",
	#"letter_id":"",
	"line_entry_type":"PLAYER_NAME",
	"line_entry_target_var":"",
	"go to": []
}

func _ready():
	# SINGLE_STAT has exactly one attribute row and no way to add another, so hide its
	# remove button - freeing that row would leave the node with no stat to test.
	split_containers["SINGLE_STAT"].get_node("WeightedAttribute").get_node("CancelButton").hide()

func _on_close_request():
	get_parent().remove_node(self)

func _on_dragged(from, to):
	position_offset = to

func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize

func update_data():
	
	node_data["offset_x"] = position_offset.x
	node_data["offset_y"] = position_offset.y

	# Ensure dropdown-driven fields are captured even if no change signal fired (e.g., after duplicate/paste)
	var idx:int = event_dropdown.selected
	node_data["event_type"] = event_dropdown.get_item_text(idx)

	# Capture check type selection
	idx = check_type_dropdown.selected
	if idx >= 0:
		node_data["check_type"] = check_type_dropdown.get_item_text(idx)

	# Capture split type and related dropdowns
	idx = split_type_dropdown.selected
	if idx >= 0:
		node_data["split_type"] = split_type_dropdown.get_item_text(idx)

	# Capture wardrobe action and garment slot
	idx = wardrobe_action_dropdown.selected
	if idx >= 0:
		node_data["wardrobe_action"] = wardrobe_action_dropdown.get_item_text(idx)
	idx = garment_slot_dropdown.selected
	if idx >= 0:
		node_data["garment_slot_id"] = garment_slot_dropdown.get_item_text(idx)

	# Capture split action target (for ACTION_TEST)
	idx = action_target_dropdown.selected
	if idx >= 0:
		node_data["split_action_target"] = action_target_dropdown.get_item_text(idx)

	# Capture reaction target/resource type and heart level target even if signal didn't fire
	idx = reaction_target_dropdown.selected
	if idx >= 0:
		node_data["split_reaction_target"] = reaction_target_dropdown.get_item_text(idx)
	idx = resource_type_dropdown.selected
	if idx >= 0:
		node_data["split_resource_type"] = resource_type_dropdown.get_item_text(idx)
	idx = heart_level_target_dropdown.selected
	if idx >= 0:
		node_data["split_heart_level_target"] = heart_level_target_dropdown.get_item_text(idx)
	# Also persist the reaction trigger checkbox state
	node_data["split_reaction_should_trigger"] = bool(reaction_should_trigger_checkbox.button_pressed)

	# Capture subtree type
	idx = subtree_type_dropdown.selected
	if idx >= 0:
		node_data["subtree_type"] = subtree_type_dropdown.get_item_text(idx)

	# Capture line entry type
	idx = line_entry_type_dropdown.selected
	if idx >= 0:
		node_data["line_entry_type"] = line_entry_type_dropdown.get_item_text(idx)

	# Capture menu type
	idx = menu_type_dropdown.selected
	if idx >= 0:
		node_data["menu_type"] = menu_type_dropdown.get_item_text(idx)
	
	match node_data["event_type"]:
		#"CHECK":
		#	match node_data["check_type"]:
		#		"REQUEST":
		#			#node_data["request_id"] = line_edits["request_id"].text
		#			node_data["outcome_pass"] = line_edits["request_pass"].text
		#			node_data["outcome_fail"] = line_edits["request_fail"].text
		#			node_data["outcome_unsure"] = line_edits["request_unsure"].text
		#		"COERCE":
		#			node_data["lever_id"] = line_edits["lever_id"].text
		#			node_data["outcome_pass"] = line_edits["coerce_pass"].text
		#			node_data["outcome_fail"] = line_edits["coerce_fail"].text
		#		"FORCE":
		#			node_data["outcome_pass"] = line_edits["force_pass"].text
		#			node_data["outcome_fail"] = line_edits["force_fail"].text
		"SPLIT":
			match node_data["split_type"]:
				"BOOL":
					node_data["split_bool_var_id"] = line_edits["split_bool_var_id"].text
					node_data["split_true_outcome"] = line_edits["split_true_outcome"].text
					node_data["split_false_outcome"] = line_edits["split_false_outcome"].text
				"INT":
					node_data["split_int_var_id"] = line_edits["split_int_var_id"].text
					node_data["split_greater_outcomes"] = {}
					for output in split_containers["INT"].get_children():
						if "OutputGreater" in output.name:
							var target_value = output.get_node("IntLine").text
							var target_node = output.get_node("TargetLine").text
							node_data["split_greater_outcomes"][target_value] = target_node
					node_data["split_else_outcome"] = line_edits["split_else_outcome"].text
				"STRING":
					node_data["split_string_var_id"] = line_edits["split_string_var_id"].text
					node_data["split_string_outcomes"] = {}
					for output in split_containers["STRING"].get_children():
						if "OutputSplitString" in output.name:
							var target_value = output.get_node("StringLine").text
							var target_node = output.get_node("TargetLine").text
							node_data["split_string_outcomes"][target_value] = target_node
					node_data["split_string_else_outcome"] = line_edits["split_string_else_outcome"].text
				"RANDOM":
					node_data["split_random_outcomes"] = {}
					for output in split_containers["RANDOM"].get_children():
						if "OutputRandom" in output.name:
							var target_weight = output.get_node("IntLine").text
							var target_node = output.get_node("TargetLine").text
							node_data["split_random_outcomes"][target_node] = target_weight
				"PERMISSION_CHECK":
					node_data["split_permission_target"] = permission_target_dropdown.get_item_text(permission_target_dropdown.selected)
					node_data["split_permission_action_id"] = line_edits["split_permission_action_id"].text
					node_data["split_permission_difficulties"] = {
						"crit": line_edits["split_permission_diff_crit"].text,
						"success": line_edits["split_permission_diff_success"].text,
						"objection": line_edits["split_permission_diff_objection"].text
					}
					node_data["split_permission_attributes"] = {}
					for attribute in split_containers["PERMISSION_CHECK"].get_node("RelatedAttributes").get_children():
						if "WeightedAttributePermission" in attribute.name:
							var attr_type = attribute.get_node("AttributeType").get_item_text(attribute.get_node("AttributeType").selected)
							var attr_weight = attribute.get_node("AttributeWeight").text
							node_data["split_permission_attributes"][attr_type] = attr_weight
					node_data["split_permission_outcomes"] = {
						"crit_heat": line_edits["split_permission_outcomes"]["crit_heat"].text,
						"yes_heat": line_edits["split_permission_outcomes"]["yes_heat"].text,
						"crit_love": line_edits["split_permission_outcomes"]["crit_love"].text,
						"yes_love": line_edits["split_permission_outcomes"]["yes_love"].text,
						"crit_obey": line_edits["split_permission_outcomes"]["crit_obey"].text,
						"yes_obey": line_edits["split_permission_outcomes"]["yes_obey"].text,
						"objection": line_edits["split_permission_outcomes"]["objection"].text,
						"refusal": line_edits["split_permission_outcomes"]["refusal"].text
					}
				"ENTHUSIASM_CHECK":
					node_data["split_enthusiasm_target"] = enthusiasm_target_dropdown.get_item_text(enthusiasm_target_dropdown.selected)
					node_data["split_enthusiasm_action_id"] = line_edits["split_enthusiasm_action_id"].text
					node_data["split_enthusiasm_breakpoints"] = {
						"low": line_edits["split_enthusiasm_breakpoints"]["low"].text,
						"high": line_edits["split_enthusiasm_breakpoints"]["high"].text,
					}
					# values here are weights (weight x attribute level), not thresholds
					node_data["split_enthusiasm_attributes"] = {}
					for attribute in split_containers["ENTHUSIASM_CHECK"].get_node("RelatedAttributes").get_children():
						if "WeightedAttributeEnthusiasm" in attribute.name:
							var attr_type = attribute.get_node("AttributeType").get_item_text(attribute.get_node("AttributeType").selected)
							var attr_weight = attribute.get_node("AttributeWeight").text
							node_data["split_enthusiasm_attributes"][attr_type] = attr_weight
					node_data["split_enthusiasm_outcomes"] = {
						"high": line_edits["split_enthusiasm_outcomes"]["high"].text,
						"medium": line_edits["split_enthusiasm_outcomes"]["medium"].text,
						"low": line_edits["split_enthusiasm_outcomes"]["low"].text,
					}
				"SINGLE_STAT":
					node_data["split_single_stat_target"] = single_stat_target_dropdown.get_item_text(single_stat_target_dropdown.selected)
					node_data["split_single_stat_action_id"] = line_edits["split_single_stat_action_id"].text
					# exactly one stat, so the attribute row is a fixed child rather than an add/remove list
					var stat_row = split_containers["SINGLE_STAT"].get_node("WeightedAttribute")
					var stat_type = stat_row.get_node("AttributeType").get_item_text(stat_row.get_node("AttributeType").selected)
					node_data["split_single_stat_attribute"] = {stat_type: stat_row.get_node("AttributeWeight").text}
					node_data["split_single_stat_outcomes"] = {
						"crit": line_edits["split_single_stat_outcomes"]["crit"].text,
						"pass": line_edits["split_single_stat_outcomes"]["pass"].text,
						"fail": line_edits["split_single_stat_outcomes"]["fail"].text,
					}
				"ACTION_TEST":
					node_data["split_action_id"] = line_edits["split_action_id"].text
					node_data["split_action_outcomes"] = {
						"crit_success": line_edits["split_action_crit_success"].text,
						"success": line_edits["split_action_success"].text,
						"weak_fail": line_edits["split_action_weak_fail"].text,
						"fail": line_edits["split_action_fail"].text,
						"crit_fail": line_edits["split_action_crit_fail"].text,
						"crit_success_alt": line_edits["split_action_crit_success_alt"].text,
						"success_alt": line_edits["split_action_success_alt"].text
					}
				"REACTION_STRENGTH":
					node_data["split_reaction_id"] = line_edits["split_reaction_id"].text
					node_data["split_reaction_subtree"] = line_edits["split_reaction_subtree"].text
				"HEART_LEVEL":
					node_data["split_heart_level_subtree"] = line_edits["split_heart_level_subtree"].text
		"REACTION":
			node_data["reaction_target"] = reaction_target_dropdown.get_item_text(reaction_target_dropdown.selected)
			node_data["reaction_id"] = line_edits["reaction_id"].text
			node_data["reaction_novelty_counter"] = line_edits["reaction_novelty_counter"].text
			node_data["reaction_girl_resources"] = {}
			node_data["reaction_attributes"] = {}
			node_data["reaction_player_resources"] = {}
			for girl_resource in event_containers["REACTION"].get_node("GirlResources").get_children():
				if "GirlResourceLine" in girl_resource.name:
					var resource_type = girl_resource.get_node("ResourceType").get_item_text(girl_resource.get_node("ResourceType").selected)
					var resource_amount = girl_resource.get_node("ResourceAmount").text
					node_data["reaction_girl_resources"][resource_type] = resource_amount
			for attribute in event_containers["REACTION"].get_node("RelatedAttributes").get_children():
				if "WeightedAttributeReaction" in attribute.name:
					var attr_type = attribute.get_node("AttributeType").get_item_text(attribute.get_node("AttributeType").selected)
					var attr_weight = attribute.get_node("AttributeWeight").text
					node_data["reaction_attributes"][attr_type] = attr_weight
			for player_resource in event_containers["REACTION"].get_node("PlayerResources").get_children():
				if "PlayerResourceLine" in player_resource.name:
					var resource_type = player_resource.get_node("ResourceType").get_item_text(player_resource.get_node("ResourceType").selected)
					var resource_amount = player_resource.get_node("ResourceAmount").text
					node_data["reaction_player_resources"][resource_type] = resource_amount
		"SUBTREE":
			match node_data["subtree_type"]:
				"STANDARD":
					node_data["subtree_id"] = line_edits["subtree_id"].text
					node_data["subtree_start"] = line_edits["subtree_start"].text
					if output_subtree_count > 0:
						node_data["subtree_outputs"] = {}
						for output in event_containers["SUBTREE"].get_children():
							if "OutputSubtree" in output.name:
								var outcome_name = output.get_node("OutcomeLine").text
								var target_node = output.get_node("TargetLine").text
								node_data["subtree_outputs"][outcome_name] = target_node
				"NEGOTIATION":
					node_data["neg_action_id"] = line_edits["neg_action_id"].text
					node_data["neg_subtree_id"] = line_edits["neg_subtree_id"].text
					node_data["neg_subtree_start"] = line_edits["neg_subtree_start"].text
					node_data["neg_subtree_success"] = line_edits["neg_subtree_success"].text
					node_data["neg_subtree_no_patience"] = line_edits["neg_subtree_no_patience"].text
					node_data["neg_subtree_aborted"] = line_edits["neg_subtree_aborted"].text
		#"CYCLER":
		#	node_data["cycle_id"] = line_edits["cycle_id"].text
		#	if output_cycler_count > 0:
		#		node_data["cycler_outputs"] = []
		#		for output in event_containers["CYCLER"].get_children():
		#			if "OutputCycler" in output.name:
		#				#var cycle_index = output.get_node("IntLine").text
		#				var target_key = output.get_node("TargetLine").text
		#				node_data["cycler_outputs"].append(target_key)
		#"RANDOM":
		#	if output_random_count > 0:
		#		node_data["random_outputs"] = {}
		#		for output in event_containers["RANDOM"].get_children():
		#			if "OutputRandom" in output.name:
		#				var target_weight = output.get_node("IntLine").text
		#				var target_node = output.get_node("TargetLine").text
		#				node_data["random_outputs"][target_node] = target_weight

		"WARDROBE":
			node_data["wardrobe_girl_id"] = line_edits["wardrobe_girl_id"].text
			match node_data["wardrobe_action"]:
				"WEAR_GARMENT":
					node_data["garment_id"] = line_edits["garment_id"].text
				#"REMOVE_GARMENT":
				#	node_data["garment_slot_id"] = line_edits["garment_slot_id"].text
				"WEAR_OUTFIT":
					node_data["outfit_id"] = line_edits["outfit_id"].text
				"SAVE_OUTFIT":
					node_data["outfit_id"] = line_edits["outfit_id"].text
		"MENU":
			match node_data["menu_type"]:
				"OUTFITTER":
					node_data["outfitter_outfit_id"] = line_edits["outfitter_outfit_id"].text
					node_data["outfitter_output_yes_love"] = line_edits["outfitter_output_yes_love"].text
					node_data["outfitter_output_yes_obey"] = line_edits["outfitter_output_yes_obey"].text
					node_data["outfitter_output_object"] = line_edits["outfitter_output_object"].text
					node_data["outfitter_output_refuse"] = line_edits["outfitter_output_refuse"].text
					node_data["outfitter_output_abort"] = line_edits["outfitter_output_abort"].text
		"LINE_ENTRY":
			node_data["line_entry_target_var"] = line_edits["line_entry_target_var"].text


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

func change_split_mode(idx:int = 0):
	# Hide all split containers first
	for container in split_containers.values():
		container.hide()

	split_containers[split_type_dropdown.get_item_text(idx)].show()

func change_wardrobe_mode(idx:int = 0):
	# Hide all wardrobe containers first
	for container in wardrobe_containers.values():
		container.hide()

	wardrobe_containers[wardrobe_action_dropdown.get_item_text(idx)].show()

func change_subtree_mode(idx:int = 0):
	# Hide all subtree containers first
	for container in subtree_containers.values():
		container.hide()

	subtree_containers[subtree_type_dropdown.get_item_text(idx)].show()

func _on_event_dropdown_item_selected(index:int):
	node_data["event_type"] = event_dropdown.get_item_text(index)
	change_mode(index)

func _on_check_type_item_selected(index:int):
	node_data["check_type"] = check_type_dropdown.get_item_text(index)
	change_check_mode(index)

func _on_split_type_item_selected(index:int):
	node_data["split_type"] = split_type_dropdown.get_item_text(index)
	change_split_mode(index)

func _on_wardrobe_action_item_selected(index:int):
	node_data["wardrobe_action"] = wardrobe_action_dropdown.get_item_text(index)
	change_wardrobe_mode(index)

func _on_line_entry_type_item_selected(index:int):
	node_data["line_entry_type"] = line_entry_type_dropdown.get_item_text(index)

func _on_menu_type_item_selected(index:int):
	node_data["menu_type"] = menu_type_dropdown.get_item_text(index)
	outfitter_info_container.visible = menu_type_dropdown.get_item_text(index) == "OUTFITTER"

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
		split_containers["RANDOM"].add_child(new_output)
	elif output_type == "greater":
		output_greater_count += 1
		var new_output = output_greater.instantiate()
		new_output.name = "OutputGreater" + str(output_greater_count)
		split_containers["INT"].add_child(new_output)
	elif output_type == "string":
		output_split_string_count += 1
		var new_output = output_split_string.instantiate()
		new_output.name = "OutputSplitString" + str(output_split_string_count)
		split_containers["STRING"].add_child(new_output)
	else:
		push_error("Unknown output type: " + output_type)

func _on_add_attribute_button_pressed(test_type):
	if test_type == "permission":
		attribute_permission_count += 1
		var new_attribute = weighted_attribute.instantiate()
		new_attribute.name = "WeightedAttributePermission" + str(attribute_permission_count)
		split_containers["PERMISSION_CHECK"].get_node("RelatedAttributes").add_child(new_attribute)
	elif test_type == "enthusiasm":
		attribute_enthusiasm_count += 1
		var new_attribute = weighted_attribute.instantiate()
		new_attribute.name = "WeightedAttributeEnthusiasm" + str(attribute_enthusiasm_count)
		split_containers["ENTHUSIASM_CHECK"].get_node("RelatedAttributes").add_child(new_attribute)
	elif test_type == "reaction":
		attribute_reaction_count += 1
		var new_attribute = weighted_attribute.instantiate()
		new_attribute.name = "WeightedAttributeReaction" + str(attribute_reaction_count)
		event_containers["REACTION"].get_node("RelatedAttributes").add_child(new_attribute)

func _on_add_girl_resource_button_pressed():
	girl_resource_reaction_count += 1
	var new_resource_line = girl_resource_line.instantiate()
	new_resource_line.name = "GirlResourceLine" + str(girl_resource_reaction_count)
	event_containers["REACTION"].get_node("GirlResources").add_child(new_resource_line)

func _on_add_player_resource_button_pressed():
	player_resource_reaction_count += 1
	var new_resource_line = player_resource_line.instantiate()
	new_resource_line.name = "PlayerResourceLine" + str(player_resource_reaction_count)
	event_containers["REACTION"].get_node("PlayerResources").add_child(new_resource_line)

func _on_cancel_button_pressed(output_type): #output type is the node's name lowercased
	if "subtree" in output_type:
		output_subtree_count -= 1
	elif "cycler" in output_type:
		output_cycler_count -= 1
	elif "random" in output_type:
		output_random_count -= 1
	elif "greater" in output_type:
		output_greater_count -= 1
	elif "string" in output_type:
		output_split_string_count -= 1
	elif "permission" in output_type:
		attribute_permission_count -= 1
	elif "enthusiasm" in output_type:
		attribute_enthusiasm_count -= 1
	elif "attributereaction" in output_type:
		attribute_reaction_count -= 1
	elif "girlresource" in output_type:
		girl_resource_reaction_count -= 1
	elif "playerresource" in output_type:
		player_resource_reaction_count -= 1
	

func _on_garment_slot_item_selected(index:int):
	node_data["garment_slot_id"] = garment_slot_dropdown.get_item_text(index)


func _on_action_target_item_selected(index:int):
	node_data["split_action_target"] = action_target_dropdown.get_item_text(index)

func _on_permission_target_item_selected(index:int):
	node_data["split_permission_target"] = permission_target_dropdown.get_item_text(index)

func _on_single_stat_target_item_selected(index:int):
	node_data["split_single_stat_target"] = single_stat_target_dropdown.get_item_text(index)

func _on_enthusiasm_target_item_selected(index:int):
	node_data["split_enthusiasm_target"] = enthusiasm_target_dropdown.get_item_text(index)

func _on_sub_tree_type_item_selected(index:int):
	node_data["subtree_type"] = subtree_type_dropdown.get_item_text(index)
	change_subtree_mode(index)

func _on_heart_level_target_item_selected(index:int):
	node_data["split_heart_level_target"] = heart_level_target_dropdown.get_item_text(index)

func _on_reaction_target_item_selected(index:int):
	node_data["reaction_target"] = reaction_target_dropdown.get_item_text(index)

func _on_resource_type_item_selected(index:int):
	node_data["split_resource_type"] = resource_type_dropdown.get_item_text(index)

func _on_should_trigger_reaction_check_box_toggled(pressed: bool):
	node_data["split_reaction_should_trigger"] = pressed