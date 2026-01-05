extends HBoxContainer

@export var resource_amount: LineEdit
@onready var resource_type: OptionButton = $ResourceType

func _on_cancel_button_pressed():
	#check to see if parent's parent has _cancel_button_pressed signal
	if get_parent().get_parent().has_signal("_cancel_button_pressed"):
		get_parent().get_parent()._cancel_button_pressed.emit(get_parent().name.to_lower())
	elif get_parent().get_parent().get_parent().has_signal("_cancel_button_pressed"):
		get_parent().get_parent().get_parent()._cancel_button_pressed.emit(get_parent().name.to_lower())
	else:
		get_parent().get_parent().get_parent().get_parent()._cancel_button_pressed.emit(get_parent().name.to_lower())
	#print(get_parent().name)
	queue_free()
