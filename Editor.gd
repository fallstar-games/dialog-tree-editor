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

# Unsaved changes tracking
# Snapshot of the graph as it was at the last save/load/new. Compared against a
# fresh compile to decide whether the user has anything to lose.
var _clean_snapshot:String = ""
# Action waiting on the unsaved-changes prompt: "" | "quit" | "open"
var _pending_action:String = ""
# Action waiting on a Save As to finish (same values as _pending_action)
var _action_after_save:String = ""
# Set once quitting is committed, so the close notification isn't re-prompted
var _quitting:bool = false

# Helper function to set option button selection by matching text
func set_option_button_by_text(option_button: OptionButton, target_value: String, error_prefix: String = "Option") -> bool:
	var found = false
	for i in range(option_button.get_item_count()):
		if option_button.get_item_text(i) == target_value:
			option_button.select(i)
			found = true
			break
	if not found:
		push_error(error_prefix + " not found: " + target_value)
		#just set the value to whatever the first option is
		option_button.select(0)
	return found

func _ready():
	if get_node("CanvasLayer/OpenFileDialog").is_connected("file_selected", _on_file_dialog_file_selected):
#		get_node("CanvasLayer/OpenFileDialog").disconnect("file_selected", _on_file_dialog_file_selected)
		print("Signal: file_selected - This signal is only used to set the path")
	get_node("CanvasLayer/OpenFileDialog").connect("confirmed", _on_file_dialog_load_file)
	get_node("CanvasLayer/OpenFileDialog").access = FileDialog.ACCESS_FILESYSTEM
	get_node("CanvasLayer/OpenFileDialog").current_dir = Global.get_save_dir()
	Global.connect("close_menu", _close_menu)
	Global.connect("file_saved", _on_global_file_saved)
	# Handle the window's X button ourselves so unsaved work can be defended
	get_tree().auto_accept_quit = false
	# Ensure we have an action to close all selected nodes at once
	_ensure_close_selected_action()
	# Ensure we have a cut action (Ctrl/Cmd+X) that copies then deletes
	_ensure_cut_nodes_action()
	# Ensure arrow key pan actions exist
	_ensure_pan_actions()
	# Baseline an empty editor as "clean"
	_mark_clean()

# Fired by the window manager when the user clicks the X button. Only reaches us
# because _ready() disabled auto_accept_quit.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

################## Shortcut Keys ####################################
	
func _input(_event):
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
		request_open()
	elif Input.is_action_just_released("Save"):
		if Global.if_file_exists(get_window().title) == false:
			_on_save_as_pressed()
		else:
			save_file_dialog.file_path = get_window().title
			save_file_dialog._on_save_pressed(true)
			saved_notification.get_node("AnimationPlayer").play("FadeOut")
	elif Input.is_action_just_released("Duplicate Selected"):
		_duplicate_selected_nodes()
	elif Input.is_action_just_released("Copy Nodes"):
		_copy_selected_nodes_to_clipboard()
	elif Input.is_action_just_released("Paste Nodes"):
		_paste_nodes_from_clipboard(mouse_position_in_canvas)
	elif Input.is_action_just_released("Cut Nodes"):
		# Only act if not typing into a text field
		if not _is_text_input_focused():
			# Copy first, then delete
			_copy_selected_nodes_to_clipboard()
			_close_selected_nodes()
	elif Input.is_action_just_released("Close Selected"):
		# Require modifier (handled by InputMap) and ignore if typing
		if not _is_text_input_focused():
			_close_selected_nodes()
	# Arrow key panning (only when not typing in a text field)
	if not _is_text_input_focused():
		var pan_speed := 50.0
		if Input.is_action_pressed("Pan Left"):
			scroll_offset.x -= pan_speed
		if Input.is_action_pressed("Pan Right"):
			scroll_offset.x += pan_speed
		if Input.is_action_pressed("Pan Up"):
			scroll_offset.y -= pan_speed
		if Input.is_action_pressed("Pan Down"):
			scroll_offset.y += pan_speed


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

		if new_option.node_data.has("reaction_girl_resources") and not new_option.node_data["reaction_girl_resources"].is_empty():
			for resource_type in new_option.node_data["reaction_girl_resources"].keys():
				new_option._on_add_girl_resource_button_pressed()
				var current_count = new_option.girl_resource_reaction_count
				var resource_node_name = "GirlResourceLine" + str(current_count)
				var resource_node = new_option.event_containers["REACTION"].get_node("GirlResources").get_node(resource_node_name)
				if resource_node:
					set_option_button_by_text(resource_node.get_node("ResourceType"), str(resource_type))
					resource_node.get_node("ResourceAmount").text = str(new_option.node_data["reaction_girl_resources"][resource_type])

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
	# Change window title to the relative subpath (without .json) under the save directory
	var save_dir: String = Global.get_save_dir()
	var path_norm: String = String(selected_file_path).replace("\\", "/")
	var save_dir_norm: String = save_dir.replace("\\", "/")
	var rel: String = ""
	# Ensure trailing slash match when checking prefix
	var save_dir_with_sep: String = save_dir_norm
	if not save_dir_with_sep.ends_with("/"):
		save_dir_with_sep += "/"
	if path_norm.begins_with(save_dir_with_sep):
		rel = path_norm.substr(save_dir_with_sep.length())
	else:
		# Fallback: just use the filename (no folders)
		rel = path_norm.get_file()
	# Drop .json extension if present
	if rel.ends_with(".json"):
		rel = rel.substr(0, rel.length() - 5)
	# Normalize any accidental leading slashes
	while rel.begins_with("/"):
		rel = rel.substr(1)
	get_window().title = rel
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
		var node_data = dialog[node_name]
		var current_node = node_data.res
		
		_apply_node_data_to_node(current_node, node_data)
		
		# Link Connections
		if "End" in node_data["go to"]:
			_on_end_node_pressed()
			connect_node(node_data["node title"], 0, "End", 0)
		else:
			for to in node_data["go to"]:
				connect_node(node_data["node title"], 0, to, 0)

	#finally, connect the first dialog node to start
	#if first_dialog_node != "":
		#auto_connect_start(first_dialog_node)

	# Let any deferred UI work settle, then baseline the freshly loaded graph
	await get_tree().process_frame
	_mark_clean()


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
	request_open()

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
	request_quit()


