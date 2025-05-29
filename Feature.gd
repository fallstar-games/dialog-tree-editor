extends GraphNode

#var node_type = "feature"

# Signal
signal _cancel_button_pressed(feature_type)

# Stats
var variable_count : int = 0
var signal_count : int = 0
var conditional_count : int = 0
var greater_count : int = 0
var less_count : int = 0
var equal_count : int = 0
var has_garment_count : int = 0

# Data
var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"set_variables": {},
	"signals": [],
	"if_boolean": {},
	"if_greater": {},
	"if_less": {},
	"if_equal": {},
	"has_garment": {},
	"node title": "",
	"go to": []
}

func update_data():
	node_data["offset_x"] = self.position_offset.x
	node_data["offset_y"] = self.position_offset.y

	print("var count = " + str(variable_count) + ", signal count = " + str(signal_count) + ", conditional count = " + str(conditional_count))
	
	if variable_count != 0:
		for individual_variable in variables_group.get_children():
			if "Variable" in individual_variable.name:
				var var_active = individual_variable.get_node("CheckButton").button_pressed 
				var var_name = individual_variable.get_node("LineEdit").text 
				
				node_data["set_variables"][var_name] = var_active
		
	if signal_count != 0 :		
		for individual_signal in emit_signal_group.get_children():	
			if "Signal"	in individual_signal.name:
				var signal_name = individual_signal.get_node("LineEdit").text
				
				if not signal_name in node_data["signals"]:
					node_data["signals"].append(signal_name)

	if conditional_count != 0:
		for individual_conditional in conditionals_group.get_children():
			if "Conditional" in individual_conditional.name:
				var condition_exists = individual_conditional.get_node("CheckButton").button_pressed 
				var condition_name = individual_conditional.get_node("LineEdit").text 
				
				node_data["if_boolean"][condition_name] = condition_exists
	
	if greater_count != 0:
		for individual_greater in greater_group.get_children():
			if "Greater" in individual_greater.name:
				var greater_name = individual_greater.get_node("VarNameLine").text 
				var greater_value = individual_greater.get_node("IntLine").text 
				
				node_data["if_greater"][greater_name] = greater_value

	if less_count != 0:
		for individual_less in less_group.get_children():
			if "Less" in individual_less.name:
				var less_name = individual_less.get_node("VarNameLine").text 
				var less_value = individual_less.get_node("IntLine").text 
				
				node_data["if_less"][less_name] = less_value

	if equal_count != 0:
		for individual_equal in equal_group.get_children():
			if "Equal" in individual_equal.name:
				var equal_name = individual_equal.get_node("VarNameLine").text 
				var equal_value = individual_equal.get_node("IntLine").text 
				
				node_data["if_equal"][equal_name] = equal_value

	if has_garment_count != 0:
		for individual_garment in has_garment_group.get_children():
			if "HasGarment" in individual_garment.name:
				var garment_name = individual_garment.get_node("LineEdit").text 
				var garment_active = individual_garment.get_node("CheckButton").button_pressed 
				
				node_data["has_garment"][garment_name] = garment_active

# Nodes
@onready var variables_group = $VariablesGroup
@onready var emit_signal_group = $EmitSignalGroup
@onready var conditionals_group = $ConditionalsGroup
@onready var greater_group = $GreaterGroup
@onready var less_group = $LessGroup
@onready var equal_group = $EqualGroup
@onready var has_garment_group = $HasGarmentGroup

@onready var variable = load("res://Variable.tscn")
@onready var emit_signal = load("res://Signal.tscn")
@onready var conditional = load("res://Conditional.tscn")
@onready var greater = load("res://greater.tscn")
@onready var less = load("res://less.tscn")
@onready var equal = load("res://equal.tscn")
@onready var has_garment = load("res://has_garment.tscn")


func _ready():
	variables_group.hide()
	emit_signal_group.hide()
	conditionals_group.hide()
	greater_group.hide()
	less_group.hide()
	equal_group.hide()
	has_garment_group.hide()

############### 1 | GENERAL ##############################

# Cancelling features
func _on_cancel_button_pressed(feature_type):
	#print("Cancel pressed for feature type: " + feature_type)
	if "variable" in feature_type:
		variable_count -= 1
		
		if variable_count == 0:
			variables_group.hide()
		
	elif "signal" in feature_type:
		signal_count -= 1	
		
		if signal_count == 0:
			emit_signal_group.hide()
		
	elif "conditional" in feature_type:
		conditional_count -= 1
		
		if conditional_count == 0:
			conditionals_group.hide()

	elif "greater" in feature_type:
		greater_count -= 1
		
		if greater_count == 0:
			greater_group.hide()

	elif "less" in feature_type:
		less_count -= 1
		
		if less_count == 0:
			less_group.hide()

	elif "equal" in feature_type:
		equal_count -= 1
		
		if equal_count == 0:
			equal_group.hide()

	elif "hasgarment" in feature_type:
		has_garment_count -= 1
		
		if has_garment_count == 0:
			has_garment_group.hide()
		
# Add Groups
func _on_add_button_pressed(feature_type):
	if feature_type == "variable":
		variable_count += 1
		
		var new_variable = variable.instantiate()
		new_variable.name = "Variable" + str(variable_count)
		variables_group.add_child(new_variable)
		
	elif feature_type == "signal":
		signal_count += 1	
		
		var new_emit_signal = emit_signal.instantiate()
		new_emit_signal.name = "Signal" + str(signal_count)
		emit_signal_group.add_child(new_emit_signal)
		
	elif feature_type == "conditional":
		conditional_count += 1
		var new_conditional = conditional.instantiate()
		new_conditional.name = "Conditional" + str(conditional_count)
		conditionals_group.add_child(new_conditional)

	elif feature_type == "greater":
		greater_count += 1
		var new_greater = greater.instantiate()
		new_greater.name = "Greater" + str(greater_count)
		greater_group.add_child(new_greater)

	elif feature_type == "less":
		less_count += 1
		var new_less = less.instantiate()
		new_less.name = "Less" + str(less_count)
		less_group.add_child(new_less)

	elif feature_type == "equal":
		equal_count += 1
		var new_equal = equal.instantiate()
		new_equal.name = "Equal" + str(equal_count)
		equal_group.add_child(new_equal)

	elif feature_type == "has_garment":
		has_garment_count += 1
		var new_has_garment = has_garment.instantiate()
		new_has_garment.name = "HasGarment" + str(has_garment_count)
		has_garment_group.add_child(new_has_garment)


func _on_option_button_item_selected(index):
	if index == 0:
		variables_group.show()
		_on_add_button_pressed("variable")
		
	elif index == 1: 
		emit_signal_group.show()
		_on_add_button_pressed("signal")
		
	elif index == 2:
		conditionals_group.show()
		_on_add_button_pressed("conditional")

	elif index == 3:
		greater_group.show()
		_on_add_button_pressed("greater")

	elif index == 4:
		less_group.show()
		_on_add_button_pressed("less")

	elif index == 5:
		equal_group.show()
		_on_add_button_pressed("equal")

	elif index == 6:
		has_garment_group.show()
		_on_add_button_pressed("has_garment")


func _on_close_request():
	# Delegate node removal to parent as its the orchestrator
	get_parent().remove_node(self)
	
	
func _on_dragged(from, to):
	position_offset = to
	
func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize
