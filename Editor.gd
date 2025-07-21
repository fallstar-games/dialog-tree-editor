extends GraphEdit

# Get nodes
var last_instanced_node_pos = Vector2(0,0)
var last_mouse_pos = Vector2(0,0)
@onready var saved_notification = $Tool/SavedNotification
@onready var spawn_sound = $SpawnSound
var rng = RandomNumberGenerator.new()


# Keep Count
var total_node_count = 0
var end_count = 0
var new_nodes_position_offset = Vector2(450,0)


# Data
var dialog = {}
var node_stack:Dictionary = {
	"DIALOG":  { "nodes": [], "last_index": 0, "res": load("res://GraphNode.tscn") },
	"APPEND": { "nodes": [], "last_index": 0, "res": load("res://AppendNode.tscn") },
	"LOGIC": { "nodes": [], "last_index": 0, "res": load("res://Feature.tscn") },
	"CHOICE":  { "nodes": [], "last_index": 0, "res": load("res://Option.tscn") },
	"IMAGE":  { "nodes": [], "last_index": 0, "res": load("res://ImageNode.tscn") },
	"EVENT":  { "nodes": [], "last_index": 0, "res": load("res://EventNode.tscn") },
	"OFFRAMP":  { "nodes": [], "last_index": 0, "res": load("res://Offramp.tscn") },
	"ONRAMP":  { "nodes": [], "last_index": 0, "res": load("res://Onramp.tscn") },
	"TRANSITION":  { "nodes": [], "last_index": 0, "res": load("res://Transition.tscn") }
}

# Signals
signal graph_cleared
signal node_closed

var selected_file_path:String
func _ready():
	if get_node("CanvasLayer/OpenFileDialog").is_connected("file_selected", _on_file_dialog_file_selected):
#		get_node("CanvasLayer/OpenFileDialog").disconnect("file_selected", _on_file_dialog_file_selected)
		print("Signal: file_selected - This signal is only used to set the path")
	get_node("CanvasLayer/OpenFileDialog").connect("confirmed", _on_file_dialog_load_file)
	Global.connect("close_menu", _close_menu)

################## Shortcut Keys ####################################
	
func _input(event):
	# Get actaul position = (mouse position in window + moved canvas position) scaled 
	var mouse_position_in_canvas = (get_global_mouse_position() + scroll_offset)/zoom
	if Input.is_action_just_released("New Node"):
		last_mouse_pos = mouse_position_in_canvas - new_nodes_position_offset
		_on_new_node_pressed()
	elif Input.is_action_just_released("Return to Start"):
		scroll_offset = Vector2(-200, -40)
	elif Input.is_action_just_released("Go to End"):
		if has_node("End"):
			var end = $End
			var pos_x = end.position.x
			pos_x = pos_x * -1
			var pos_y = end.position.y
			pos_y = pos_y * -0.02
			scroll_offset = Vector2(pos_x, pos_y)
	elif Input.is_action_just_released("New File"):
		_on_new_pressed()
	elif Input.is_action_just_released("New Feature"):
		last_mouse_pos = mouse_position_in_canvas - new_nodes_position_offset
		_on_new_feature_pressed()
	elif Input.is_action_just_released("Open"):
		$CanvasLayer/OpenFileDialog.show()
	elif Input.is_action_just_released("Save"):
		if Global.if_file_exists(get_window().title) == false:
			_on_save_as_pressed()
		else:
			save_file_dialog.file_path = get_window().title
			save_file_dialog._on_save_pressed(true)
			saved_notification.get_node("AnimationPlayer").play("FadeOut")


func random_number():
	return rng.randf_range(1, 1.5)

################## Life cycle methods  ####################################
# Called when a node is either created or removed
func update_node_count():
	var node_count = 0
	#var single_node = null

	for key in node_stack.keys():
		var type_node_count = len(node_stack[ key ].nodes)
		#print(key + " node count is " + str(type_node_count))
		node_count = node_count + type_node_count

		#if type_node_count == 1:
		#	single_node = node_stack[ key ].nodes[0].get_name()

	total_node_count = node_count

	# single_node is implicit by count but still good practice to declare in statement
	#if total_node_count == 1 and single_node:
		#print("auto connected start")
		#auto_connect_start(single_node)

