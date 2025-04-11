extends GraphNode

#var node_type = "option"

#@export var text : CodeEdit
@onready var text = $Text/TextEdit
@onready var dice_roll_dropdown = $DiceDropdown
@onready var difficulty_container = $HBoxContainer
@onready var roll_difficulty: LineEdit = $HBoxContainer/LineEdit

@export var ignore_color: Color = Color.hex(0x7f7f7fff)
@export var active_color: Color = Color.hex(0x7f7f7fff)

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"text": "",
	"dice_roll": "",
	"difficulty": 0,
	"go to": []
}

func _on_close_request():
		# Delegate node removal to parent as its the orchestrator
	get_parent().remove_node(self)

func _on_dragged(from, to):
	position_offset = to

	
func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize
	
func update_data():
	node_data["text"] = text.text

	node_data["offset_x"] = position_offset.x
	node_data["offset_y"] = position_offset.y

	var idx = dice_roll_dropdown.selected
	if idx > 0:
		node_data["dice_roll"] = dice_roll_dropdown.get_item_text(idx)
		node_data["difficulty"] = int(roll_difficulty.text)
	else:
		node_data["dice_roll"] = ""
		node_data["difficulty"] = 0


func _on_dice_dropdown_item_selected(index:int):
	if index == -1 || index == 0:
		dice_roll_on(false)
	else:
		dice_roll_on()

func dice_roll_on(is_on:bool = true):
	if is_on:
		difficulty_container.show()
		dice_roll_dropdown.add_theme_color_override("font_color", active_color)
	else:
		difficulty_container.hide()
		dice_roll_dropdown.add_theme_color_override("font_color", ignore_color)
