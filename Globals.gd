extends Node

# Constants
const LEVEL_COUNT := 32
const DEFAULT_HEALTH := 16

# game_paused outright freezes actors and such.
# lock_input prevents the player from moving normally
export var game_paused := false
export var lock_input := false

export var timer := 0
export var vswitch_timer := 0

export var music_volume := 1.0
export var sfx_volume := 1.0

export var set_health := DEFAULT_HEALTH

# Earthquake variables
var eq_timer := 0
var eq_intensity := 3
var earthquake_camera = null

# Unlocked abilities
export var air_dash_unlocked := false
export var air_dash_selected := true
export var armour_unlocked := false
export var armour_selected := true
export var ultimate_unlocked := false
export var ultimate_selected := true

# In order: default slash, flameball, TODO
export var attacks_unlocked := [true, false, false, false]
export var hearts_obtained := [false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false]

var fullscreen_on := false
export var pause_menu_on := false
export var retry_menu_on := false
export var current_level := 1
export var coins_collected_in_level := [false, false, false]

# Checkpoint values: checkpoint number, val coins collected 1-3, position to spawn,
# prevent enemies from spawning?
export var checkpoint_data := [0, false, false, false, Vector2.ZERO, false]

# [normal exit reached?, secret exit reached?]
export var goal_reached_in_current_level = [false, false]

export var level_flags = []
export var val_coin_list = []
export var current_costume := 0
export var unlocked_in_store = []
export var spent_coins = 0

export var current_camera_pos = Vector2.ZERO
var stored_camera_for_earthquake

# Variable that determines the current textbox data.
# The boolean denotes whether or not locked input should remain after text close.
var open_textbox = [null, false]
var game_script = []

# Used for boss gates and specific scenarios, despawns enemies
var prevent_enemy_spawn = false


# Health and ammo scenes
var reload_scenes = [preload("res://src/objects/BigHealth.tscn"),
	preload("res://src/objects/SmallHealth.tscn"),
	preload("res://src/objects/BigAmmo.tscn"),
	preload("res://src/objects/SmallAmmo.tscn")]

func _ready() -> void:
	# warning-ignore:unused_variable
	for i in range(LEVEL_COUNT):
		level_flags += [[false, false]]
		val_coin_list += [[false, false, false]]
	current_camera_pos = get_current_camera_pos()
	
	var script_file = File.new()
	script_file.open("res://text/script.dialogue", File.READ)
	game_script = script_file.get_as_text().split('\n')
	script_file.close()

func _process(_delta) -> void:
	timer += 1
	if timer == pow(2, 30):
		timer = 0
	
	if Input.is_action_just_pressed("fullscreen_toggle"):
		OS.window_fullscreen = not OS.window_fullscreen
	
	if eq_timer:
		do_earthquake()
		eq_timer -= 1
		if not eq_timer:
			recenter_camera()
	
	if open_textbox[0]:
		if is_instance_valid(open_textbox[0]): return
		open_textbox[0] = null
		lock_input = open_textbox[1]
	

# Returns the player object
func find_player():
	var root_node = get_parent()
	for i in root_node.get_children():
		if 'Level' in i.name:
			return i.find_node('Player')

# Begins a transition effect centred at pos, and of transition type 'type'
func start_transition(pos, type):
	Transition.start_transition(pos, type)

# TODO
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
	elif get_current_camera():
		return get_current_camera().get_camera_screen_center()
	return current_camera_pos

# Sets the current camera
func set_current_camera_pos(vector):
	current_camera_pos = vector
	if get_current_camera():
		get_current_camera().global_position = vector

# Generates a debris object with specified texture at a given position
func spawn_debris(texture, pos):
	var current_scene = get_current_scene()
	var debris_scene = preload("res://src/effects/Debris.tscn")
	var spawn := debris_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.tex = texture

# Creates an explosion particle at a specified position
func spawn_explosion(pos, has_collision=false, damage=3):
	var current_scene = get_current_scene()
	var explosion_scene = preload("res://src/effects/Explosion.tscn")
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
	
	var is_health_or_ammo = call_rng(0,1)
	var health_scene = reload_scenes[(0 if drop_var >= (21-2*drop_rate) else 1)+is_health_or_ammo*2]
	var spawn := health_scene.instance() as Node2D
	call_deferred("add_spawn", current_scene, spawn)
	spawn.global_position = pos
	spawn.set_velocity(Vector2(0,-200))

# Adds the spawn scene to the given scene
func add_spawn(current_scene, spawn):
	current_scene.add_child(spawn)

# Creates a GravityBullet object at a certain position, with a given velocity and optional gravity
func spawn_gravity_bullet(pos, vel, grav=1200):
	var current_scene = get_current_scene()
	var grav_bullet_scene = preload("res://src/enemyobjects/GravityBullet.tscn")
	var spawn := grav_bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.gravity = grav
	spawn.velocity = vel

