extends Node2D


var animation_timer := 0
var title_screen_menu := 0

var title_velocity = 0
var azzy_velocity = 0
var bounce_nums = 4
var title_screen_variant = 0
var selection_cursor := 0
var is_editing_controls = false
var is_transitioning = true

var dummy_cursor := 0
var extra_index := 0

# Big one: loading the save data!
var save_data = {}


func _ready() -> void:
	save_data = Globals.load_save_data()
	if save_data and 'controls' in save_data:
		load_controls(save_data['controls'])
	if save_data and 'music_volume' in save_data:
		Globals.music_volume = save_data['music_volume']
	if save_data and 'sfx_volume' in save_data:
		Globals.sfx_volume = save_data['sfx_volume']
	reset_title_screen()
	
	Globals.load_new_game()
	
	Globals.start_transition(Vector2(0,0), 7)

func _process(_delta: float) -> void:
	
	var menu_dir = get_menu_direction()
	var menu_input = get_menu_input()
	if menu_input: menu_dir = Vector2.ZERO
	if animation_timer:
		menu_dir = Vector2.ZERO
		menu_input = 0
	
	$FirstMenu/Cursor.visible = title_screen_menu == 2
	$FirstMenu.visible = title_screen_menu in [1,2,3]
	$ControlsMenu.visible = title_screen_menu == 4
	$ControlsMenu/Cursor.visible = title_screen_menu == 4
	
	$FilesMenu/FileCursor.visible = title_screen_menu == 3
	$FilesMenu/EraseCursor.visible = false
	$FilesMenu/YNCursor.visible = extra_index == 2
	$FilesMenu/EraseText.visible = extra_index < 2
	$FilesMenu/DeleteText.visible = extra_index == 2
	$FilesMenu/DeletedText.visible = extra_index == 3
	
	$FirstMenu/Cursor.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	$ControlsMenu/Cursor.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	$FilesMenu/FileCursor.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	$FilesMenu/EraseCursor.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	$FilesMenu/YNCursor.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	
	if is_transitioning:
		animation_timer -= 1
		if animation_timer: return
		if title_screen_menu == 2 and selection_cursor == 0:
			# TODO: Transition to opening cutscene...
			
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/LevelMap.tscn")
		elif title_screen_menu == 2 and selection_cursor == 3:
			# TODO: Transition to extras menu
			
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/EXTRA/TitleScreen.tscn")
		elif title_screen_menu == 3:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/LevelMap.tscn")
		return
	
	match title_screen_menu:
		0:
			# TITLE TRANSITIONING PART
			$TitleObject/TitleVisibility/Title/Azzy/TailAnimation.play("TailWag")
			$TitleObject/TitleVisibility/Title/Azzy/AzzyAnimation.play("IdleBlink")
			$PressStart.visible = false
			if animation_timer:
				if title_screen_variant == 0:
					title_bounce()
				elif title_screen_variant == 1:
					title_stretch_in()
				elif title_screen_variant == 2:
					title_build_upward()
			else:
				$TitleObject.set_position(Vector2(0,0))
				$TitleObject/TitleVisibility.set_size(Vector2(864,624))
				$TitleObject/TitleVisibility.set_position(Vector2(0,0))
				title_screen_menu = 1
		1:
			# PRESS START PART
			if not animation_timer:
				$TitleObject/TitleVisibility/Title/Azzy/TailAnimation.play("TailWag")
				$TitleObject/TitleVisibility/Title/Azzy/AzzyAnimation.play("IdleBlink")
				$PressStart.visible = Globals.timer % 60 < 40
				
				if menu_input == 2 or menu_input == 3:
					animation_timer = 120
					azzy_velocity = -25
			elif animation_timer > 60:
				$TitleObject/TitleVisibility/Title/Azzy/TailAnimation.play("TailWag")
				$PressStart.visible = Globals.timer % 15 < 8
				$TitleObject/TitleVisibility/Title/Azzy/AzzyAnimation.play("Jump" if azzy_velocity < 0 else "Fall")
				$TitleObject/TitleVisibility/Title/Azzy/Clothes.frame = $TitleObject/TitleVisibility/Title/Azzy.frame
				azzy_jump()
			elif animation_timer > 1:
				$PressStart.visible = false
				$Camera2D.position = Vector2(1296,312)
			elif animation_timer == 1:
				selection_cursor = 0
				title_screen_menu = 2
		2:
			# MAIN OPTIONS MENU
			if animation_timer:
				animation_timer -= 1
				if animation_timer == 0:
					selection_cursor = 0
					title_screen_menu = 3
				return
			
			selection_cursor = mod_wrap(selection_cursor + int(menu_dir.y), 5)
			$FirstMenu/Cursor.set_position(Vector2(240,108 + 82*selection_cursor))
			if menu_input == 2:
				if selection_cursor == 0:
					Globals.start_transition(Vector2.ZERO, 5)
					animation_timer = 75
					is_transitioning = true
					Globals.load_new_game()
				elif selection_cursor == 1:
					$Camera2D.position = Vector2(2160,312)
					animation_timer = 75
					file_print()
				elif selection_cursor == 2:
					selection_cursor = 10
					title_screen_menu = 4
				elif selection_cursor == 3:
					Globals.start_transition(Vector2.ZERO, 5)
					animation_timer = 75
					is_transitioning = true
				elif selection_cursor == 4:
					$FirstMenu/Cursor.modulate = Color(0,1,0)
					get_tree().quit()
		
		3:
			# LOAD FILE MENU
			if animation_timer:
				animation_timer -= 1
				if animation_timer == 0:
					selection_cursor = 1
					title_screen_menu = 2
				return
			
			if (menu_input == 1 and extra_index == 0):
				$Camera2D.position = Vector2(1296,312)
				animation_timer = 75
			
			do_file_menu(menu_input, menu_dir)
		
		4:
			# CONTROLS MENU
			if selection_cursor == 10:
				if menu_dir.y < 0: selection_cursor = 4
				elif menu_dir.y > 0: selection_cursor = 0
			elif menu_dir.x != 0:
				selection_cursor = mod_wrap(selection_cursor + 5, 10)
			elif (selection_cursor == 0 or selection_cursor == 5) and menu_dir.y < 0:
				selection_cursor = 10
			elif (selection_cursor == 4 or selection_cursor == 9) and menu_dir.y > 0:
				selection_cursor = 10
			else: selection_cursor += menu_dir.y
			
			if menu_input == 1 or (selection_cursor == 10 and menu_input == 2):
				selection_cursor = 2
				title_screen_menu = 2
				$ControlsMenu/Cursor.visible = false
				Globals.save_controls_data()
				return
			if selection_cursor == 10: $ControlsMenu/Cursor.set_position(Vector2(382, 453))
			else:
				$ControlsMenu/Cursor.set_position(Vector2(196 if selection_cursor <= 4 else 564,
				225 + 42*(selection_cursor % 5)))
			$ControlsMenu/Cursor.set_position($ControlsMenu/Cursor.get_position() + Vector2(-148,-16))
			
			display_controls()
			
			if is_editing_controls:
				return
			if menu_input == 2:
				is_editing_controls = true
				$ControlsMenu/Cursor.modulate = Color(0,1,0)
		
	if animation_timer:
		animation_timer -= 1