################## Unsaved changes ####################################

# Get nodes
@onready var unsaved_dialog = $CanvasLayer/UnsavedChangesDialog
@onready var unsaved_message = $CanvasLayer/UnsavedChangesDialog/Message
@onready var unsaved_save_button = $CanvasLayer/UnsavedChangesDialog/Buttons/SaveAndContinue
@onready var unsaved_discard_button = $CanvasLayer/UnsavedChangesDialog/Buttons/Discard

# Record the current graph as the saved state. Callers that have just compiled
# can pass their dict to avoid a second pass over every node.
func _mark_clean(snapshot:Dictionary = {}):
	if snapshot.is_empty():
		snapshot = compile_nodes_into_json()
	_clean_snapshot = JSON.stringify(snapshot)

# True when the graph differs from the last save/load/new.
func has_unsaved_changes() -> bool:
	return JSON.stringify(compile_nodes_into_json()) != _clean_snapshot

# Show the confirmation panel for an action that would discard the graph
func _prompt_unsaved(action:String):
	_pending_action = action
	menu_panel.hide()
	if action == "open":
		unsaved_message.text = "You have unsaved changes in the current node graph.\n\nOpening another file will lose them."
		unsaved_save_button.text = "SAVE & OPEN"
		unsaved_discard_button.text = "OPEN ANYWAY"
	else:
		unsaved_message.text = "You have unsaved changes in the current node graph.\n\nIf you quit now, you will lose them."
		unsaved_save_button.text = "SAVE & QUIT"
		unsaved_discard_button.text = "QUIT ANYWAY"
	unsaved_dialog.show()

func _perform_pending_action():
	var action = _pending_action
	_pending_action = ""
	unsaved_dialog.hide()
	match action:
		"quit":
			_do_quit()
		"open":
			open_file_dialog.show()

func request_quit():
	if _quitting or not has_unsaved_changes():
		_do_quit()
	else:
		_prompt_unsaved("quit")

func _do_quit():
	_quitting = true
	get_tree().quit()

func request_open():
	if has_unsaved_changes():
		_prompt_unsaved("open")
	else:
		open_file_dialog.show()

func _on_unsaved_cancel_pressed():
	_pending_action = ""
	unsaved_dialog.hide()

func _on_unsaved_discard_pressed():
	_perform_pending_action()

func _on_unsaved_save_pressed():
	if Global.if_file_exists(get_window().title):
		# Known file - save straight over it and carry on
		save_file_dialog.file_path = get_window().title
		save_file_dialog._on_save_pressed(true)
		_perform_pending_action()
	else:
		# Never saved, so the user has to name it first. Resume once the save lands.
		_action_after_save = _pending_action
		_pending_action = ""
		unsaved_dialog.hide()
		save_file_dialog.show()

# Resume a quit/open that was waiting on a Save As to complete
func _on_global_file_saved():
	if _action_after_save == "":
		return
	_pending_action = _action_after_save
	_action_after_save = ""
	_perform_pending_action()



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

# Ensure the input action exists and is bound to useful defaults
func _ensure_close_selected_action():
	var action := "Close Selected"
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# Reset bindings to strictly Ctrl/Cmd + Delete
	var existing := InputMap.action_get_events(action)
	for ev in existing:
		InputMap.action_erase_event(action, ev)
	var del_event := InputEventKey.new()
	del_event.command_or_control_autoremap = true
	del_event.physical_keycode = KEY_DELETE
	InputMap.action_add_event(action, del_event)

# Ensure the cut action exists and is bound to Ctrl/Cmd+X
func _ensure_cut_nodes_action():
	var action := "Cut Nodes"
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var cut_event := InputEventKey.new()
		cut_event.command_or_control_autoremap = true
		cut_event.physical_keycode = KEY_X
		InputMap.action_add_event(action, cut_event)
	else:
		var events := InputMap.action_get_events(action)
		if events.is_empty():
			var cut_event2 := InputEventKey.new()
			cut_event2.command_or_control_autoremap = true
			cut_event2.physical_keycode = KEY_X
			InputMap.action_add_event(action, cut_event2)

# Ensure arrow key pan actions exist
func _ensure_pan_actions():
	var pan_actions := {
		"Pan Left": KEY_LEFT,
		"Pan Right": KEY_RIGHT,
		"Pan Up": KEY_UP,
		"Pan Down": KEY_DOWN
	}
	for action_name in pan_actions.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var events := InputMap.action_get_events(action_name)
		if events.is_empty():
			var key_event := InputEventKey.new()
			key_event.physical_keycode = pan_actions[action_name]
			InputMap.action_add_event(action_name, key_event)

# Returns true if a LineEdit or TextEdit currently has keyboard focus.
func _is_text_input_focused() -> bool:
	var fo = get_viewport().gui_get_focus_owner()
	if fo == null:
		return false
	return (fo is LineEdit) or (fo is TextEdit)

# Close all currently selected nodes using the same logic as the close button
func _close_selected_nodes():
	var sel := _get_selected_nodes()
	if sel.is_empty():
		return
	# Feedback
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()
	# Build list first to avoid mutating while iterating selection
	var to_remove:Array = []
	for n in sel:
		if n == null:
			continue
		if not (n is GraphNode):
			continue
		var node_name := str(n.name)
		# Skip Start (not removable via this bulk action)
		if node_name == "Start":
			continue
		# Handle End explicitly (not tracked in node_stack)
		if node_name == "End":
			for connection in get_connection_list():
				if connection.from == "End" or connection.to == "End":
					disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)
			n.queue_free()
			end_count = 0
			continue
		# Regular tracked nodes: only remove if known type prefix exists
		var type_prefix := node_name.split("_")[0]
		if node_stack.has(type_prefix):
			to_remove.append(n)
	# Remove after collection
	for n in to_remove:
		remove_node(n)