# Creates a GravityBullet object at a certain position, with a given velocity
func spawn_bullet(pos, vel):
	var current_scene = get_current_scene()
	var bullet_scene = preload("res://src/enemyobjects/Bullet.tscn")
	var spawn := bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.velocity = vel

# Creates a Bomba object at a certain position, with a given velocity and optional gravity
func spawn_bomba(pos, vel, grav=1200):
	var current_scene = get_current_scene()
	var bullet_scene = preload("res://src/enemyobjects/Bomba.tscn")
	var spawn := bullet_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
	spawn.velocity = vel
	spawn.gravity = grav

# Creates a mini-missile at a certain position, with a direction dir
func spawn_mini_missile(pos, dir):
	var current_scene = get_current_scene()
	var bullet_scene = preload("res://src/enemyobjects/MiniMissile.tscn")
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
	for action in ['move_up', 'move_down', 'move_left', 'move_right', 'toggle_weapons_l',
		'jump', 'attack', 'dash', 'pause', 'toggle_weapons_r']:
		current_data['controls'][action] = [InputMap.get_action_list(action)[0].scancode]
		var joypad_button = save_controls_format(action)
		if joypad_button != []:
			current_data['controls'][action] += [joypad_button]
	
	var file = File.new()
	var dir = Directory.new()
	if not dir.file_exists('./saves'):
		dir.open('./')
		dir.make_dir('saves')
	
	
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

# Helper function to format controls save data better with joypad inputs
func save_controls_format(action):
	if InputMap.get_action_list(action).size() < 2: return []
	var button_event = InputMap.get_action_list(action)[1]
	if button_event is InputEventJoypadButton:
		return [button_event.button_index, 0, null]
	elif button_event is InputEventJoypadMotion:
		return [button_event.axis, 1, (1 if button_event.axis_value > 0 else -1)]
	return []

# Saves music and sfx volume data
func save_volume_data():
	var path = './saves/data.json'
	var current_data = load_save_data()
	if not current_data:
		current_data = {}
	
	current_data["music_volume"] = music_volume
	current_data["sfx_volume"] = sfx_volume
	
	var file = File.new()
	var dir = Directory.new()
	if not dir.file_exists('./saves'):
		dir.open('./')
		dir.make_dir('saves')
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

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
	
	current_level = file_data['current_level']
	
	attacks_unlocked = int_to_bools(int(file_data['attacks']), 4)
	hearts_obtained = int_to_bools(int(file_data['hearts']), 16)
	set_health = file_data['set_health']
	
	for i in range(3): coins_collected_in_level[i] = false

# Load data for a new file
func load_new_game():
	air_dash_unlocked = false
	air_dash_selected = true
	armour_unlocked = false
	armour_selected = true
	ultimate_unlocked = false
	ultimate_selected = true
	
	var flag_str = ''
	# warning-ignore:unused_variable
	for i in range(LEVEL_COUNT):
		flag_str += '0'
	level_flags = str_to_level_flags(flag_str)
	val_coin_list = str_to_val_coins(flag_str)
	current_costume = 100 if (
		Input.is_action_pressed("toggle_weapons_l") and Input.is_action_pressed("toggle_weapons_r")
		) else 0
	
	unlocked_in_store = []
	spent_coins = 0
	
	current_level = 1
	
	attacks_unlocked = [true, false, false, false]
	hearts_obtained = int_to_bools(0,16)
	set_health = DEFAULT_HEALTH
	
	for i in range(3): coins_collected_in_level[i] = false
	for i in range(2): goal_reached_in_current_level[i] = false

# Returns a dictionary of the nth save file, -1 if non-existent, -2 if corrupted
func view_save_game(save_data, n):
	if not save_data: return -1
	if not ('file'+str(n) in save_data): return -1
	var file_data = save_data['file' + str(n)]
	if not save_game_checks(file_data): return -2
	return file_data

# Converts string to list of val coin flags
func str_to_val_coins(coin_string):
	var coin_list = []
	for i in range(coin_string.length()):
		var new_entry = []
		new_entry += [true] if int(coin_string[i]) % 2 else [false]
		new_entry += [true] if int(coin_string[i]) % 4 >= 2  else [false]
		new_entry += [true] if int(coin_string[i]) >= 4 else [false]
		coin_list += [new_entry]
	return coin_list

# Converts string to list of exit flags
func str_to_level_flags(level_string):
	var level_list = []
	for i in range(level_string.length()):
		var new_entry = []
		new_entry += [true] if int(level_string[i]) % 2 else [false]
		new_entry += [true] if int(level_string[i]) >= 2  else [false]
		level_list += [new_entry]
	return level_list

