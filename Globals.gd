extends Node

# Constants
const LEVEL_COUNT := 32

export var game_paused := false
export var lock_input := false
export var timer := 0
export var pause_menu_on := false
export var retry_menu_on := false
export var current_level := 0
export var coins_collected_in_level := [false, false, false]

# [normal exit reached?, secret exit reached?]
export var goal_reached_in_current_level = [false, false]

export var level_flags = []

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	timer += 1
	if timer == pow(2, 30):
		timer = 0

# Returns the player object
func find_player():
	var root_node = get_parent()
	for i in root_node.get_children():
		if 'Level' in i.name:
			return i.find_node('Player')

# Begins a transition effect centred at pos, and of transition type 'type'
func start_transition(pos, type):
	get_current_scene().find_node('Transition').start_transition(pos, type)

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

# Returns the current level scene, mostly used within Globals itself
func get_current_scene():
	var root_node = get_parent()
	for i in root_node.get_children():
		if 'Level' in i.name:
			return i
		elif i.name == 'TitleScreen': return i
	
# Generates a debris object with specified texture at a given position
func spawn_debris(texture, pos):
	var current_scene = get_current_scene()
	var debris_scene = load("res://src/effects/Debris.tscn")
	var spawn := debris_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.tex = texture

# Creates an explosion particle at a specified position
func spawn_explosion(pos):
	var current_scene = get_current_scene()
	var explosion_scene = load("res://src/effects/Explosion.tscn")
	var spawn := explosion_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos

# Creates a health object at a certain position, with probability depending on drop_rate
func spawn_health(pos, drop_rate=1):
	var current_scene = get_current_scene()
	
	var drop_var = call_rng(1, 20)
	if drop_var < (20-6*drop_rate): return
	
	var health_scene = load("res://src/objects/Health.tscn" if drop_var >= (21-2*drop_rate) else "res://src/objects/SmallHealth.tscn")
	var spawn := health_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.global_position = pos
	spawn.set_velocity(Vector2(0,-200))

# Returns the constant LEVEL_COUNT
func get_level_count():
	return LEVEL_COUNT

# When loading a file, override the current level_flags with the new one
func set_level_flags(flag_array):
	level_flags = flag_array