#func auto_connect_start(node):
	#connect_node("Start", 0, node, 0)

#var utilities_path = "C:\\Users\\John\\Alexis' Team Dropbox\\Alexis Austin\\Bespoke\\working\\Godot\\Projects\\HaremHeavenExcel\\json2xl-utilities-5-18"
var save_path = "C:\\Users\\John\\Alexis' Team Dropbox\\Alexis Austin\\Bespoke\\working\\Godot\\Projects\\harem-heaven\\executable\\DialogEditSaves"

func _on_open_utilities_pressed():
	OS.shell_open(save_path)

# ====================== Duplication Support ========================
# Duplicate currently selected GraphNodes by instantiating new nodes
# of the same type and copying node_data, offsetting position.
# Preserves connections between selected nodes (but not to external nodes).
func _duplicate_selected_nodes():
	var sel = _get_selected_nodes()
	if sel.is_empty():
		return
	# Ensure node_data reflects current UI before duplicating
	for src in sel:
		if src.has_method("update_data"):
			src.update_data()
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	# Build set of selected node names for filtering connections
	var selected_names:Dictionary = {}
	for src in sel:
		selected_names[str(src.name)] = true

	# First pass: create all nodes and build name mapping (old_name -> new_name)
	var name_mapping:Dictionary = {}
	var created:Array = []
	var node_connections:Array = []  # Store {from_old, to_old} for remapping later

	for src in sel:
		if typeof(src) != TYPE_OBJECT:
			continue
		# Determine type prefix from name (e.g., DIALOG_001)
		var type_prefix = str(src.name).split("_")[0]
		if not node_stack.has(type_prefix):
			continue
		var original_name = str(src.name)

		# Create new node of same type
		var dst = get_new_node(type_prefix)

		# Build name mapping
		name_mapping[original_name] = str(dst.name)

		# Deep copy node_data and apply
		var data_any = src.get("node_data")
		if typeof(data_any) != TYPE_DICTIONARY:
			continue
		var data:Dictionary = (data_any as Dictionary).duplicate(true)

		# Capture internal connections before clearing
		if data.has("go to"):
			for target in data["go to"]:
				if selected_names.has(str(target)):
					node_connections.append({"from": original_name, "to": str(target)})
			data["go to"] = []

		# Ensure a fresh title/name for the duplicate when applicable
		if data.has("node title"):
			data["node title"] = dst.name
		# Offset position so it's not exactly overlapping
		if data.has("offset_x") and data.has("offset_y"):
			data["offset_x"] = src.position_offset.x + 60
			data["offset_y"] = src.position_offset.y + 40

		_apply_node_data_to_node(dst, data)
		created.append(dst)

	# Second pass: restore internal connections using name mapping
	for conn in node_connections:
		var old_from = conn["from"]
		var old_to = conn["to"]
		if name_mapping.has(old_from) and name_mapping.has(old_to):
			var new_from = name_mapping[old_from]
			var new_to = name_mapping[old_to]
			# Create visual connection
			connect_node(new_from, 0, new_to, 0)
			# Update node_data "go to"
			if has_node(new_from):
				var from_node = get_node(new_from)
				if "node_data" in from_node and from_node.node_data.has("go to"):
					if not from_node.node_data["go to"].has(new_to):
						from_node.node_data["go to"].append(new_to)

	# Select newly created nodes
	if created.size() > 0:
		# Deselect previously selected
		for gn in sel:
			if gn is GraphNode:
				gn.selected = false
		# Select new ones
		for n in created:
			if n is GraphNode:
				n.selected = true
		# Move view slightly towards last created
		last_instanced_node_pos = created[created.size()-1].position_offset

