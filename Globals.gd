extends Node

export var game_paused := false
export var lock_input := false
export var timer := 0
export var pause_menu_on := false
export var retry_menu_on := false
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

func start_transition(pos, forward):
	var root_node = get_parent()
	for i in root_node.get_children():
		if 'Level' in i.name:
			i.find_node('Transition').start_transition(pos, forward)

func level_number_to_obj(n):
	var boss_level_numbers = [7]
	if n in boss_level_numbers:
		return
	return get_parent() # TODO

# Generates random integer between start and end
func call_rng(start, end):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(start, end)

# Generates a debris object with specified texture at a given position
func spawn_debris(texture, pos):
	var root_node = get_parent()
	# warning-ignore:shadowed_variable
	var current_level = null
	for i in root_node.get_children():
		if 'Level' in i.name:
			current_level = i
	
	var debris_scene = load("res://src/effects/Debris.tscn")
	var spawn := debris_scene.instance() as Node2D
	current_level.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.tex = texture