# Helper function to help the title bounce animation
func title_bounce():
	if not bounce_nums:
		$TitleObject.set_position(Vector2(0,0))
		return
	if $TitleObject.get_position().y >= 0 and title_velocity > 0 and bounce_nums:
		title_velocity = -9*bounce_nums
		bounce_nums -= 1
	if bounce_nums:
		title_velocity += 2
		$TitleObject.set_position(Vector2($TitleObject.get_position() + Vector2(0,title_velocity)))

# Helper function to help with a title screen transition variation
func title_stretch_in():
	var current_size = $TitleObject/TitleVisibility.get_size()
	$TitleObject/TitleVisibility.set_size(current_size + Vector2(20,0))
	$TitleObject/TitleVisibility.set_position(Vector2(420-(current_size.x)/2, 0))
	$TitleObject/TitleVisibility/Title.set_position(Vector2(-420+(current_size.x)/2, 0))
	if current_size.x >= 840:
		$TitleObject/TitleVisibility.set_size(Vector2(840,600))
		$TitleObject/TitleVisibility.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility/Title.set_position(Vector2(0, 0))

# Another function to help with a different variation
func title_build_upward():
	var current_size = $TitleObject/TitleVisibility.get_size()
	$TitleObject/TitleVisibility.set_size(current_size + Vector2(0,15))
	$TitleObject/TitleVisibility.set_position(Vector2(0, 600-current_size.y))
	$TitleObject/TitleVisibility/Title.set_position(Vector2(0, current_size.y-600))
	if current_size.y >= 600:
		$TitleObject/TitleVisibility.set_size(Vector2(840,600))
		$TitleObject/TitleVisibility.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility/Title.set_position(Vector2.ZERO)