# General method to create nodes (DIALOG | FEATURE | OPTION) - see: var node_stack
# + accepts a name as passive, generates a new name if empty
func get_new_node(type:String, _node_name:String = ""):
	var new_node = node_stack[type].res.instantiate()
	node_stack[ type ].last_index = node_stack[ type ].last_index + 1

	var new_name = type + "_" +str(node_stack[ type ].last_index).pad_zeros(3)

	while node_already_exists(type, new_name):
		node_stack[ type ].last_index = node_stack[ type ].last_index + 1
		new_name = type + "_" +str(node_stack[ type ].last_index).pad_zeros(3)

	if _node_name != "":
		new_name = _node_name

	new_node.title =  new_name
	new_node.name = new_name
	new_node.node_data["node title"] =  new_name
	node_stack[ type ].nodes.push_back(new_node)

	if last_mouse_pos != Vector2(0,0): # Set mouse position as origin if event was a click
		last_instanced_node_pos = last_mouse_pos
		last_mouse_pos = Vector2(0,0) # Unset mouse position
	else: # Recreate bounds if the event comes from a button
		var bounds:Vector2 = Vector2(0, 0)
		for key in node_stack.keys():
			for node in node_stack[ key ].nodes:
				if node.position_offset.x > bounds.x:
					bounds.x = node.position_offset.x
				if node.position_offset.y > bounds.y:
					bounds.y = node.position_offset.y
		last_instanced_node_pos = bounds

	add_child(new_node)
	update_node_count()

	return new_node

func node_already_exists(type:String, _name:String):
	# Check if node already exists
	if node_stack.has(type):
		for node in node_stack[ type ].nodes:
			if node.get_name() == _name:
				return true
	return false

# Called from child only, passes itself and lets GraphEdit handle the removal
# For future reference _on_close_request(): get_parent().remove_node(self)
func remove_node(node:Node):
	var type = node.get_name().split("_")[0]
	if node_stack.has(type):
		var index = node_stack[ type ].nodes.find(node)

		if index == -1:
			push_error("Node not found on stack (" + str(node.get_path()) + ")")
		else:
			node_stack[ type ].nodes.remove_at(index)
			print("Node removed from stack (" + str(node.get_path()) + ")")

			var node_name = node.get_name()

			for connection in get_connection_list():
				if connection.from == node_name or connection.to == node_name:
					disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)
			node.queue_free()
			update_node_count()
	else:
		push_error("Node type not found (" + type + ")")

	for _node in node_stack["TRANSITION"].nodes:
		print("Transition node: " + _node.get_name())

################## Creating a new node ####################################
func _on_new_node_pressed(open_save : bool = false):
	
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_node = get_new_node("DIALOG")

	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_node.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new feature ####################################
func _on_new_feature_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()
	
	var new_feature = get_new_node("LOGIC")
	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_feature.position_offset = last_instanced_node_pos + new_nodes_position_offset 

################## Creating a new option ####################################
func _on_new_option_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_option = get_new_node("CHOICE")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_option.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new image ####################################
func _on_new_image_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_image = get_new_node("IMAGE")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_image.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new append ####################################
func _on_new_append_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_append = get_new_node("APPEND")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_append.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new event node ####################################
func _on_new_event_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_option = get_new_node("EVENT")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_option.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new offramp ####################################
func _on_new_offramp_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_option = get_new_node("OFFRAMP")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_option.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new onramp ####################################
func _on_new_onramp_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_option = get_new_node("ONRAMP")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_option.position_offset = last_instanced_node_pos + new_nodes_position_offset

################## Creating a new transition ####################################
func _on_new_transition_pressed(open_save : bool = false):
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	var new_option = get_new_node("TRANSITION")

	
	if not open_save:
		if last_instanced_node_pos == Vector2(0,0):
			last_instanced_node_pos = $Start.position_offset
		new_option.position_offset = last_instanced_node_pos + new_nodes_position_offset
 
################## Ending the dialog ####################################
func _on_end_node_pressed():
	if end_count == 0: 
		
		end_count += 1
		
		spawn_sound.pitch_scale = random_number()
		spawn_sound.play()
		
		var end_node = load("res://End.tscn")
		end_node = end_node.instantiate()
		add_child(end_node)
		
		end_node.position_offset = last_instanced_node_pos + new_nodes_position_offset
		
		last_instanced_node_pos = end_node.position_offset


################## Open file ####################################
	
func _on_file_dialog_file_selected(path):
	selected_file_path = path

