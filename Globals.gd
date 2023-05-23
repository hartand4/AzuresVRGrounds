extends Node

# Constants
const LEVEL_COUNT := 32

export var game_paused := false
export var lock_input := false
export var timer := 0

export var air_dash_unlocked := false
export var air_dash_selected := true
export var armour_unlocked := false
export var armour_selected := true
export var ultimate_unlocked := true
export var ultimate_selected := true

export var pause_menu_on := false
export var retry_menu_on := false
export var current_level := 0
export var coins_collected_in_level := [false, false, false]

# [normal exit reached?, secret exit reached?]
export var goal_reached_in_current_level = [false, false]

export var level_flags = []
export var val_coin_list = []

func _ready() -> void:
	# warning-ignore:unused_variable
	for i in range(LEVEL_COUNT):
		level_flags += [[false, false]]
		val_coin_list += [[false, false, false]]

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	timer += 1
	if timer == pow(2, 30):
		timer = 0
	
	coins_collected_in_level = val_coin_list[current_level]
	goal_reached_in_current_level = level_flags[current_level]

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

# Creates a GravityBullet object at a certain position, with a given velocity and optional gravity
func spawn_gravity_bullet(pos, vel, grav=1200):
	var current_scene = get_current_scene()
	var grav_bullet_scene = load("res://src/enemyobjects/GravityBullet.tscn")
	var spawn := grav_bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.gravity = grav
	spawn.velocity = vel

# Creates a GravityBullet object at a certain position, with a given velocity
func spawn_bullet(pos, vel):
	var current_scene = get_current_scene()
	var bullet_scene = load("res://src/enemyobjects/Bullet.tscn")
	var spawn := bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.velocity = vel

# Creates a Bomba object at a certain position, with a given velocity and optional gravity
func spawn_bomba(pos, vel, grav=1200):
	var current_scene = get_current_scene()
	var bullet_scene = load("res://src/enemyobjects/Bomba.tscn")
	var spawn := bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.velocity = vel
	spawn.gravity = grav

# Returns the constant LEVEL_COUNT
func get_level_count():
	return LEVEL_COUNT

# When loading a file, override the current level_flags with the new one
func set_level_flags(flag_array):
	level_flags = flag_array

# Loads JSON file from the ./saves folder. Contains control info, and list of flags obtained throughout the game
func load_save_data():
	var path = './saves/data.json'
	var file = File.new()
	if not file.file_exists(path):
		print('Nope')
		return
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data

# Saves data on controls, called whenever controls are adjusted
func save_controls_data():
	var path = './saves/data.json'
	var current_data = load_save_data()
	if not current_data:
		current_data = {}
	
	current_data["controls"] = {}
	for action in ['move_up', 'move_down', 'move_left', 'move_right', 'jump', 'attack', 'dash', 'pause']:
		current_data['controls'][action] = [InputMap.get_action_list("move_up")[0].scancode]
		var joypad_button = save_controls_format(action)
		if joypad_button != []:
			current_data['controls'][action] += [joypad_button]
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

# Helper function to format controls save data better with joypad inputs
func save_controls_format(action):
	if InputMap.get_action_list(action).size() < 2: return []
	var button_event = InputMap.get_action_list(action)[1]
	if button_event is InputEventJoypadButton:
		return [button_event.button_index, 0]
	elif button_event is InputEventJoypadMotion:
		return [button_event.axis, 1]
	return []


func load_save_game(save_data, n):
	if not ('file'+str(n) in save_data): return -1
	var file_data = save_data['file' + str(n)]
	if not save_game_checks(file_data): return -1
	
	air_dash_unlocked = file_data['air_dash'][0]
	air_dash_selected = file_data['air_dash'][1]
	armour_unlocked = file_data['armour'][0]
	armour_selected = file_data['armour'][1]
	ultimate_unlocked = file_data['ultimate'][0]
	ultimate_selected = file_data['ultimate'][1]
	
	level_flags = file_data['exits']

func save_game_checks(file_data):
	for flag in ['air_dash', 'armour', 'ultimate']:
		if not (flag in file_data and file_data[flag] is Array and file_data[flag].size() == 2): return false
		if not (typeof(file_data[flag][0]) == TYPE_BOOL and typeof(file_data[flag][1]) == TYPE_BOOL): return false
		
	print('flags for unlockables done')
	
	if not ("current_level" in file_data and typeof(file_data['current_level']) == TYPE_REAL): return false
	if not "val_coins" in file_data: return false
	elif not (file_data['val_coins'] is Array and file_data['val_coins'].size() == LEVEL_COUNT): return false
	if not "exits" in file_data: return false
	elif not (file_data['exits'] is Array and file_data['exits'].size() == LEVEL_COUNT): return false
	
	for i in range(LEVEL_COUNT):
		if not (file_data['val_coins'][i] is Array and file_data['val_coins'][i].size() == 3): return false
		for j in range(3):
			if not (typeof(file_data['val_coins'][i][j]) == TYPE_BOOL): return false
		if not (file_data['exits'][i] is Array and file_data['exits'][i].size() == 2): return false
		for j in range(2):
			if not (typeof(file_data['exits'][i][j]) == TYPE_BOOL): return false
	
	return true

func save_current_game_to_file(n):
	var path = './saves/data.json'
	var current_data = load_save_data()
	if not current_data:
		current_data = {}
	
	current_data['file'+str(n)] = {'current_level': current_level,'air_dash': [air_dash_unlocked, air_dash_selected], 
	'armour': [armour_unlocked, armour_selected], 'ultimate': [ultimate_unlocked, ultimate_selected],}
	current_data['file'+str(n)]['exits'] = level_flags
	current_data['file'+str(n)]['val_coins'] = val_coin_list
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

func total_val_coin_count(coin_list = val_coin_list):
	var sum := 0
	for level in coin_list:
		for truth_value in level:
			sum += (1 if truth_value else 0)
	return sum

func total_exit_count(exit_list = level_flags):
	var sum := 0
	for level in exit_list:
		for truth_value in level:
			sum += (1 if truth_value else 0)
	return sum