# Gets direction input
func get_menu_direction():
	var x_dir = 1.0 if Input.is_action_just_pressed("move_right") else (
		-1.0 if Input.is_action_just_pressed("move_left") else 0.0)
	var y_dir = 1.0 if Input.is_action_just_pressed("move_down") else (
		-1.0 if Input.is_action_just_pressed("move_up") else 0.0)
	return Vector2(x_dir, y_dir)

# Gets button input
func get_menu_input():
	if Input.is_action_just_pressed("jump"):
		return 2
	if Input.is_action_just_pressed("attack"):
		return 1
	if Input.is_action_just_pressed("pause"):
		return 3
	return 0

# Helper function to reset some title screen values
func reset_title_screen():
	title_screen_variant = Globals.call_rng(0,2)
	animation_timer = 100
	selection_cursor = 0
	title_screen_menu = 0
	title_velocity = 0
	azzy_velocity = 0
	is_transitioning = false
	is_editing_controls = false
	$PressStart.visible = false
	$TitleObject/TitleVisibility/Title/Azzy.set_position(Vector2(725,172))
	$Camera2D.position = Vector2(432,312)
	if title_screen_variant == 0:
		$TitleObject.set_position(Vector2(0,-500))
		bounce_nums = 4
		return
	if title_screen_variant == 1:
		$TitleObject.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility.set_size(Vector2(0,624))
		$TitleObject/TitleVisibility.set_position(Vector2(432,0))
		$TitleObject/TitleVisibility/Title.set_position(Vector2(-432,0))
		return
	if title_screen_variant == 2:
		$TitleObject.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility.set_size(Vector2(864,0))
		$TitleObject/TitleVisibility.set_position(Vector2(0,624))
		$TitleObject/TitleVisibility/Title.set_position(Vector2(-624,0))
		return

# Makes Azure jump off title screen
func azzy_jump():
	azzy_velocity += 1.5
	var current_pos = $TitleObject/TitleVisibility/Title/Azzy.get_position()
	$TitleObject/TitleVisibility/Title/Azzy.set_position(current_pos+Vector2(-4,azzy_velocity))

# Proper % function
func mod_wrap(input_num, mod_amt):
	if input_num > 0: return input_num % mod_amt
	return mod_wrap(input_num + mod_amt, mod_amt)

# Displays controls in controls menu
func display_controls():
	var input_label_dict = {
		'UpButtonLabel':'move_up', 'DownButtonLabel':'move_down', 'LeftButtonLabel':'move_left',
		'RightButtonLabel':'move_right', 'JumpButtonLabel':'jump', 'AttackButtonLabel':'attack',
		'DashButtonLabel':'dash', 'PauseButtonLabel':'pause',
		'ShiftLButtonLabel': 'toggle_weapons_l', 'ShiftRButtonLabel': 'toggle_weapons_r'}
	if is_editing_controls: return
	for label in input_label_dict:
		$ControlsMenu/PauseText2.find_node(label).text = OS.get_scancode_string(InputMap.get_action_list(input_label_dict[label])[0].scancode)
		if InputMap.get_action_list(input_label_dict[label]).size() > 1:
			if InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadButton:
				$ControlsMenu/PauseText2.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].button_index)
			elif InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadMotion:
				$ControlsMenu/PauseText2.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].axis) + (
					(" +" if InputMap.get_action_list(input_label_dict[label])[1].get_axis_value() > 0 else " -")
				)

