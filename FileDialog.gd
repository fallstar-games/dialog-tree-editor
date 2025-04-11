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
	file_path = new_text
	error_message.hide()
	file_exists.hide()
	if you_will_lose:
		you_will_lose.hide()
	confirm_file_overwrite = 0
	confirm_lose_unsaved = 0

# Save a file
func _on_save_pressed(skip_confirm:bool = false):
	if file_path and file_path.is_valid_filename():
		
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
		
		# Save to file
		#var file = FileAccess.open("user://" + file_path + ".json", FileAccess.WRITE)
		var file = FileAccess.open("res://SaveDir/" + file_path + ".json", FileAccess.WRITE)
		file.store_string(dialog)
		
		# Hide self
		self.hide()
		Global.emit_signal("close_menu")
		
		# Play notification sound
		if not notification_sound.playing:
			notification_sound.play()
		
	else:
		error_message.show()
		#Animation Effects
		$JerkAnimation.play("Jerk")
		$ErrorSound.play()

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

	#do a save of a blank file
	if file_path and file_path.is_valid_filename():
		get_window().title = file_path
		var dialog = {}
		get_tree().current_scene.dialog = dialog
		dialog = JSON.stringify(dialog)
		var file = FileAccess.open("res://SaveDir/" + file_path + ".json", FileAccess.WRITE)
		file.store_string(dialog)
		self.hide()
		Global.emit_signal("close_menu")
		
		if not notification_sound.playing:
			notification_sound.play()