# Apply a node_data dictionary to a newly created node instance,
# mirroring how load-from-JSON does it for each type.
func _apply_node_data_to_node(node, data:Dictionary):
	# Common fields
	if data.has("offset_x") and data.has("offset_y"):
		node.position_offset = Vector2(data["offset_x"], data["offset_y"]) 
	# Type-specific
	var type_prefix = node.name.split("_")[0]
	match type_prefix:
		"DIALOG":
			# GraphNode.gd mapping
			node.text.text = data.get("text", "")
			node.character_opt.select(int(data.get("speaker", 0)))
			node.change_speaker_mode(int(data.get("speaker", 0)))
			if data.has("image_type"):
				if data["image_type"] == "no_change":
					node.image_type_dropdown.select(0)
					node.change_image_type_mode(0)
				else:
					set_option_button_by_text(node.image_type_dropdown, str(data["image_type"]))
					node.change_image_type_mode(node.image_type_dropdown.selected)
			if data.has("expression_eyes"):
				if data["expression_eyes"] == "no_change":
					node.eyes_opt.select(0)
				else:
					set_option_button_by_text(node.eyes_opt, str(data["expression_eyes"]))
			if data.has("expression_mouth"):
				if data["expression_mouth"] == "no_change":
					node.mouth_opt.select(0)
				else:
					set_option_button_by_text(node.mouth_opt, str(data["expression_mouth"]))
			if data.has("paperdoll_pose"):
				if data["paperdoll_pose"] == "no_change":
					node.pose_dropdown.select(0)
				else:
					set_option_button_by_text(node.pose_dropdown, str(data["paperdoll_pose"]))
			if data.has("framing"):
				if data["framing"] == "no_change":
					node.framing_dropdown.select(0)
				else:
					set_option_button_by_text(node.framing_dropdown, str(data["framing"]))
			# Ensure overlay dropdown copies over on duplicate/copy-paste
			if data.has("overlay"):
				if data["overlay"] == "no_change":
					node.overlay_dropdown.select(0)
				else:
					set_option_button_by_text(node.overlay_dropdown, str(data["overlay"]), "Image overlay")
			if data.has("solo_pose"):
				set_option_button_by_text(node.solo_dropdown, str(data["solo_pose"]))
			if data.has("duo_pose"):
				set_option_button_by_text(node.duo_dropdown, str(data["duo_pose"]))
			if data.has("room_id"):
				node.room_line.text = str(data["room_id"])
		"APPEND":
			node.text.text = data.get("text", "")
		"LOGIC":
			node.main_person_line.text = data.get("main_person_id", "")
			node.second_person_line.text = data.get("second_person_id", "")
			node.option_button.select(int(data.get("opt_index", 0)))
			node._on_option_button_item_selected(int(data.get("opt_index", 0)))
			# Operator
			if data.has("if_operator"):
				set_option_button_by_text(node.operator_dropdown, str(data["if_operator"]))
				node._on_operator_dropdown_item_selected(node.operator_dropdown.selected)
			else:
				# Default to AND if no operator found
				node.operator_dropdown.select(0)
				node._on_operator_dropdown_item_selected(0)
			# Variables
			if data.has("set_variables") and not data["set_variables"].is_empty():
				node.variables_group.show()
				var i := 1
				for key in data["set_variables"].keys():
					if node.variable_count < i:
						node._on_add_button_pressed("variable")
					var variable_node = node.variables_group.get_node("Variable" + str(i))
					if variable_node:
						variable_node.text.text = key
						variable_node.check_button.button_pressed = data["set_variables"][key]
					i += 1
			# Signals
			if data.has("signals") and not data["signals"].is_empty():
				node.emit_signal_group.show()
				var i2 := 1
				for signal_name in data["signals"]:
					if node.signal_count < i2:
						node._on_add_button_pressed("signal")
					var signal_node = node.emit_signal_group.get_node("Signal" + str(i2))
					if signal_node:
						signal_node.text.text = signal_name
					i2 += 1
			# If boolean
			if data.has("if_boolean") and not data["if_boolean"].is_empty():
				node.conditionals_group.show()
				var i3 := 1
				for key in data["if_boolean"].keys():
					if node.conditional_count < i3:
						node._on_add_button_pressed("conditional")
					var conditional_node = node.conditionals_group.get_node("Conditional" + str(i3))
					if conditional_node:
						conditional_node.text.text = key
						conditional_node.check_button.button_pressed = data["if_boolean"][key]
					i3 += 1
			# Greater
			if data.has("if_greater") and not data["if_greater"].is_empty():
				node.greater_group.show()
				var i4 := 1
				for key in data["if_greater"].keys():
					if node.greater_count < i4:
						node._on_add_button_pressed("greater")
					var greater_node = node.greater_group.get_node("Greater" + str(i4))
					if greater_node:
						greater_node.var_name.text = key
						greater_node.var_amount.text = str(data["if_greater"][key])
					i4 += 1
			# Less
			if data.has("if_less") and not data["if_less"].is_empty():
				node.less_group.show()
				var i5 := 1
				for key in data["if_less"].keys():
					if node.less_count < i5:
						node._on_add_button_pressed("less")
					var less_node = node.less_group.get_node("Less" + str(i5))
					if less_node:
						less_node.var_name.text = key
						less_node.var_amount.text = str(data["if_less"][key])
					i5 += 1
			# Equal
			if data.has("if_equal") and not data["if_equal"].is_empty():
				node.equal_group.show()
				var i6 := 1
				for key in data["if_equal"].keys():
					if node.equal_count < i6:
						node._on_add_button_pressed("equal")
					var equal_node = node.equal_group.get_node("Equal" + str(i6))
					if equal_node:
						equal_node.var_name.text = key
						equal_node.var_amount.text = str(data["if_equal"][key])
					i6 += 1
			# Has garment
			if data.has("has_garment") and not data["has_garment"].is_empty():
				node.has_garment_group.show()
				var i7 := 1
				for key in data["has_garment"].keys():
					if node.has_garment_count < i7:
						node._on_add_button_pressed("has_garment")
					var has_garment_node = node.has_garment_group.get_node("HasGarment" + str(i7))
					if has_garment_node:
						has_garment_node.text.text = key
						has_garment_node.check_button.button_pressed = data["has_garment"][key]
					i7 += 1
		"CHOICE":
			node.text.text = data.get("text", "")
			if data.has("room_id"):
				node.room_line.text = str(data["room_id"])
			if data.has("reqs_id"):
				node.reqs_preset_line.text = str(data["reqs_id"])
			if data.has("disabled"):
				node.disabled_checkbox.button_pressed = bool(data["disabled"])
			if data.has("icon_id"):
				if str(data["icon_id"]) == "":
					node.icon_dropdown.select(0)
				else:
					set_option_button_by_text(node.icon_dropdown, str(data["icon_id"]))
		"IMAGE":
			# Position set above
			if data.has("image_slot"):
				set_option_button_by_text(node.slot_dropdown, str(data["image_slot"]))
				node.change_slot_mode(node.slot_dropdown.selected)
			if node.slot_dropdown.selected == 0 and data.has("big_image_action"):
				set_option_button_by_text(node.set_hide_big_dropdown, str(data["big_image_action"]))
				node.change_set_hide_big_mode(node.set_hide_big_dropdown.selected)
			if node.slot_dropdown.selected == 1 and data.has("small_image_action"):
				set_option_button_by_text(node.set_hide_small_dropdown, str(data["small_image_action"]))
				node.change_set_hide_small_mode(node.set_hide_small_dropdown.selected)
			if data.has("image_target"):
				set_option_button_by_text(node.target_dropdown, str(data["image_target"]))
				node.change_target_mode(node.target_dropdown.selected)
			if data.has("image_person_big_mode"):
				set_option_button_by_text(node.person_main_mode_dropdown, str(data["image_person_big_mode"]))
				node.change_person_main_mode(node.person_main_mode_dropdown.selected)
			if data.has("expression_eyes"):
				if data["expression_eyes"] == "no_change":
					node.expression_eyes_dropdown.select(0)
				else:
					set_option_button_by_text(node.expression_eyes_dropdown, str(data["expression_eyes"]))
			if data.has("expression_mouth"):
				if data["expression_mouth"] == "no_change":
					node.expression_mouth_dropdown.select(0)
				else:
					set_option_button_by_text(node.expression_mouth_dropdown, str(data["expression_mouth"]))
			if data.has("paperdoll_pose"):
				if data["paperdoll_pose"] == "no_change":
					node.paperdoll_pose_dropdown.select(0)
				else:
					set_option_button_by_text(node.paperdoll_pose_dropdown, str(data["paperdoll_pose"]))
			# Ensure overlay dropdown copies over on duplicate/copy-paste
			if data.has("overlay"):
				if data["overlay"] == "no_change":
					node.overlay_dropdown.select(0)
				else:
					set_option_button_by_text(node.overlay_dropdown, str(data["overlay"]), "Image overlay")
			if data.has("solo_pose"):
				set_option_button_by_text(node.solo_pose_dropdown, str(data["solo_pose"]), "Image solo pose")
			if data.has("duo_pose"):
				if str(data["duo_pose"]) == "HOLDING_HANDS":
					print("Duo pose HOLDING_HANDS found, changing to SITTING")
					set_option_button_by_text(node.duo_pose_dropdown, "SITTING", "Image duo pose")
				else:
					set_option_button_by_text(node.duo_pose_dropdown, str(data["duo_pose"]), "Image duo pose")
			if data.has("framing"):
				if data["framing"] == "no_change":
					node.framing_dropdown.select(0)
				else:
					set_option_button_by_text(node.framing_dropdown, str(data["framing"]))
			if data.has("person_image_id"):
				node.person_image_id_line.text = str(data["person_image_id"])
			if data.has("other_image_id"):
				node.other_image_id_line.text = str(data["other_image_id"])
			if data.has("effect"):
				set_option_button_by_text(node.effect_dropdown, str(data["effect"]))
		"OFFRAMP":
			if data.has("dest_type"):
				match str(data["dest_type"]):
					"SAME_TREE":
						node.destination_dropdown.select(0)
						node.change_mode(0)
						node.outcome_line.text = str(data.get("dest_outcome", ""))
					"OUTSIDE_TREE":
						node.destination_dropdown.select(1)
						node.change_mode(1)
						node.file_line.text = str(data.get("dest_node", ""))
						node.outcome_line.text = str(data.get("dest_outcome", ""))
					"TERMINATE":
						node.destination_dropdown.select(2)
						node.change_mode(2)
						node.outcome_line.text = str(data.get("dest_outcome", ""))
		"EVENT":
			# Set dropdowns for event, split, subtree, wardrobe, and line entry
			if data.has("event_type"):
				set_option_button_by_text(node.event_dropdown, str(data["event_type"]), "Event type")
				node.change_mode(node.event_dropdown.selected)
			if data.has("split_type"):
				set_option_button_by_text(node.split_type_dropdown, str(data["split_type"]))
				node.change_split_mode(node.split_type_dropdown.selected)
			if data.has("subtree_type"):
				set_option_button_by_text(node.subtree_type_dropdown, str(data["subtree_type"]))
				node.change_subtree_mode(node.subtree_type_dropdown.selected)
			if data.has("line_entry_type"):
				set_option_button_by_text(node.line_entry_type_dropdown, str(data["line_entry_type"]))
			if data.has("wardrobe_action"):
				set_option_button_by_text(node.wardrobe_action_dropdown, str(data["wardrobe_action"]))
				node.change_wardrobe_mode(node.wardrobe_action_dropdown.selected)
			if data.has("menu_type"):
				set_option_button_by_text(node.menu_type_dropdown, str(data["menu_type"]))
				node.outfitter_info_container.visible = str(data["menu_type"]) == "OUTFITTER"

			match str(data.get("event_type", "SPLIT")):
				"SPLIT":
					match str(data.get("split_type", "BOOL")):
						"BOOL":
							node.line_edits["split_bool_var_id"].text = str(data.get("split_bool_var_id", ""))
							node.line_edits["split_true_outcome"].text = str(data.get("split_true_outcome", ""))
							node.line_edits["split_false_outcome"].text = str(data.get("split_false_outcome", ""))
						"INT":
							node.line_edits["split_int_var_id"].text = str(data.get("split_int_var_id", ""))
							if data.has("split_greater_outcomes") and not data["split_greater_outcomes"].is_empty():
								for target_value in data["split_greater_outcomes"].keys():
									node._on_add_output_button_pressed("greater")
									var current_output_count = node.output_greater_count
									var output_node_name = "OutputGreater" + str(current_output_count)
									var output_node = node.split_containers["INT"].get_node(output_node_name)
									if output_node:
										output_node.var_amount.text = str(target_value)
										output_node.var_name.text = str(data["split_greater_outcomes"][target_value])
							node.line_edits["split_else_outcome"].text = str(data.get("split_else_outcome", ""))
						"STRING":
							node.line_edits["split_string_var_id"].text = str(data.get("split_string_var_id", ""))
							if data.has("split_string_outcomes") and not data["split_string_outcomes"].is_empty():
								for target_value in data["split_string_outcomes"].keys():
									node._on_add_output_button_pressed("string")
									var current_output_count = node.output_split_string_count
									var output_node_name = "OutputSplitString" + str(current_output_count)
									var output_node = node.split_containers["STRING"].get_node(output_node_name)
									if output_node:
										output_node.outcome_name.text = str(target_value)
										output_node.target_node.text = str(data["split_string_outcomes"][target_value])
							node.line_edits["split_string_else_outcome"].text = str(data.get("split_string_else_outcome", ""))
						"RANDOM":
							if data.has("split_random_outcomes") and not data["split_random_outcomes"].is_empty():
								for target_node in data["split_random_outcomes"].keys():
									node._on_add_output_button_pressed("random")
									var current_output_count = node.output_random_count
									var output_node_name = "OutputRandom" + str(current_output_count)
									var output_node = node.split_containers["RANDOM"].get_node(output_node_name)
									if output_node:
										output_node.var_amount.text = str(data["split_random_outcomes"][target_node])
										output_node.var_name.text = str(target_node)
						"PERMISSION_CHECK":
							if data.has("split_permission_target"):
								set_option_button_by_text(node.permission_target_dropdown, str(data["split_permission_target"]))
							if data.has("split_permission_action_id"):
								node.line_edits["split_permission_action_id"].text = str(data["split_permission_action_id"])
							if data.has("split_permission_difficulties"):
								node.line_edits["split_permission_diff_crit"].text = str(data["split_permission_difficulties"].get("crit", ""))
								node.line_edits["split_permission_diff_success"].text = str(data["split_permission_difficulties"].get("success", ""))
								node.line_edits["split_permission_diff_objection"].text = str(data["split_permission_difficulties"].get("objection", ""))
							if data.has("split_permission_attributes") and not data["split_permission_attributes"].is_empty():
								for attr_type in data["split_permission_attributes"].keys():
									node._on_add_attribute_button_pressed("permission")
									var current_attr_count = node.attribute_permission_count
									var attr_node_name = "WeightedAttributePermission" + str(current_attr_count)
									var attr_node = node.split_containers["PERMISSION_CHECK"].get_node("RelatedAttributes").get_node(attr_node_name)
									if attr_node:
										set_option_button_by_text(attr_node.get_node("AttributeType"), str(attr_type))
										attr_node.get_node("AttributeWeight").text = str(data["split_permission_attributes"][attr_type])
							if data.has("split_permission_outcomes"):
								node.line_edits["split_permission_outcomes"]["crit_heat"].text = str(data["split_permission_outcomes"].get("crit_heat", ""))
								node.line_edits["split_permission_outcomes"]["yes_heat"].text = str(data["split_permission_outcomes"].get("yes_heat", ""))
								node.line_edits["split_permission_outcomes"]["crit_love"].text = str(data["split_permission_outcomes"].get("crit_love", ""))
								node.line_edits["split_permission_outcomes"]["yes_love"].text = str(data["split_permission_outcomes"].get("yes_love", ""))
								node.line_edits["split_permission_outcomes"]["crit_obey"].text = str(data["split_permission_outcomes"].get("crit_obey", ""))
								node.line_edits["split_permission_outcomes"]["yes_obey"].text = str(data["split_permission_outcomes"].get("yes_obey", ""))
								node.line_edits["split_permission_outcomes"]["objection"].text = str(data["split_permission_outcomes"].get("objection", ""))
								node.line_edits["split_permission_outcomes"]["refusal"].text = str(data["split_permission_outcomes"].get("refusal", ""))
						"ENTHUSIASM_CHECK":
							if data.has("split_enthusiasm_target"):
								set_option_button_by_text(node.enthusiasm_target_dropdown, str(data["split_enthusiasm_target"]))
							if data.has("split_enthusiasm_action_id"):
								node.line_edits["split_enthusiasm_action_id"].text = str(data["split_enthusiasm_action_id"])
							#node.line_edits["split_enthusiasm_diff_loves"].text = str(data.get("split_enthusiasm_diff_loves", ""))
							#node.line_edits["split_enthusiasm_diff_likes"].text = str(data.get("split_enthusiasm_diff_likes", ""))
							if data.has("split_enthusiasm_attributes") and not data["split_enthusiasm_attributes"].is_empty():
								for attr_type in data["split_enthusiasm_attributes"].keys():
									node._on_add_attribute_button_pressed("enthusiasm")
									var current_attr_count = node.attribute_enthusiasm_count
									var attr_node_name = "WeightedAttributeEnthusiasm" + str(current_attr_count)
									var attr_node = node.split_containers["ENTHUSIASM_CHECK"].get_node("RelatedAttributes").get_node(attr_node_name)
									if attr_node:
										set_option_button_by_text(attr_node.get_node("AttributeType"), str(attr_type))
										attr_node.get_node("AttributeWeight").text = str(data["split_enthusiasm_attributes"][attr_type])
							if data.has("split_enthusiasm_outcomes"):
								node.line_edits["split_enthusiasm_outcomes"]["loves"].text = str(data["split_enthusiasm_outcomes"].get("loves", ""))
								node.line_edits["split_enthusiasm_outcomes"]["likes"].text = str(data["split_enthusiasm_outcomes"].get("likes", ""))
								node.line_edits["split_enthusiasm_outcomes"]["dislikes"].text = str(data["split_enthusiasm_outcomes"].get("dislikes", ""))
						"ACTION_TEST":
							node.line_edits["split_action_id"].text = str(data.get("split_action_id", ""))
							if data.has("split_action_target"):
								set_option_button_by_text(node.action_target_dropdown, str(data["split_action_target"]))
							if data.has("split_action_outcomes"):
								node.line_edits["split_action_crit_success"].text = str(data["split_action_outcomes"].get("crit_success", ""))
								node.line_edits["split_action_success"].text = str(data["split_action_outcomes"].get("success", ""))
								node.line_edits["split_action_weak_fail"].text = str(data["split_action_outcomes"].get("weak_fail", ""))
								node.line_edits["split_action_fail"].text = str(data["split_action_outcomes"].get("fail", ""))
								node.line_edits["split_action_crit_fail"].text = str(data["split_action_outcomes"].get("crit_fail", ""))
								if data["split_action_outcomes"].has("crit_success_alt"):
									node.line_edits["split_action_crit_success_alt"].text = str(data["split_action_outcomes"].get("crit_success_alt", ""))
								if data["split_action_outcomes"].has("success_alt"):
									node.line_edits["split_action_success_alt"].text = str(data["split_action_outcomes"].get("success_alt", ""))
						"REACTION_STRENGTH":
							# Mirror load-time mapping for reaction strength split
							node.line_edits["split_reaction_id"].text = str(data.get("split_reaction_id", ""))
							if data.has("split_reaction_target"):
								set_option_button_by_text(node.reaction_target_dropdown, str(data["split_reaction_target"]))
							if data.has("split_resource_type"):
								set_option_button_by_text(node.resource_type_dropdown, str(data["split_resource_type"]))
							node.line_edits["split_reaction_subtree"].text = str(data.get("split_reaction_subtree", ""))
							node.reaction_should_trigger_checkbox.button_pressed = bool(data.get("split_reaction_should_trigger", false))
						"HEART_LEVEL":
							# Mirror load-time mapping for heart level split
							if data.has("split_heart_level_target"):
								set_option_button_by_text(node.heart_level_target_dropdown, str(data["split_heart_level_target"]))
							node.line_edits["split_heart_level_subtree"].text = str(data.get("split_heart_level_subtree", ""))
				"SUBTREE":
					match str(data.get("subtree_type", "STANDARD")):
						"STANDARD":
							node.line_edits["subtree_id"].text = str(data.get("subtree_id", ""))
							node.line_edits["subtree_start"].text = str(data.get("subtree_start", ""))
							if data.has("subtree_outputs") and not data["subtree_outputs"].is_empty():
								for i in range(data["subtree_outputs"].size()):
									node._on_add_output_button_pressed("subtree")
									var current_output_count = node.output_subtree_count
									var output_node_name = "OutputSubtree" + str(current_output_count)
									var output_node = node.event_containers["SUBTREE"].get_node(output_node_name)
									if output_node:
										output_node.outcome_name.text = str(data["subtree_outputs"].keys()[current_output_count - 1])
										output_node.target_node.text = str(data["subtree_outputs"].values()[current_output_count - 1])
						"NEGOTIATION":
							node.line_edits["neg_action_id"].text = str(data.get("neg_action_id", ""))
							node.line_edits["neg_subtree_id"].text = str(data.get("neg_subtree_id", ""))
							node.line_edits["neg_subtree_start"].text = str(data.get("neg_subtree_start", ""))
							node.line_edits["neg_subtree_success"].text = str(data.get("neg_subtree_success", ""))
							node.line_edits["neg_subtree_no_patience"].text = str(data.get("neg_subtree_no_patience", ""))
							node.line_edits["neg_subtree_aborted"].text = str(data.get("neg_subtree_aborted", ""))
				"WARDROBE":
					if data.has("wardrobe_girl_id"):
						node.line_edits["wardrobe_girl_id"].text = str(data.get("wardrobe_girl_id", ""))
					match str(data.get("wardrobe_action", "WEAR_GARMENT")):
						"WEAR_GARMENT":
							node.line_edits["garment_id"].text = str(data.get("garment_id", ""))
						"REMOVE_GARMENT":
							set_option_button_by_text(node.garment_slot_dropdown, str(data.get("garment_slot_id", "PANTIES")))
						"WEAR_OUTFIT":
							node.line_edits["outfit_id"].text = str(data.get("outfit_id", ""))
						"SAVE_OUTFIT":
							node.line_edits["outfit_id"].text = str(data.get("outfit_id", ""))
				"MENU":
					match str(data.get("menu_type", "OUTFITTER")):
						"OUTFITTER":
							node.line_edits["outfitter_outfit_id"].text = str(data.get("outfitter_outfit_id", ""))
							node.line_edits["outfitter_output_yes_love"].text = str(data.get("outfitter_output_yes_love", ""))
							node.line_edits["outfitter_output_yes_obey"].text = str(data.get("outfitter_output_yes_obey", ""))
							node.line_edits["outfitter_output_object"].text = str(data.get("outfitter_output_object", ""))
							node.line_edits["outfitter_output_refuse"].text = str(data.get("outfitter_output_refuse", ""))
							node.line_edits["outfitter_output_abort"].text = str(data.get("outfitter_output_abort", ""))
				"LINE_ENTRY":
					node.line_edits["line_entry_target_var"].text = str(data.get("line_entry_target_var", ""))
				"REACTION":
					if data.has("reaction_target"):
						set_option_button_by_text(node.reaction_target_dropdown, str(data["reaction_target"]))
					if data.has("reaction_id"):
						node.line_edits["reaction_id"].text = str(data["reaction_id"])
					node.line_edits["reaction_novelty_counter"].text = str(data.get("reaction_novelty_counter", ""))
					
					if data.has("reaction_girl_resources") and not data["reaction_girl_resources"].is_empty():
						for resource_type in data["reaction_girl_resources"].keys():
							node._on_add_girl_resource_button_pressed()
							var current_count = node.girl_resource_reaction_count
							var resource_node_name = "GirlResourceLine" + str(current_count)
							var resource_node = node.event_containers["REACTION"].get_node("GirlResources").get_node(resource_node_name)
							if resource_node:
								set_option_button_by_text(resource_node.get_node("ResourceType"), str(resource_type))
								resource_node.get_node("ResourceAmount").text = str(data["reaction_girl_resources"][resource_type])

					if data.has("reaction_attributes") and not data["reaction_attributes"].is_empty():
						for attr_type in data["reaction_attributes"].keys():
							node._on_add_attribute_button_pressed("reaction")
							var current_count = node.attribute_reaction_count
							var attr_node_name = "WeightedAttributeReaction" + str(current_count)
							var attr_node = node.event_containers["REACTION"].get_node("RelatedAttributes").get_node(attr_node_name)
							if attr_node:
								set_option_button_by_text(attr_node.get_node("AttributeType"), str(attr_type))
								attr_node.get_node("AttributeWeight").text = str(data["reaction_attributes"][attr_type])

					if data.has("reaction_player_resources") and not data["reaction_player_resources"].is_empty():
						for resource_type in data["reaction_player_resources"].keys():
							node._on_add_player_resource_button_pressed()
							var current_count = node.player_resource_reaction_count
							var resource_node_name = "PlayerResourceLine" + str(current_count)
							var resource_node = node.event_containers["REACTION"].get_node("PlayerResources").get_node(resource_node_name)
							if resource_node:
								set_option_button_by_text(resource_node.get_node("ResourceType"), str(resource_type))
								resource_node.get_node("ResourceAmount").text = str(data["reaction_player_resources"][resource_type])
		"ONRAMP":
			node.key_line.text = data.get("string_key", "")
		"TRANSITION":
			node.locale_line.text = data.get("room_id", "")
			if data.has("fade_time"):
				node.fade_line.text = str(data["fade_time"]) 
			if data.has("wait_time"):
				node.wait_line.text = str(data["wait_time"]) 
			node.main_person_line.text = data.get("main_person_id", "")
			node.second_person_line.text = data.get("second_person_id", "")
			node.show_hide_person_2()
			if data.has("weather"):
				if data["weather"] == "no_change":
					node.weather_option.select(0)
				else:
					set_option_button_by_text(node.weather_option, str(data["weather"]))
			if data.has("phase"):
				if data["phase"] == "no_change":
					node.phase_option.select(0)
				else:
					set_option_button_by_text(node.phase_option, str(data["phase"]))
		_:
			pass

	# After mapping UI, make sure the node's internal node_data mirrors the UI state.
	if node and node.has_method("update_data"):
		node.update_data()