# Listens for new input when editing controls
func _unhandled_input(event, setup=false):
	if not is_editing_controls: return
	if (event is InputEventKey or event is InputEventJoypadButton) and not event.pressed: return
	
	var action_name = input_index_to_str(selection_cursor)
	
	if event is InputEventKey:
		#get_tree().quit()
		var assigned_action = get_key_action(event)
		var assigned_action_name = input_index_to_str(assigned_action)
		
		
		if assigned_action == -1 or setup:
			# This means the key is not assigned to an action
			var joypad_input
			if InputMap.get_action_list(action_name).size() > 1:
				joypad_input = InputMap.get_action_list(action_name)[1]
			InputMap.action_erase_events(action_name)
			InputMap.action_add_event(action_name, event)
			if joypad_input:
				InputMap.action_add_event(action_name, joypad_input)
		else:
			# Key already assigned to another action
			var joypad_input
			if InputMap.get_action_list(action_name).size() > 1:
				joypad_input = InputMap.get_action_list(action_name)[1]
			var other_inputs = [InputMap.get_action_list(action_name)[0]]
			if InputMap.get_action_list(assigned_action_name).size() > 1:
				other_inputs += [InputMap.get_action_list(assigned_action_name)[1]]
			InputMap.action_erase_events(action_name)
			InputMap.action_erase_events(assigned_action_name)
			InputMap.action_add_event(action_name, event)
			if joypad_input:
				InputMap.action_add_event(action_name, joypad_input)
			InputMap.action_add_event(assigned_action_name, other_inputs[0])
			if other_inputs.size() > 1:
				InputMap.action_add_event(assigned_action_name, other_inputs[1])
	
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		
		var assigned_action = get_key_action(event)
		var assigned_action_name = input_index_to_str(assigned_action)
		
		if assigned_action == -1:
			if InputMap.get_action_list(action_name).size() > 1:
				InputMap.action_erase_event(action_name, InputMap.get_action_list(action_name)[1])
			InputMap.action_add_event(action_name, event)
		
		else:
			# Key already assigned to another action
			var joypad_input
			if InputMap.get_action_list(action_name).size() > 1:
				joypad_input = InputMap.get_action_list(action_name)[1]
				InputMap.action_erase_event(action_name, InputMap.get_action_list(action_name)[1])
			InputMap.action_add_event(action_name, event)
			
			# Now swap input with the other assigned action
			InputMap.action_erase_event(assigned_action_name, InputMap.get_action_list(assigned_action_name)[1])
			if joypad_input:
				InputMap.action_add_event(assigned_action_name, joypad_input)
	 
	$ControlsMenu/Cursor.modulate = Color(1,1,1)
	is_editing_controls = false
	animation_timer = 1

# Check if that key is already applied to some action
func get_key_action(event):
	var event_button_index
	
	# Check if button is already assigned to an action (key first)
	if event is InputEventKey:
		event_button_index = event.scancode
		for i in range(10):
			if event_button_index == InputMap.get_action_list(input_index_to_str(i))[0].scancode:
				return i
		return -1
	
	# If instead event is a joypad thing
	elif event is InputEventJoypadButton:
		event_button_index = event.button_index
		for i in range(10):
			var input_on_map = InputMap.get_action_list(input_index_to_str(i))[1]
			if input_on_map is InputEventJoypadButton and event_button_index == input_on_map.button_index:
				return i
		return -1
	
	elif event is InputEventJoypadMotion:
		event_button_index = event.axis
		for i in range(10):
			var input_on_map = InputMap.get_action_list(input_index_to_str(i))[1]
			if input_on_map is InputEventJoypadMotion and event_button_index == input_on_map.axis and (
				input_on_map.axis_value*event.axis_value > 0
			):
				return i
		return -1
	return -1

# Returns the action name from the index number
func input_index_to_str(n):
	if n in range(10):
		return ['move_up', 'move_down', 'move_left', 'move_right', 'toggle_weapons_l',
		'jump', 'attack', 'dash', 'pause', 'toggle_weapons_r'][n]
	return ''

