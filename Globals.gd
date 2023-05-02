extends Node

export var game_paused := false
export var lock_input := false
export var timer := 0
export var pause_menu_on := false
export var current_level := 0
export var coins_collected_in_level := [false, false, false]

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	timer += 1
	if timer == pow(2, 30):
		timer = 0

func find_player():
	var root_node = get_parent()
	for i in root_node.get_children():
		if 'Level' in i.name:
			return i.find_node('Player')
