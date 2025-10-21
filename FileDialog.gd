extends Panel

#@export var file_name : NodePath
#@export var cancel_button : NodePath
#@export var confirm_button : NodePath
#@export var back_button : NodePath
@export var file_name: LineEdit
@export var error_message : Label
@export var file_exists : Label
@export var you_will_lose : Label
@export var jerk_anim : AnimationPlayer
@export var error_sound : AudioStreamPlayer
@export var notification_sound : AudioStreamPlayer

var confirm_file_overwrite = 0
var confirm_lose_unsaved = 0

var file_path 

# Normalize a user-entered path to a safe relative subpath under the save directory.
# - Converts backslashes to forward slashes
# - Removes leading slashes to prevent absolute paths
# - Rejects parent traversal (..) and invalid segments
# - Collapses empty/dot segments
func _normalize_subpath(input: String) -> String:
	if input == null:
		return ""
	var s := input.strip_edges()
	# Normalize separators to Godot-style
	s = s.replace("\\", "/")
	# Disallow absolute-like paths
	while s.begins_with("/"):
		s = s.substr(1)
	# Split and validate parts
	var parts: Array = []
	for raw in s.split("/", false):
		var p := String(raw).strip_edges()
		if p == "" or p == ".":
			continue
		if p == "..":
			return ""
		if not p.is_valid_filename():
			return ""
		parts.append(p)
	return "/".join(parts)

# Cancel button
func _on_cancel_pressed():
	file_exists.hide()
	if you_will_lose:
		you_will_lose.hide()
	confirm_file_overwrite = 0
	confirm_lose_unsaved = 0
	#erase any text in the lineEdit
	file_name.text = ""
	self.hide()

func _on_line_edit_text_changed(new_text):
	# Normalize user input as they type so subfolders are supported cross-platform.
	file_path = _normalize_subpath(new_text)
	error_message.hide()
	file_exists.hide()
	if you_will_lose:
		you_will_lose.hide()
	confirm_file_overwrite = 0
	confirm_lose_unsaved = 0

# Save a file
func _on_save_pressed(skip_confirm:bool = false):
	if file_path and file_path != "":
		
		# If file exists
		if Global.if_file_exists(file_path) and confirm_file_overwrite == 0 and !skip_confirm:
			confirm_file_overwrite += 1
			file_exists.show()
			
			#Animation Effects
			jerk_anim.play("Jerk")
			error_sound.play()
			return
			
		# Reset File exists error
		confirm_file_overwrite = 0
			
		# Get compiled data
		var dialog = get_tree().current_scene.compile_nodes_into_json()
	
		# Change window title
		get_window().title = file_path
		
		# Convert to Json
		dialog = JSON.stringify(dialog)
		
		# Save to file (ensure subdirectories exist)
		var abs_path: String = Global.get_formal_filepath(file_path)
		var abs_dir: String = abs_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(abs_dir):
			DirAccess.make_dir_recursive_absolute(abs_dir)
		var file = FileAccess.open(abs_path, FileAccess.WRITE)
		file.store_string(dialog)

		# Also save a copy to <executable path>/XLUtilities/inbox/
		var exe_dir = OS.get_executable_path().get_base_dir()
		var inbox_dir = exe_dir.path_join("XLUtilities").path_join("inbox")
		if not DirAccess.dir_exists_absolute(inbox_dir):
			DirAccess.make_dir_recursive_absolute(inbox_dir)
		var inbox_path = inbox_dir.path_join(file_path + ".json")
		# Ensure nested subfolders inside inbox exist as well
		var inbox_subdir: String = inbox_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(inbox_subdir):
			DirAccess.make_dir_recursive_absolute(inbox_subdir)
		var inbox_file = FileAccess.open(inbox_path, FileAccess.WRITE)
		if inbox_file:
			inbox_file.store_string(dialog)
		
		# Hide self
		self.hide()
		Global.emit_signal("close_menu")
		
		# Play notification sound
		if not notification_sound.playing:
			notification_sound.play()
		
	else:
		error_message.show()
		#Animation Effects
		jerk_anim.play("Jerk")
		error_sound.play()

# Create a new file			
func _on_create_pressed():

	# If file exists
	if Global.if_file_exists(file_path) and confirm_file_overwrite == 0:
		confirm_file_overwrite += 1
		file_exists.show()
		
		#Animation Effects
		jerk_anim.play("Jerk")
		error_sound.play()
		return

	#if the current node count is greater than 0
	if get_tree().current_scene.total_node_count > 0 && confirm_lose_unsaved == 0:
		confirm_lose_unsaved += 1
		file_exists.hide()
		you_will_lose.show()

		#Animation Effects
		jerk_anim.play("Jerk")
		error_sound.play()
		return

	# Reset File exists error
	confirm_lose_unsaved = 0

	#clear everything first
	get_tree().current_scene.clear_all()

	#do a save of a blank file (supporting subfolders)
	if file_path and file_path != "":
		get_window().title = file_path
		var dialog = {}
		get_tree().current_scene.dialog = dialog
		dialog = JSON.stringify(dialog)
		# Ensure destination directory exists, then write
		var abs_path: String = Global.get_formal_filepath(file_path)
		var abs_dir: String = abs_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(abs_dir):
			DirAccess.make_dir_recursive_absolute(abs_dir)
		var file = FileAccess.open(abs_path, FileAccess.WRITE)
		file.store_string(dialog)
		self.hide()
		Global.emit_signal("close_menu")
		
		if not notification_sound.playing:
			notification_sound.play()