# Runs preliminary checks, then loads controls from save data
func load_controls(ctr_data):
	# Perform security checks first...
	for action_name in ['move_up', 'move_down', 'move_left', 'move_right', 'toggle_weapons_l',
	'attack', 'jump', 'dash', 'pause', 'toggle_weapons_r']:
		if not action_name in ctr_data:
			print('error!')
			return
	
	for i in ctr_data:
		if ctr_data[i].size() > 2 or ctr_data[i].size() < 1:
			print('control data incomplete, ignoring')
			return
		if not (typeof(ctr_data[i][0]) == TYPE_INT or typeof(ctr_data[i][0]) == TYPE_REAL):
			return
		if ctr_data[i].size() == 2:
			if ctr_data[i][1].size() != 3: return
			if not (typeof(ctr_data[i][1][0]) in [TYPE_INT, TYPE_REAL] and
			typeof(ctr_data[i][1][1]) in [TYPE_INT, TYPE_REAL] and ctr_data[i][1][1] in [0,1] and
			(not ctr_data[i][1][2] or ctr_data[i][1][2] in [-1,1])): return
	
	# In the clear as far as I know, now to just load the controls!
	for i in range(10):
		var new_event = InputEventKey.new()
		new_event.set_scancode(int(ctr_data[input_index_to_str(i)][0]))
		new_event.pressed = true
		is_editing_controls = true
		selection_cursor = i
		_unhandled_input(new_event, true)
		print(OS.get_scancode_string(new_event.scancode))
		
		if ctr_data[input_index_to_str(i)].size() == 2:
			if ctr_data[input_index_to_str(i)][1][1]:
				new_event = InputEventJoypadMotion.new()
				new_event.set_axis(int(ctr_data[input_index_to_str(i)][1][0]))
				new_event.set_axis_value(int(ctr_data[input_index_to_str(i)][1][2]))
			else:
				new_event = InputEventJoypadButton.new()
				new_event.set_button_index(int(ctr_data[input_index_to_str(i)][1][0]))
				new_event.pressed = true
			is_editing_controls = true
			selection_cursor = i
			_unhandled_input(new_event)

# Performs logic for file select and erase menus
func do_file_menu(menu_input, menu_dir):
	$FilesMenu/EraseText.text = "ERASE FILE" if extra_index == 0 else "CANCEL"
	$FilesMenu/FileCursor.modulate = Color(1,1,1) if extra_index < 2 else Color(0,1,0)
	
	if extra_index <= 1:
		if menu_dir.x != 0 and selection_cursor != 6:
			selection_cursor = mod_wrap(selection_cursor + 3, 6)
		if menu_dir.y < 0:
			selection_cursor = selection_cursor-1 if selection_cursor in [1,2,4,5] else (
				6 if selection_cursor in [0,3] else 2)
		elif menu_dir.y > 0:
			selection_cursor = selection_cursor+1 if selection_cursor in [0,1,3,4,5] else (
				6 if selection_cursor == 2 else 0)
		
		if extra_index == 0 and menu_input == 2:
			if selection_cursor < 6:
				var file_data = Globals.view_save_game(save_data, selection_cursor+1)
				if typeof(file_data) != TYPE_INT:
					Globals.load_save_game(save_data, selection_cursor+1)
					Globals.start_transition(Vector2.ZERO, 5)
					animation_timer = 75
					is_transitioning = true
				else:
					print('No (valid) file to load')
			else:
				extra_index = 1
				$FileBG.texture = load("res://assets/Title Screen/FilesBG2.png")
		
		elif extra_index == 1:
			# warning-ignore:integer_division
			$FilesMenu/FileCursor.position = Vector2(1912 + 376*(selection_cursor/3), 170 + 114*(selection_cursor%3))
			if menu_input == 1 or (menu_input==2 and selection_cursor == 6):
				extra_index = 0
				$FileBG.texture = load("res://assets/Title Screen/FilesBG.png")
			elif menu_input == 2:
				var file_data = Globals.view_save_game(save_data, selection_cursor+1)
				if typeof(file_data) != TYPE_INT or file_data == -2:
					extra_index = 2
					dummy_cursor = selection_cursor
					selection_cursor = 1
				else:
					print('No file to delete')
		
		$FilesMenu/FileCursor.visible = selection_cursor < 6
		$FilesMenu/EraseCursor.visible = selection_cursor == 6
		if extra_index < 2:
			# warning-ignore:integer_division
			$FilesMenu/FileCursor.position = Vector2(1912 + 376*(selection_cursor/3), 170 + 114*(selection_cursor%3))
	
	elif extra_index == 2:
		if menu_dir.x != 0:
			selection_cursor = mod_wrap(selection_cursor+1, 2)
		
		if menu_input == 1 or (menu_input == 2 and selection_cursor == 1):
			extra_index = 1
			selection_cursor = dummy_cursor
		
		elif menu_input == 2:
			Globals.delete_game(dummy_cursor+1)
			file_print()
			extra_index = 3
		
		$FilesMenu/YNCursor.position = Vector2(2208 + selection_cursor*146,496)
	
	elif extra_index == 3 and menu_input == 2:
		extra_index = 0
		$FileBG.texture = load("res://assets/Title Screen/FilesBG.png")
		save_data = Globals.load_save_data()
		selection_cursor = dummy_cursor