# Helper to gather currently selected GraphNodes by name
func _get_selected_nodes() -> Array:
	var result:Array = []
	var existing_nodes = get_tree().get_nodes_in_group("graph_nodes")
	for n in existing_nodes:
		if n is GraphNode and n.selected:
			result.append(n)
	return result

# ================== Copy/Paste Support ==================
# Copy selected nodes into clipboard as JSON string, preserving internal connections
func _copy_selected_nodes_to_clipboard():
	var sel = _get_selected_nodes()
	if sel.is_empty():
		return
	# Ensure node_data is up-to-date before serializing
	for n in sel:
		if n.has_method("update_data"):
			n.update_data()
	# Build set of selected node names for filtering connections
	var selected_names:Dictionary = {}
	for n in sel:
		selected_names[str(n.name)] = true
	# Determine anchor (top-left most selected) to store relative positions
	var min_x = INF
	var min_y = INF
	for n in sel:
		if n.position_offset.x < min_x:
			min_x = n.position_offset.x
		if n.position_offset.y < min_y:
			min_y = n.position_offset.y
	var payload = {
		"version": 2,
		"nodes": []
	}
	for n in sel:
		var type_prefix = str(n.name).split("_")[0]
		var original_name = str(n.name)
		var data_any = n.get("node_data")
		if typeof(data_any) != TYPE_DICTIONARY:
			continue
		var data:Dictionary = (data_any as Dictionary).duplicate(true)
		# normalize to relative positions
		if data.has("offset_x") and data.has("offset_y"):
			data["offset_x"] = n.position_offset.x - min_x
			data["offset_y"] = n.position_offset.y - min_y
		# Filter "go to" to only include connections to other selected nodes
		var internal_connections:Array = []
		if data.has("go to"):
			for target in data["go to"]:
				if selected_names.has(str(target)):
					internal_connections.append(str(target))
			data["go to"] = internal_connections
		# Store original name for remapping; will be assigned fresh name on paste
		payload["nodes"].append({
			"type": type_prefix,
			"original_name": original_name,
			"data": data
		})
	var json_text = JSON.stringify(payload)
	# Godot 4.x clipboard API
	DisplayServer.clipboard_set(json_text)

