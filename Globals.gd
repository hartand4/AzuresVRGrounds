extends Node

# Constants
const LEVEL_COUNT := 32

export var game_paused := false
export var lock_input := false
export var timer := 0

export var vswitch_timer := 0

# Earthquake variables
var eq_timer := 0
var eq_intensity := 3
var earthquake_camera = null

export var air_dash_unlocked := false
export var air_dash_selected := true
export var armour_unlocked := false
export var armour_selected := true
export var ultimate_unlocked := false
export var ultimate_selected := true

export var pause_menu_on := false
export var retry_menu_on := false
export var current_level := 1
export var coins_collected_in_level := [false, false, false]
export var checkpoint_data := [0, false, false, false, Vector2.ZERO]

# [normal exit reached?, secret exit reached?]
export var goal_reached_in_current_level = [false, false]

export var level_flags = []
export var val_coin_list = []
export var current_costume := 0
export var unlocked_in_store = []
export var spent_coins = 0

export var current_camera_pos = Vector2.ZERO

func _ready() -> void:
	# warning-ignore:unused_variable
	for i in range(LEVEL_COUNT):
		level_flags += [[false, false]]
		val_coin_list += [[false, false, false]]
	current_camera_pos = get_current_camera_pos()

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	timer += 1
	if timer == pow(2, 30):
		timer = 0
	
	if eq_timer:
		do_earthquake()
		eq_timer -= 1
		if not eq_timer:
			recenter_camera()

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

# Returns the current camera (usually the player)
func get_current_camera_pos():
	var player = Globals.find_player()
	if player and player.find_node("Camera2D").current:
		return player.find_node("Camera2D").get_camera_screen_center()
	return current_camera_pos