# Validates some save data to avoid crashes
func save_game_checks(file_data):
	for flag in ['air_dash', 'armour', 'ultimate']:
		if not (flag in file_data and file_data[flag] is Array and file_data[flag].size() == 2): return false
		if not (typeof(file_data[flag][0]) == TYPE_BOOL and typeof(file_data[flag][1]) == TYPE_BOOL): return false
	if not "costumes" in file_data or not(file_data['costumes'] is Array): return false
	for costume in file_data['costumes']:
		if typeof(costume) != TYPE_REAL: return false
	
	if not ("attacks" in file_data and typeof(file_data['attacks']) == TYPE_REAL): return false
	if not ("hearts" in file_data and typeof(file_data['hearts']) == TYPE_REAL): return false
	if not ("set_health" in file_data and typeof(file_data['set_health']) == TYPE_REAL): return false
	
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
	'current_costume': current_costume, 'costumes': unlocked_in_store, 'spent_coins': spent_coins,
	'set_health': set_health}
	
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
	
	current_data['music_volume'] = music_volume
	current_data['sfx_volume'] = sfx_volume
	
	current_data['file'+str(n)]['attacks'] = bools_to_int(attacks_unlocked)
	current_data['file'+str(n)]['hearts'] = bools_to_int(hearts_obtained)
	
	var file = File.new()
	var dir = Directory.new()
	if not dir.file_exists('./saves'):
		dir.open('./')
		dir.make_dir('saves')
	
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

# Deletes file n from the save data
func delete_game(n):
	var path = './saves/data.json'
	var current_data = load_save_data()
	if not current_data:
		current_data = {}
	
	if ('file'+str(n)) in current_data:
		current_data.erase('file'+str(n))
	
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
	var camera = get_current_camera()
	stored_camera_for_earthquake = camera
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
	var camera = stored_camera_for_earthquake
	var variance = eq_intensity if timer % 6 < 2 else 0 if timer % 6 < 4 else -eq_intensity
	
	earthquake_camera.limit_top = camera.limit_top - eq_intensity
	earthquake_camera.limit_bottom = camera.limit_bottom + eq_intensity
	earthquake_camera.limit_left = camera.limit_left
	earthquake_camera.limit_right = camera.limit_right
	camera.current = true
	earthquake_camera.global_position = camera.get_camera_screen_center() + Vector2(0,variance)
	earthquake_camera.current = true

# Removes the temporary eq camera from the scene
func recenter_camera():
	stored_camera_for_earthquake.current = true
	var temp_eq_cam = earthquake_camera
	earthquake_camera = null
	get_current_scene().remove_child(temp_eq_cam)

# Returns a list of a random permutation of n integers including 0
func random_permutation(n):
	var unused_numbers = []
	var permutation = []
	for i in range(n):
		unused_numbers += [i]
	while unused_numbers.size() > 0:
		var index = call_rng(0, unused_numbers.size()-1)
		permutation += [unused_numbers[index]]
		unused_numbers.remove(index)
	return permutation

# Returns the tilemap in the current level/scene
func get_tilemap(layer=1):
	var tilemap_name = "TileMap" + ("Mask" if layer==2 else "Front" if layer==0 else "")
	return get_current_scene().find_node(tilemap_name)

# TODO: FINISH THIS
# Get the function of a tilemap tile based on the current scene
# 0 = Nothing
func get_block_type(block_index, layer=1):
	# Current level will play a part
	block_index = block_index
	layer=layer
	return 0

# Returns the current camera of the viewport
func get_current_camera():
	var viewport = get_viewport()
	if not viewport:
		return null
	var camera_group_id = "__cameras_%d" % viewport.get_viewport_rid().get_id()
	var cameras = get_tree().get_nodes_in_group(camera_group_id)
	for camera in cameras:
		if camera is Camera2D and camera.current:
			return camera
	return null

# Returns a list of booleans of length "length" based on an integer (bitwise)
func int_to_bools(integer, length):
	var temp_bool_list = []
	for i in range(length):
		temp_bool_list += [integer % int(pow(2,i+1)) >= int(pow(2,i))]
	return temp_bool_list

# Returns an integer based on a list of boolean (bitwise)
func bools_to_int(temp_bool_list):
	var integer = 0
	for i in range(temp_bool_list.size() ):
		if temp_bool_list[i]:
			integer += int(pow(2,i))
	return integer

# Spawns a textbox object containing the given text
func create_textbox(text_to_add, instant=false, destroy_instant=false, persist_lock=false):
	var current_scene = get_current_scene()
	if not current_scene: return
	lock_input = true
	var temp_spawn = load("res://src/effects/Textbox.tscn")
	var spawn = temp_spawn.instance()
	spawn.init(text_to_add, instant, destroy_instant)
	current_scene.add_child(spawn)
	open_textbox[0] = spawn
	open_textbox[1] = persist_lock

# Returns the max player health based on the amount of hearts obtained
func get_max_health():
	var max_health_value = DEFAULT_HEALTH
	for heart in hearts_obtained:
		max_health_value += 2 if heart else 0
	return max_health_value

# Checks if object is in range of camera based on its position (copy from actor.gd)
func in_camera_range(pos):
	var camera_pos = get_current_camera_pos()
	return camera_pos.x - 432 - 120 < pos.x and camera_pos.x + 432 + 120 > pos.x and (
		camera_pos.y - 312 - 120 < pos.y and camera_pos.y + 312 + 120 > pos.y)