# Logic that prints info for each save game
func file_print():
	for i in range(6):
		var file_display = $FilesMenu.find_node('File'+str(i+1))
		var file_data = Globals.view_save_game(Globals.load_save_data(), i+1)
		
		if typeof(file_data) == TYPE_NIL or (typeof(file_data) == TYPE_INT and file_data == -1):
			for node in ['MainIcons','Sprite','Sprite2','Sprite3','CoinAmount','ExitAmount']:
				file_display.find_node(node).visible = false
			file_display.find_node('EmptyText').visible = true
		
		elif typeof(file_data) == TYPE_INT and file_data == -2:
			file_display.find_node('EmptyText').visible = false
			for node in ['Sprite','Sprite2','Sprite3']:
				file_display.find_node(node).visible = false
			for j in range(3):
				file_display.find_node("Weapon"+str(j+1)).visible = false
			
			file_display.find_node('MainIcons').visible = true
			file_display.find_node('CoinAmount').visible = true
			file_display.find_node('ExitAmount').visible = true
			file_display.find_node('CoinAmount').text = '???'
			file_display.find_node('ExitAmount').text = '??'
			file_display.find_node('HealthNumber').text = '??'
		
		else:
			file_display.find_node('EmptyText').visible = false
			for node in ['MainIcons','CoinAmount','ExitAmount']:
				file_display.find_node(node).visible = true
			file_display.find_node('Sprite').visible = file_data.air_dash[0]
			file_display.find_node('Sprite2').visible = file_data.armour[0]
			file_display.find_node('Sprite3').visible = file_data.ultimate[0]
			
			var temp_coin_amt = Globals.total_val_coin_count(Globals.str_to_val_coins(file_data['val_coins']))
			file_display.find_node('CoinAmount').text = (
				str(temp_coin_amt / 100) + str((temp_coin_amt%100)/10) + str(temp_coin_amt % 10) )
				
			var temp_exit_amt = Globals.total_exit_count(Globals.str_to_level_flags(file_data['exits']))
			file_display.find_node('ExitAmount').text = (
				str(temp_exit_amt/10) + str(temp_exit_amt % 10) )
			
			var temp_attack_list = Globals.int_to_bools(int(file_data['attacks']), 4)
			file_display.find_node('Weapon1').visible = temp_attack_list[1]
			file_display.find_node('Weapon2').visible = temp_attack_list[2]
			file_display.find_node('Weapon3').visible = temp_attack_list[3]
			
			var temp_health_amt = Globals.DEFAULT_HEALTH
			var temp_hearts_list = Globals.int_to_bools(int(file_data.hearts), 16)
			for temp_heart in temp_hearts_list:
				temp_health_amt += 2 if temp_heart else 0
			file_display.find_node('HealthNumber').text = (
				str(temp_health_amt/10) + str(temp_health_amt % 10) )