func _on_file_dialog_load_file():
	# Change window title
	get_window().title = selected_file_path.get_file().replace(".json", "")
	# Make sure the listener runs before the emitter
	_on_file_dialog_load_file_async() # Start the async function waiting for the signal
	clear_all() # Run the function that emits the signal expected
	
func _on_file_dialog_load_file_async():
	await self.graph_cleared
	# Hide Option Panel
	menu_panel.hide()
	
	# Parse JSON to *dialog* dictionary in scene tree
	var file = FileAccess.open(selected_file_path,FileAccess.READ)
	#var first_dialog_node = ""
	dialog = JSON.parse_string(file.get_as_text())
	
	
	# Assign nodes into/with correct positions and values
	# Nodes (incl. start & end nodes)
	
	# Create nodes before connecting them to avoid lost references
	for node_name in dialog:
		var type = node_name.split("_")[0]
		if type and node_stack.has(type):
			var new_node = get_new_node(type, node_name)
			var node_data_keys = dialog[ node_name ].keys()
			# reassign node"s data
			for key in node_data_keys:
				new_node.node_data[ key ] = dialog[ node_name ][ key ]
			# pass to object for next loop quick reference
			dialog[ node_name ].res = new_node

	for node_name in dialog:
		var node = dialog[node_name]
		
		# if type: node
		if "DIALOG" in node["node title"]:
			var current_node = dialog[ node_name ].res
			
			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]
			
			current_node.text.text = node["text"]
			current_node.character_opt.select(node["speaker"])
			current_node.change_speaker_mode(int(node["speaker"]))


			if node.has("image_type"):
				if node["image_type"] == "no_change":
					current_node.image_type_dropdown.select(0) # Select "No Image" if image type is empty
					current_node.change_image_type_mode(0)
				else:
					var found = false
					for i in range(current_node.image_type_dropdown.get_item_count()):
						if current_node.image_type_dropdown.get_item_text(i) == node["image_type"]:
							current_node.image_type_dropdown.select(i)
							current_node.change_image_type_mode(i)
							found = true
							break
					if not found:
						push_error("Image type not found: " + node["image_type"])

			if node.has("expression_eyes"):
				if node["expression_eyes"] == "no_change":
					current_node.eyes_opt.select(0) # Select "None" if eyes is empty
				else:
					var found = false
					for i in range(current_node.eyes_opt.get_item_count()):
						if current_node.eyes_opt.get_item_text(i) == node["expression_eyes"]:
							current_node.eyes_opt.select(i)
							found = true
							break
					if not found:
						push_error("Image eyes not found: " + node["expression_eyes"])

			if node.has("expression_mouth"):
				if node["expression_mouth"] == "no_change":
					current_node.mouth_opt.select(0) # Select "None" if mouth is empty
				else:
					var found = false
					for i in range(current_node.mouth_opt.get_item_count()):
						if current_node.mouth_opt.get_item_text(i) == node["expression_mouth"]:
							current_node.mouth_opt.select(i)
							found = true
							break
					if not found:
						push_error("Image mouth not found: " + node["expression_mouth"])

			#Set pose_dropdown to the index with the same name as node["pose"]
			if node.has("paperdoll_pose"):
				if node["paperdoll_pose"] == "no_change":
					current_node.pose_dropdown.select(0) # Select "None" if pose is empty
				else:
					var found = false
					for i in range(current_node.pose_dropdown.get_item_count()):
						if current_node.pose_dropdown.get_item_text(i) == node["paperdoll_pose"]:
							current_node.pose_dropdown.select(i)
							found = true
							break
					if not found:
						push_error("Image pose not found: " + node["paperdoll_pose"])

			if node.has("framing"):
				# Set framing_dropdown to the index with the same name as node["framing"]
				if node["framing"] == "no_change":
					current_node.framing_dropdown.select(0) # Select "None" if framing is empty
				else:
					var found = false
					for i in range(current_node.framing_dropdown.get_item_count()):
						if current_node.framing_dropdown.get_item_text(i) == node["framing"]:
							current_node.framing_dropdown.select(i)
							found = true
							break
					if not found:
						push_error("Image framing not found: " + node["framing"])

			if node.has("solo_pose"):
				var found = false
				for i in range(current_node.solo_dropdown.get_item_count()):
					if current_node.solo_dropdown.get_item_text(i) == node["solo_pose"]:
						current_node.solo_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image solo pose not found: " + node["solo_pose"])

			if node.has("duo_pose"):
				var found = false
				for i in range(current_node.duo_dropdown.get_item_count()):
					if current_node.duo_dropdown.get_item_text(i) == node["duo_pose"]:
						current_node.duo_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image duo pose not found: " + node["duo_pose"])

		# if type: append
		elif "APPEND" in node["node title"]:
			var current_node = dialog[ node_name ].res
			
			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]
			
			current_node.text.text = node["text"]
			
		# if type: feature	
		elif "LOGIC" in node["node title"]:
			var current_node = dialog[ node_name ].res
			
			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]

			current_node.main_person_line.text = node["main_person_id"]
			current_node.second_person_line.text = node["second_person_id"]
			current_node.option_button.select(node["opt_index"])
			current_node._on_option_button_item_selected(node["opt_index"])
			
			# variable
			if not node["set_variables"].is_empty():
				var variables_group = current_node.get_node("VariablesGroup")
				variables_group.show()
				
				var variable_index = 0
				for variable_set in node["set_variables"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if variable_index > 0:
						current_node._on_add_button_pressed("variable")
					
					var current_variable_count = current_node.variable_count
					var variable_node_name = "Variable" + str(current_variable_count - variable_index)
					var variable_node = variables_group.get_node(variable_node_name)
					variable_node.text.text = node["set_variables"].keys()[variable_index]
					variable_node.check_button.button_pressed = node["set_variables"].values()[variable_index]
					variable_index += 1
			
			# signals
			if not node["signals"].is_empty():
				var emit_signal_group = current_node.get_node("EmitSignalGroup")
				emit_signal_group.show()
				
				var signal_index = 0
				for single_signal in node["signals"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if signal_index > 0:
						current_node._on_add_button_pressed("signal")
					
					var current_signal_count = current_node.signal_count
					var signal_node_name = "Signal" + str(current_signal_count - signal_index)
					var signal_node = emit_signal_group.get_node(signal_node_name)
					signal_node.text.text = node["signals"][signal_index]
					signal_index += 1
			
			# boolean conditionals
			if not node["if_boolean"].is_empty():

				var conditionals_group = current_node.get_node("ConditionalsGroup")
				conditionals_group.show()
				
				var conditional_index = 0
				for conditional in node["if_boolean"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if conditional_index > 0:
						current_node._on_add_button_pressed("conditional")
					
					var current_conditional_count = current_node.conditional_count
					var conditional_node_name = "Conditional" + str(current_conditional_count - conditional_index)
					var conditional_node = conditionals_group.get_node(conditional_node_name)
					print("Conditional node name: " + conditional_node_name + ". Conditional Count: " + str(current_conditional_count))
					conditional_node.text.text = node["if_boolean"].keys()[conditional_index]
					conditional_node.check_button.button_pressed = node["if_boolean"].values()[conditional_index]
					conditional_index += 1

			# greater than conditionals
			if not node["if_greater"].is_empty():
				var greater_group = current_node.get_node("GreaterGroup")
				greater_group.show()
				
				var greater_index = 0
				for greater in node["if_greater"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if greater_index > 0:
						current_node._on_add_button_pressed("greater")
					
					var current_greater_count = current_node.greater_count
					var greater_node_name = "Greater" + str(current_greater_count - greater_index)
					var greater_node = greater_group.get_node(greater_node_name)
					greater_node.var_name.text = node["if_greater"].keys()[greater_index]
					greater_node.var_amount.text = node["if_greater"].values()[greater_index]
					greater_index += 1
			
			# less than conditionals
			if not node["if_less"].is_empty():
				var less_group = current_node.get_node("LessGroup")
				less_group.show()
				
				var less_index = 0
				for less in node["if_less"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if less_index > 0:
						current_node._on_add_button_pressed("less")
					
					var current_less_count = current_node.less_count
					var less_node_name = "Less" + str(current_less_count - less_index)
					var less_node = less_group.get_node(less_node_name)
					less_node.var_name.text = node["if_less"].keys()[less_index]
					less_node.var_amount.text = node["if_less"].values()[less_index]
					less_index += 1

			# equal to conditionals
			if not node["if_equal"].is_empty():
				var equal_group = current_node.get_node("EqualGroup")
				equal_group.show()
				
				var equal_index = 0
				for equal in node["if_equal"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if equal_index > 0:
						current_node._on_add_button_pressed("equal")
					
					var current_equal_count = current_node.equal_count
					var equal_node_name = "Equal" + str(current_equal_count - equal_index)
					var equal_node = equal_group.get_node(equal_node_name)
					equal_node.var_name.text = node["if_equal"].keys()[equal_index]
					equal_node.var_amount.text = node["if_equal"].values()[equal_index]
					equal_index += 1

			# has garment conditionals
			if not node["has_garment"].is_empty():
				var has_garment_group = current_node.get_node("HasGarmentGroup")
				has_garment_group.show()
				
				var garment_index = 0
				for garment in node["has_garment"]:
					# Skip first iteration since _on_option_button_item_selected already added one
					if garment_index > 0:
						current_node._on_add_button_pressed("has_garment")
					
					var current_has_garment_count = current_node.has_garment_count
					var has_garment_node_name = "HasGarment" + str(current_has_garment_count - garment_index)
					var has_garment_node = has_garment_group.get_node(has_garment_node_name)
					has_garment_node.text.text = node["has_garment"].keys()[garment_index]
					has_garment_node.check_button.button_pressed = node["has_garment"].values()[garment_index]
					garment_index += 1
			
		# if type: option
		elif "CHOICE" in node["node title"]:
			#_on_new_option_pressed(true)
			#print("option spawned at bottom of load function")
			var current_node = dialog[ node_name ].res

			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]
			current_node.text.text = node["text"]
			"""
			# match item string to item index
			for item in current_node.dice_roll_dropdown.get_item_count():
					
				if current_node.dice_roll_dropdown.get_item_text(item) == node["dice_roll"]:

					current_node.dice_roll_dropdown.select(item)
					current_node.dice_roll_on()
					
					break

			current_node.roll_difficulty.text = str(node["difficulty"])
			"""

		# if type: event
		elif "EVENT" in node["node title"]:
			var current_node = dialog[ node_name ].res

			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]

			var found = false
			for i in range(current_node.event_dropdown.get_item_count()):
				if current_node.event_dropdown.get_item_text(i) == node["event_type"]:
					current_node.event_dropdown.select(i)
					current_node.change_mode(i)
					found = true
					break
			if not found:
				push_error("Event type not found: " + node["event_type"])

			found = false
			for i in range(current_node.check_type_dropdown.get_item_count()):
				if current_node.check_type_dropdown.get_item_text(i) == node["check_type"]:
					current_node.check_type_dropdown.select(i)
					current_node.change_check_mode(i)
					found = true
					break
			if not found:
				push_error("Check type not found: " + node["check_type"])

			found = false
			for i in range(current_node.wardrobe_action_dropdown.get_item_count()):
				if current_node.wardrobe_action_dropdown.get_item_text(i) == node["wardrobe_action"]:
					current_node.wardrobe_action_dropdown.select(i)
					current_node.change_wardrobe_mode(i)
					found = true
					break
			if not found:
				push_error("Wardrobe action not found: " + node["wardrobe_action"])

			match node["event_type"]:
				"CHECK":
					match node["check_type"]:
						"REQUEST":
							current_node.line_edits["request_id"].text = node["request_id"]
							current_node.line_edits["request_pass"].text = node["outcome_pass"]
							current_node.line_edits["request_fail"].text = node["outcome_fail"]
							current_node.line_edits["request_unsure"].text = node["outcome_unsure"]
						"COERCE":
							current_node.line_edits["lever_id"].text = node["lever_id"]
							current_node.line_edits["coerce_pass"].text = node["outcome_pass"]
							current_node.line_edits["coerce_fail"].text = node["outcome_fail"]
						"FORCE":
							current_node.line_edits["force_pass"].text = node["outcome_pass"]
							current_node.line_edits["force_fail"].text = node["outcome_fail"]
				"SUBTREE":
					current_node.line_edits["subtree_id"].text = node["subtree_id"]
					current_node.line_edits["subtree_start"].text = node["subtree_start"]
					if not node["subtree_outputs"].is_empty():
						for output_name in node["subtree_outputs"]:
							current_node._on_add_output_button_pressed("subtree")
							var current_output_count = current_node.output_subtree_count
							var output_node_name = "OutputSubtree" + str(current_output_count)
							var output_node = current_node.event_containers["SUBTREE"].get_node(output_node_name)
							if output_node == null:
								print("Output node not found: " + output_node_name)
								continue
							output_node.outcome_name.text = node["subtree_outputs"].keys()[current_output_count - 1]
							output_node.target_node.text = node["subtree_outputs"].values()[current_output_count - 1]
				"CYCLER":
					current_node.line_edits["cycle_id"].text = node["cycle_id"]
					
					if not node["cycler_outputs"].is_empty():
						for target_key in node["cycler_outputs"]:
							current_node._on_add_output_button_pressed("cycler")
							var current_output_count = current_node.output_cycler_count
							var output_node_name = "OutputCycler" + str(current_output_count)
							var output_node = current_node.event_containers["CYCLER"].get_node(output_node_name)

							#output_node.var_amount.text = cycle_index
							output_node.var_name.text = target_key
					
				"RANDOM":
					if not node["random_outputs"].is_empty():
						for target_node in node["random_outputs"]:
							current_node._on_add_output_button_pressed("random")
							var current_output_count = current_node.output_random_count
							var output_node_name = "OutputRandom" + str(current_output_count)
							var output_node = current_node.event_containers["RANDOM"].get_node(output_node_name)

							output_node.var_amount.text = str(node["random_outputs"][target_node])
							output_node.var_name.text = target_node
				"WARDROBE":
					match node["wardrobe_action"]:
						"WEAR_GARMENT":
							current_node.line_edits["garment_id"].text = node["garment_id"]
						"REMOVE_GARMENT":
							current_node.line_edits["garment_slot_id"].text = node["garment_slot_id"]
						"WEAR_OUTFIT":
							current_node.line_edits["outfit_id"].text = node["outfit_id"]
						"SAVE_OUTFIT":
							current_node.line_edits["outfit_id"].text = node["outfit_id"]


		# if type: image
		elif "IMAGE" in node["node title"]:
			var current_node = dialog[ node_name ].res

			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]

			#set slot_dropdown to the index with the same name as node["image_slot"]
			var found = false
			for i in range(current_node.slot_dropdown.get_item_count()):
				if current_node.slot_dropdown.get_item_text(i) == node["image_slot"]:
					current_node.slot_dropdown.select(i)
					current_node.change_slot_mode(i)
					found = true
					break
			if not found:
				push_error("Image slot not found: " + node["image_slot"])

			#Set set_hide_dropdown to the index with the same name as node["image_action"]
			found = false
			for i in range(current_node.set_hide_dropdown.get_item_count()):
				if current_node.set_hide_dropdown.get_item_text(i) == node["image_action"]:
					current_node.set_hide_dropdown.select(i)
					current_node.change_set_hide_mode(i)
					found = true
					break
			if not found:
				push_error("Image action not found: " + node["image_action"])

			#Set target_dropdown to the index with the same name as node["image_target"]
			found = false
			for i in range(current_node.target_dropdown.get_item_count()):
				if current_node.target_dropdown.get_item_text(i) == node["image_target"]:
					current_node.target_dropdown.select(i)
					current_node.change_target_mode(i)
					found = true
					break
			if not found:
				push_error("Image target not found: " + node["image_target"])
			
			#Set person_main_mode_dropdown to the index with the same name as node["image_person_main_mode"]
			if node.has("image_person_main_mode"):
				found = false
				for i in range(current_node.person_main_mode_dropdown.get_item_count()):
					if current_node.person_main_mode_dropdown.get_item_text(i) == node["image_person_main_mode"]:
						current_node.person_main_mode_dropdown.select(i)
						current_node.change_person_main_mode(i)
						found = true
						break
				if not found:
					push_error("Image person main mode not found: " + node["image_person_main_mode"])
			
			#current_node.expression_eyes_dropdown.select(node["expression_eyes"])
			if node["expression_eyes"] == "no_change":
				current_node.expression_eyes_dropdown.select(0) # Select "None" if eyes is empty
			else:
				found = false
				var eyes_str = str(node["expression_eyes"])
				for i in range(current_node.expression_eyes_dropdown.get_item_count()):
					if current_node.expression_eyes_dropdown.get_item_text(i) == eyes_str:
						current_node.expression_eyes_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image expression eyes not found: " + eyes_str)

			#current_node.expression_mouth_dropdown.select(node["expression_mouth"])
			if node["expression_mouth"] == "no_change":
				current_node.expression_mouth_dropdown.select(0) # Select "None" if mouth is empty
			else:
				found = false
				var mouth_str = str(node["expression_mouth"])
				for i in range(current_node.expression_mouth_dropdown.get_item_count()):
					if current_node.expression_mouth_dropdown.get_item_text(i) == mouth_str:
						current_node.expression_mouth_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image expression mouth not found: " + mouth_str)

			#Set paperdoll_pose_dropdown to the index with the same name as node["paperdoll_pose"]
			if node["paperdoll_pose"] == "no_change":
				current_node.paperdoll_pose_dropdown.select(0) # Select "None" if pose is empty
			else:
				found = false
				if node.has("paperdoll_pose"):
					for i in range(current_node.paperdoll_pose_dropdown.get_item_count()):
						if current_node.paperdoll_pose_dropdown.get_item_text(i) == node["paperdoll_pose"]:
							current_node.paperdoll_pose_dropdown.select(i)
							found = true
							break
					if not found:
						push_error("Image pose not found: " + node["paperdoll_pose"])

			#Set solo_pose_dropdown to the index with the same name as node["solo_pose"]
			found = false
			if node.has("solo_pose"):
				for i in range(current_node.solo_pose_dropdown.get_item_count()):
					if current_node.solo_pose_dropdown.get_item_text(i) == node["solo_pose"]:
						current_node.solo_pose_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image solo pose not found: " + node["solo_pose"])

			#Set duo_pose_dropdown to the index with the same name as node["duo_pose"]
			found = false
			if node.has("duo_pose"):
				for i in range(current_node.duo_pose_dropdown.get_item_count()):
					if current_node.duo_pose_dropdown.get_item_text(i) == node["duo_pose"]:
						current_node.duo_pose_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image duo pose not found: " + node["duo_pose"])

			#Set framing_dropdown to the index with the same name as node["framing"]
			if node["framing"] == "no_change":
				current_node.framing_dropdown.select(0) # Select "None" if framing is empty
			else:
				found = false
				for i in range(current_node.framing_dropdown.get_item_count()):
					if current_node.framing_dropdown.get_item_text(i) == node["framing"]:
						current_node.framing_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image framing not found: " + node["framing"])

			if node.has("person_image_id"):
				current_node.person_image_id_line.text = node["person_image_id"]
			if node.has("other_image_id"):
				current_node.other_image_id_line.text = node["other_image_id"]

			#set effect_dropdown to the index with the same name as node["effect"]
			found = false
			if node.has("effect"):
				for i in range(current_node.effect_dropdown.get_item_count()):
					if current_node.effect_dropdown.get_item_text(i) == node["effect"]:
						current_node.effect_dropdown.select(i)
						found = true
						break
				if not found:
					push_error("Image effect not found: " + node["effect"])

		# if type: offramp
		elif "OFFRAMP" in node["node title"]:
			var current_node = dialog[ node_name ].res

			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]

			match node["dest_type"]:
				"SAME_TREE":
					current_node.destination_dropdown.select(0)
					current_node.change_mode(0)
					#current_node.title_line.text = node["dest_node"]
					current_node.outcome_line.text = node["dest_outcome"]
				"OUTSIDE_TREE":
					current_node.destination_dropdown.select(1)
					current_node.change_mode(1)
					current_node.file_line.text = node["dest_node"]
					current_node.outcome_line.text = node["dest_outcome"]
				"TERMINATE":
					current_node.destination_dropdown.select(2)
					current_node.change_mode(2)
					current_node.outcome_line.text = node["dest_outcome"]

		# if type: onramp
		elif "ONRAMP" in node["node title"]:
			var current_node = dialog[ node_name ].res

			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]

			current_node.key_line.text = node["string_key"]

		# if type: transition
		elif "TRANSITION" in node["node title"]:
			var current_node = dialog[ node_name ].res

			current_node.position_offset.x = node["offset_x"]
			current_node.position_offset.y = node["offset_y"]
			
			current_node.locale_line.text = node["room_id"]
			if "fade_time" in node:
				current_node.fade_line.text = str(node["fade_time"])
			if "wait_time" in node:
				current_node.wait_line.text = str(node["wait_time"])
			current_node.main_person_line.text = node["main_person_id"]
			current_node.second_person_line.text = node["second_person_id"]
			current_node.show_hide_person_2()
			#current_node.person_opt.select(node["person_type"])
			#current_node.focus_opt.select(node["focus_change"])
		
		# Link Connections
		if "End" in node["go to"]:
			_on_end_node_pressed()
			connect_node(node["node title"], 0, "End", 0)
		else:
			for to in node["go to"]:
				connect_node(node["node title"], 0, to, 0)

	#finally, connect the first dialog node to start
	#if first_dialog_node != "":
		#auto_connect_start(first_dialog_node)
		
	
################## Save a file ####################################

# Compile data to be saved
func compile_nodes_into_json():

	#first clear the dialog dict
	dialog = {}
	
	var existing_nodes = get_tree().get_nodes_in_group("graph_nodes")
	
	for node in existing_nodes:

		#remove connections to nodes that don't exist
		if node["node_data"]["go to"].size() > 0:
			for connection in node["node_data"]["go to"]:
				if not has_node(connection):
					node["node_data"]["go to"].erase(connection)

		node.update_data()
		
		dialog[node.node_data["node title"]] = node.node_data
		#var dialog_block = dialog[node.node_data["node title"]]
		
	print(dialog)
		
	return dialog
	

################## Menu/Navigation ####################################

# Get nodes
@onready var menu_list = $CanvasLayer/Panel/MenuList
@onready var options_list = $CanvasLayer/Panel/Options
@onready var new_file_dialog = $CanvasLayer/NewFileDialog
@onready var save_file_dialog = $CanvasLayer/SaveFileDialog
@onready var open_file_dialog = $CanvasLayer/OpenFileDialog
@onready var menu_cancel_button = $CanvasLayer/Panel/CancelButton
@onready var menu_panel = $CanvasLayer/Panel
@onready var back_button = $CanvasLayer/Panel/BackButton
@onready var save_button = $CanvasLayer/Panel/MenuList/Save

# Data
var new_font_size = Global.font_size
var new_type_sound = Global.type_sound

func _on_menu_pressed():
	menu_panel.show()
		
	# Disable SAVE if file does not exist
	if Global.if_file_exists(get_window().title):
		save_button.disabled = false
	else:
		save_button.disabled = true

	
func _on_cancel_button_pressed():
	menu_panel.hide()

func _on_save_as_pressed():
	save_file_dialog.show()

func _on_open_pressed():
	open_file_dialog.show()

func _on_options_pressed():
	menu_list.hide()
	options_list.show()
	back_button.show()
	menu_cancel_button.hide()

func _on_options_cancel_pressed():
	menu_list.show()
	options_list.hide()
	back_button.hide()
	menu_cancel_button.show()

func _on_save_pressed():
	menu_panel.hide()
	save_file_dialog.file_path = get_window().title
	save_file_dialog._on_save_pressed(true)
	saved_notification.get_node("AnimationPlayer").play("FadeOut")

func _on_options_save_pressed():
	Global.font_size = new_font_size
	Global.type_sound = new_type_sound
	_on_options_cancel_pressed()

func _on_font_size_pressed(font_size):
	new_font_size = font_size

func _on_type_sound_pressed(index):
	new_type_sound = index
	
func _on_new_pressed():
	new_file_dialog.show()

func _on_quit_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()



################## Connecting Nodes ####################################
func _on_connection_request(from_node, from_port, to_node, to_port):
	connect_node(from_node, from_port, to_node, to_port)
	#if from_node != "Start":
	get_node(str(from_node)).node_data["go to"].append(str(to_node))

func _on_disconnection_request(from_node, from_port, to_node, to_port):
	disconnect_node(from_node, from_port, to_node, to_port)
	#if get_node(str(from_node)).node_data["go to"].has(str(to_node)):
	#	print("the thing is there to erase")
	#if from_node != "Start":
	get_node(str(from_node)).node_data["go to"].erase(str(to_node))

func clear_all():
	clear_connections()
	for type in node_stack.keys():
		for node in node_stack[type].nodes:
			node.queue_free()
		node_stack[ type ].last_index = 0
		node_stack[type].nodes = []
	if has_node("End"):
		get_node("End").queue_free()
		end_count = 0
	await get_tree().create_timer(0.05).timeout
	total_node_count = 0
	graph_cleared.emit()

func _close_menu():
	menu_panel.hide()

#func auto_connect_start(node):
	#connect_node("Start", 0, node, 0)

var utilities_path = "C:\\Users\\John\\Alexis' Team Dropbox\\Alexis Austin\\Bespoke\\working\\Godot\\Projects\\HaremHeavenExcel\\json2xl-utilities-5-18"

func _on_open_utilities_pressed():
	OS.shell_open(utilities_path)