# Paste nodes from clipboard JSON at target canvas position, restoring internal connections
func _paste_nodes_from_clipboard(target_canvas_pos:Vector2):
	var clip = DisplayServer.clipboard_get()
	if clip == null or str(clip) == "":
		return
	var parsed = JSON.parse_string(str(clip))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if not parsed.has("nodes") or typeof(parsed["nodes"]) != TYPE_ARRAY:
		return
	# spawn sound
	spawn_sound.pitch_scale = random_number()
	spawn_sound.play()

	# First pass: create all nodes and build name mapping (old_name -> new_name)
	var name_mapping:Dictionary = {}
	var created:Array = []
	var node_connections:Array = []  # Store {from_old, to_old} for remapping later

	for node_def in parsed["nodes"]:
		if typeof(node_def) != TYPE_DICTIONARY:
			continue
		var type_prefix = node_def.get("type", "")
		if not node_stack.has(type_prefix):
			continue
		var data_any = node_def.get("data")
		if typeof(data_any) != TYPE_DICTIONARY:
			continue
		var data:Dictionary = (data_any as Dictionary).duplicate(true)
		var original_name = node_def.get("original_name", "")

		# Store connections for later (version 2 format preserves internal connections)
		var go_to_targets:Array = []
		if data.has("go to") and typeof(data["go to"]) == TYPE_ARRAY:
			go_to_targets = data["go to"].duplicate()

		# Create node
		var dst = get_new_node(type_prefix)

		# Build name mapping
		if original_name != "":
			name_mapping[original_name] = str(dst.name)

		# Rebuild absolute position from relative offsets
		if data.has("offset_x") and data.has("offset_y"):
			data["offset_x"] = int(target_canvas_pos.x) + int(data["offset_x"]) + 20
			data["offset_y"] = int(target_canvas_pos.y) + int(data["offset_y"]) + 15

		# Fresh name/title
		if data.has("node title"):
			data["node title"] = dst.name

		# Clear connections for now; will restore after all nodes created
		if data.has("go to"):
			data["go to"] = []

		_apply_node_data_to_node(dst, data)
		created.append(dst)

		# Store connection info for second pass
		for target in go_to_targets:
			node_connections.append({"from": original_name, "to": str(target)})

	# Second pass: restore internal connections using name mapping
	for conn in node_connections:
		var old_from = conn["from"]
		var old_to = conn["to"]
		if name_mapping.has(old_from) and name_mapping.has(old_to):
			var new_from = name_mapping[old_from]
			var new_to = name_mapping[old_to]
			# Create visual connection
			connect_node(new_from, 0, new_to, 0)
			# Update node_data "go to"
			if has_node(new_from):
				var from_node = get_node(new_from)
				if "node_data" in from_node and from_node.node_data.has("go to"):
					if not from_node.node_data["go to"].has(new_to):
						from_node.node_data["go to"].append(new_to)

	# Update selection to the newly created nodes
	if created.size() > 0:
		# Deselect anything currently selected
		var existing_nodes = _get_selected_nodes()
		for gn in existing_nodes:
			if gn is GraphNode:
				gn.selected = false
		for n in created:
			if n is GraphNode:
				n.selected = true
