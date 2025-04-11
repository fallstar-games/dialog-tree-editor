extends GraphNode

@onready var event_dropdown:OptionButton = $OptionButton
@onready var encounter_container = $CombatInfo
@onready var menu_container = $MenuInfo
@onready var buy_sell_container = $ShopMode
@onready var letter_container = $LetterInfo
@onready var encounter_line:LineEdit = $CombatInfo/LineEdit
@onready var menu_line:LineEdit = $MenuInfo/LineEdit
@onready var letter_line:LineEdit = $LetterInfo/LineEdit
#@onready var buy_btn:CheckBox = $ShopMode/Buy
#@onready var sell_btn:CheckBox = $ShopMode/Sell

var node_data = {
	"offset_x": 0,
	"offset_y": 0,
	"event_type":"COMBAT",
	"encounter_id": "",
	"menu_id":"",
	"letter_id":"",
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

	var idx = event_dropdown.selected
	match idx:
		0: #combat mode
			node_data["event_type"] = "COMBAT"
			node_data["encounter_id"] = encounter_line.text
		1: #open menu mode
			node_data["event_type"] = "MENU"
			node_data["menu_id"] = menu_line.text
		2: #open letter mode
			node_data["event_type"] = "LETTER"
			node_data["letter_id"] = letter_line.text

func _on_event_dropdown_item_selected(index:int):
	change_mode(index)

func change_mode(idx:int = 0):
	match idx:
		0: #Combat Encounter
			encounter_container.show()
			menu_container.hide()
			letter_container.hide()
		1: #Shop Interface
			encounter_container.hide()
			menu_container.show()
			letter_container.hide()
		2: #Letter Interface
			encounter_container.hide()
			menu_container.hide()
			letter_container.show()