# Sets the current camera
func set_current_camera_pos(vector):
	current_camera_pos = vector

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
func spawn_explosion(pos, has_collision=false, damage=3):
	var current_scene = get_current_scene()
	var explosion_scene = load("res://src/effects/Explosion.tscn")
	var spawn := explosion_scene.instance() as Node2D
	current_scene.call_deferred("add_child", spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.has_collision = has_collision
	spawn.damage = damage

# Creates a health object at a certain position, with probability depending on drop_rate
func spawn_health(pos, drop_rate=1):
	var current_scene = get_current_scene()
	
	var drop_var = call_rng(1, 20)
	if drop_var < (20-6*drop_rate): return
	
	var health_scene = load("res://src/objects/Health.tscn" if drop_var >= (21-2*drop_rate) else "res://src/objects/SmallHealth.tscn")
	var spawn := health_scene.instance() as Node2D
	call_deferred("add_spawn", current_scene, spawn)
	spawn.global_position = pos
	spawn.set_velocity(Vector2(0,-200))

func add_spawn(current_scene, spawn):
	current_scene.add_child(spawn)

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

func spawn_mini_missile(pos, dir):
	var current_scene = get_current_scene()
	var bullet_scene = load("res://src/enemyobjects/MiniMissile.tscn")
	var spawn := bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.direction = dir

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
		current_data['controls'][action] = [InputMap.get_action_list(action)[0].scancode]
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

# Loads flags in file n to global data
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
	
	level_flags = str_to_level_flags(file_data['exits'])
	val_coin_list = str_to_val_coins(file_data['val_coins'])
	current_costume = file_data['current_costume']
	
	unlocked_in_store = file_data['costumes']
	spent_coins = file_data['spent_coins']

# Converts string to list of val coin flags
func str_to_val_coins(coin_string):
	var coin_list = []
	for i in range(coin_string.length()):
		coin_list[0] = true if coin_string[i] % 2 else false
		coin_list[1] = true if coin_string[i] % 4 > 2  else false
		coin_list[2] = true if coin_string[i] > 4 else false
	return coin_list

# Converts string to list of exit flags
func str_to_level_flags(level_string):
	var level_list = []
	for i in range(level_string.length()):
		level_list[0] = true if level_string[i] % 2 else false
		level_list[1] = true if level_string[i] > 2  else false
	return level_list

# Validates some save data to avoid crashes
func save_game_checks(file_data):
	for flag in ['air_dash', 'armour', 'ultimate']:
		if not (flag in file_data and file_data[flag] is Array and file_data[flag].size() == 2): return false
		if not (typeof(file_data[flag][0]) == TYPE_BOOL and typeof(file_data[flag][1]) == TYPE_BOOL): return false
	if not "costumes" in file_data or not(file_data['costumes'] is Array): return false
	for costume in file_data['costumes']:
		if typeof(costume) != TYPE_REAL: return false
	
	print('flags for unlockables done')
	
	if not ("current_level" in file_data and typeof(file_data['current_level']) == TYPE_REAL): return false
	if not "val_coins" in file_data: return false
	elif not (file_data['val_coins'] is String and file_data['val_coins'].is_valid_integer() and
		file_data['val_coins'].length() == LEVEL_COUNT): return false
	if not "exits" in file_data: return false
	elif not (file_data['exits'] is String and file_data['exits'].is_valid_integer() and
		file_data['exits'].length() == LEVEL_COUNT): return false
	
	if not ("current_costume" in file_data and typeof(file_data['current_costume']) == TYPE_REAL): return false
	if not ("spent_coins" in file_data and typeof(file_data['spent_coins']) == TYPE_REAL): return false
	
	return true

# Overrides file n data in save data format
func save_current_game_to_file(n):
	var path = './saves/data.json'
	var current_data = load_save_data()
	if not current_data:
		current_data = {}
	
	current_data['file'+str(n)] = {'current_level': current_level,'air_dash': [air_dash_unlocked, air_dash_selected], 
	'armour': [armour_unlocked, armour_selected], 'ultimate': [ultimate_unlocked, ultimate_selected],
	'current_costume': current_costume, 'costumes': unlocked_in_store, 'spent_coins': spent_coins}
	
	var exit_numbers = ''
	var val_coin_numbers = ''
	for i in val_coin_list.size():
		var coin_value = 0
		var exit_value = 0
		
		if val_coin_list[i][0]: coin_value += 1
		if val_coin_list[i][1]: coin_value += 2
		if val_coin_list[i][2]: coin_value += 4
		val_coin_numbers += str(coin_value)
		
		if level_flags[i][0]: exit_value += 1
		if level_flags[i][1]: exit_value += 2
		exit_numbers += str(exit_value)
		
	current_data['file'+str(n)]['val_coins'] = val_coin_numbers
	current_data['file'+str(n)]['exits'] = exit_numbers
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

# Counts total amount of collected val coins
func total_val_coin_count(coin_list = val_coin_list):
	var sum := 0
	for level in coin_list:
		for truth_value in level:
			sum += (1 if truth_value else 0)
	return sum

# Counts total amount of level exits
func total_exit_count(exit_list = level_flags):
	var sum := 0
	for level in exit_list:
		for truth_value in level:
			sum += (1 if truth_value else 0)
	return sum

# Starts earthquake effect for 'length' frames, and with 'intensity' variance
func start_earthquake(length, intensity=3):
	eq_timer = length
	eq_intensity = intensity
	var camera = find_player().find_node('Camera2D')
	var current_scene = get_current_scene()
	camera.current = false
	var new_camera = Camera2D.new()
	new_camera.current = true
	earthquake_camera = new_camera
	
	current_scene.add_child(earthquake_camera)
	earthquake_camera.global_position = camera.global_position
	do_earthquake()

# Continue earthquake effect until eq_timer ends
func do_earthquake():
	var camera = find_player().find_node('Camera2D')
	var variance = eq_intensity if timer % 6 < 2 else 0 if timer % 6 < 4 else -eq_intensity
	
	earthquake_camera.limit_top = camera.limit_top - eq_intensity
	earthquake_camera.limit_bottom = camera.limit_bottom + eq_intensity
	earthquake_camera.limit_left = camera.limit_left
	earthquake_camera.limit_right = camera.limit_right
	camera.current = true
	earthquake_camera.current = false
	earthquake_camera.global_position = camera.get_camera_screen_center() + Vector2(0,variance)
	camera.current = false
	earthquake_camera.current = true

# Removes the temporary eq camera from the scene
func recenter_camera():
	find_player().find_node('Camera2D').current = true
	var temp_eq_cam = earthquake_camera
	earthquake_camera = null
	get_current_scene().remove_child(temp_eq_cam)
