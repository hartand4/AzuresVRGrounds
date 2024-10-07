extends TextureRect

const PAUSE_NORMAL := 0
const PAUSE_SAVES := 1
const PAUSE_COINS := 2
const PAUSE_OPTIONS := 3
const PAUSE_CONTROLS := 4
const PAUSE_TITLE := 5

var menu_type := PAUSE_NORMAL
var selection_cursor := 0
var dummy_cursor := 0
var extra_index := 0

var input_delay = 1
var is_transitioning = false
var is_editing_control = false

func _ready() -> void:
	$Cursor1.set_position(Vector2(250, 152 + 84*selection_cursor))

func _process(_delta: float) -> void:
	
	$Cursor1.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	$Cursor2.modulate.a = 0.25*sin(PI*Globals.timer/30) + 0.75
	
	if not Globals.pause_menu_on:
		menu_type = PAUSE_NORMAL
		selection_cursor = 0
		input_delay = 1
		visible = false
		return
	visible = true
	
	if input_delay and not is_transitioning:
		input_delay -= 1
		$Cursor1.visible = false
		$Cursor2.visible = false
		return
	elif input_delay and is_transitioning:
		input_delay -= 1
		return
	elif is_transitioning and not input_delay:
		Globals.pause_menu_on = false
		Globals.game_paused = false
		if menu_type == 5:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/EXTRA/TitleScreen.tscn")
		return
	
	for i in range(6):
		find_node("PauseText" + str(i)).visible = false
	find_node("PauseText" + str(menu_type)).visible = true
	$Cursor1.visible = menu_type in [0,2,3,5]
	$Cursor2.visible = menu_type == 4
	
	# Options menu unlocks
	options_menu_visuals()
	
	
	var menu_input = get_menu_inputs()
	var direction_input = Vector2.ZERO if menu_input else get_menu_direction()
	if is_editing_control:
		menu_input = 0
		direction_input = Vector2.ZERO
	
	if menu_input == 3:
		Globals.pause_menu_on = false
		Globals.game_paused = false
		extra_index = 0
		return
	
	match menu_type:
		PAUSE_NORMAL:
			if direction_input.x != 0:
				selection_cursor = mod_wrap(selection_cursor + 3, 6)
			if direction_input.y != 0:
				if selection_cursor > 2:
					selection_cursor = 3 + mod_wrap(selection_cursor-3 + int(direction_input.y), 3)
				else:
					selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 3)
			
			$Cursor1.set_position(Vector2(250 + 350*(1 if selection_cursor > 2 else 0),
				152 + 84*(selection_cursor % 3)))
			
			if selection_cursor == 0 and menu_input == 2:
				Globals.pause_menu_on = false
				Globals.game_paused = false
				return
			elif menu_input == 2:
				menu_type = selection_cursor
				if menu_type == 4: selection_cursor = 10
				elif menu_type == 5: selection_cursor = 1
				elif menu_type == 3: selection_cursor = 6
				else: selection_cursor = 0
				$Cursor1.visible = false
				if menu_type == 1: file_print()
		
		PAUSE_SAVES:
			$Cursor1.visible = false
			
			if menu_input == 1:
				if extra_index != 1:
					selection_cursor = 1
					menu_type = 0
				else:
					extra_index = 0
					selection_cursor = dummy_cursor
				return
			
			#file_print() -> Done once transitioning here from PAUSE_NORMAL
			$PauseText1/FileCursor.modulate = Color(1,1,1) if extra_index == 0 else Color(0,1,0)
			$PauseText1/YNCursor.visible = extra_index == 1
			
			if menu_input == 2:
				if extra_index == 0:
					$PauseText1/FileCursor.modulate = Color(0,1,0)
					extra_index = 1
					dummy_cursor = selection_cursor
					selection_cursor = 1
					
					# If file already empty, no need to ask to override
					if $PauseText1.find_node('File'+str(dummy_cursor+1)).find_node('EmptyText').visible:
						extra_index = 2
						Globals.save_current_game_to_file(dummy_cursor + 1)
						file_print()
						return
					
				elif extra_index == 1:
					if selection_cursor == 1:
						extra_index = 0
						selection_cursor = dummy_cursor
					else:
						extra_index = 2
						Globals.save_current_game_to_file(dummy_cursor + 1)
						file_print()
				else:
					extra_index = 0
					selection_cursor = 1
					menu_type = PAUSE_NORMAL
					return
			$PauseText1/OverrideText.visible = extra_index == 1
			$PauseText1/SaveComplete.visible = extra_index == 2
			
			if extra_index == 0:
				if direction_input.y < 0:
					selection_cursor += 2 if selection_cursor % 3 == 0 else -1
				elif direction_input.y > 0:
					selection_cursor += -2 if selection_cursor % 3 == 2 else 1
				if direction_input.x != 0:
					selection_cursor = mod_wrap(selection_cursor + 3, 6)
				$PauseText1/FileCursor.position.x = 234 + (376 if selection_cursor >= 3 else 0)
				$PauseText1/FileCursor.position.y = 166 + 114*(selection_cursor % 3)
			elif extra_index == 1:
				if direction_input.x != 0:
					selection_cursor = mod_wrap(selection_cursor + 1, 2)
				$PauseText1/YNCursor.position = Vector2(540 + 150*selection_cursor,502)
		
		PAUSE_OPTIONS:
			$Cursor1.set_position(Vector2(416,512))
			$Cursor1.visible = selection_cursor == 6
			var unlocked_stuff = [Globals.air_dash_unlocked, Globals.armour_unlocked,
				Globals.ultimate_unlocked, true, true, true, true]
			selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 7)
			while not unlocked_stuff[selection_cursor]:
				selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 7)
			var options_index = ["AirDashLabel", "ArmourLabel", "UltimateLabel", "HealthLabel",
				"MusicLabel", "SFXLabel"]
			if selection_cursor < 6:
				$PauseText3.find_node(options_index[selection_cursor]).modulate = Color(1,1,0)
			
			# Flip switches
			if selection_cursor == 0 and ((direction_input.y == 0 and direction_input.x != 0) or menu_input == 2):
				if menu_input == 2 or Globals.air_dash_selected == (direction_input.x < 0):
					Globals.air_dash_selected = not Globals.air_dash_selected
			elif selection_cursor == 1 and ((direction_input.y == 0 and direction_input.x != 0) or menu_input == 2):
				if menu_input == 2 or Globals.armour_selected == (direction_input.x < 0):
					Globals.armour_selected = not Globals.armour_selected
			elif selection_cursor == 2 and ((direction_input.y == 0 and direction_input.x != 0) or menu_input == 2):
				if menu_input == 2 or Globals.ultimate_selected == (direction_input.x < 0):
					Globals.ultimate_selected = not Globals.ultimate_selected
			
			elif selection_cursor == 3 and direction_input.y == 0 and direction_input.x != 0:
				if direction_input.x > 0: Globals.set_health = int(min(Globals.get_max_health(),
					Globals.set_health + 2)) if Globals.set_health != 1 else 2
				elif direction_input.x < 0: Globals.set_health = int(max(1,Globals.set_health - 2))
			
			elif selection_cursor == 4 and (direction_input.y == 0 and direction_input.x != 0):
				if direction_input.x > 0: Globals.music_volume = min(1, Globals.music_volume + 0.125)
				elif direction_input.x < 0: Globals.music_volume = max(0, Globals.music_volume - 0.125)
			elif selection_cursor == 5 and (direction_input.y == 0 and direction_input.x != 0):
				if direction_input.x > 0: Globals.sfx_volume = min(1, Globals.sfx_volume + 0.125)
				elif direction_input.x < 0: Globals.sfx_volume = max(0, Globals.sfx_volume - 0.125)
			
			if menu_input == 1 or (selection_cursor == 6 and menu_input == 2):
				selection_cursor = 3
				menu_type = 0
				$Cursor1.visible = false
				Globals.save_volume_data()
				return
		
		PAUSE_CONTROLS:
			if selection_cursor == 10:
				if direction_input.y < 0: selection_cursor = 4
				elif direction_input.y > 0: selection_cursor = 0
			elif direction_input.x != 0:
				selection_cursor = mod_wrap(selection_cursor + 5, 10)
			elif (selection_cursor == 0 or selection_cursor == 5) and direction_input.y < 0:
				selection_cursor = 10
			elif (selection_cursor == 4 or selection_cursor == 9) and direction_input.y > 0:
				selection_cursor = 10
			else: selection_cursor += direction_input.y
			
			if menu_input == 1 or (selection_cursor == 10 and menu_input == 2):
				selection_cursor = 4
				menu_type = 0
				$Cursor2.visible = false
				Globals.save_controls_data()
				return
			if selection_cursor == 10: $Cursor2.set_position(Vector2(422, 482))
			else:
				$Cursor2.set_position(Vector2(236 if selection_cursor <= 4 else 604,
				255 + 42*(selection_cursor % 5)))
			
			display_controls()
			
			if is_editing_control:
				return
			if menu_input == 2:
				is_editing_control = true
				$Cursor2.modulate = Color(0,1,0)
		
		PAUSE_TITLE:
			selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 2)
			$Cursor1.set_position(Vector2(250, 274 + 84*selection_cursor))
			if menu_input == 1 or (selection_cursor == 1 and menu_input == 2):
				selection_cursor = 5
				menu_type = 0
				$Cursor1.visible = false
			elif selection_cursor == 0 and menu_input == 2:
				is_transitioning = true
				input_delay = 120
				Globals.start_transition(Vector2(420, 300), 1)
				$Cursor1.modulate = Color(0,1,0)

# Some following functions are clones of ones from TitleScreen.gd
func get_menu_direction():
	var x_dir = 1 if Input.is_action_just_pressed("move_right") else (
		-1 if Input.is_action_just_pressed("move_left") else 0)
	var y_dir = 1 if Input.is_action_just_pressed("move_down") else (
		-1 if Input.is_action_just_pressed("move_up") else 0)
	return Vector2(x_dir, y_dir)

func get_menu_inputs():
	if Globals.lock_input: return 0
	if Input.is_action_just_pressed("pause"):
		return 3
	elif Input.is_action_just_pressed("attack"):
		return 1
	elif Input.is_action_just_pressed("jump"):
		return 2
	return 0

func mod_wrap(input_num, mod_amt):
	if input_num > 0: return input_num % mod_amt
	return mod_wrap(input_num + mod_amt, mod_amt)

func display_controls():
	var input_label_dict = {
		'UpButtonLabel':'move_up', 'DownButtonLabel':'move_down', 'LeftButtonLabel':'move_left',
		'RightButtonLabel':'move_right', 'JumpButtonLabel':'jump', 'AttackButtonLabel':'attack',
		'DashButtonLabel':'dash', 'PauseButtonLabel':'pause',
		'ShiftLButtonLabel': 'toggle_weapons_l', 'ShiftRButtonLabel': 'toggle_weapons_r'}
	if is_editing_control: return
	for label in input_label_dict:
		$PauseText4.find_node(label).text = OS.get_scancode_string(InputMap.get_action_list(input_label_dict[label])[0].scancode)
		if InputMap.get_action_list(input_label_dict[label]).size() > 1:
			if InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadButton:
				$PauseText4.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].button_index)
			elif InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadMotion:
				$PauseText4.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].axis) + (
					(" +" if InputMap.get_action_list(input_label_dict[label])[1].get_axis_value() > 0 else " -")
				)

func _unhandled_input(event):
	if not is_editing_control: return
	if (event is InputEventKey or event is InputEventJoypadButton) and not event.pressed: return
	
	var action_name = input_index_to_str(selection_cursor)
	
	if event is InputEventKey:
		#get_tree().quit()
		var assigned_action = get_key_action(event)
		var assigned_action_name = input_index_to_str(assigned_action)
		
		if assigned_action == -1:
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
	 
	$Cursor2.modulate = Color(1,1,1)
	is_editing_control = false
	input_delay = 1

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

func input_index_to_str(n):
	if n in range(10):
		return ['move_up', 'move_down', 'move_left', 'move_right', 'toggle_weapons_l',
		'jump', 'attack', 'dash', 'pause', 'toggle_weapons_r'][n]
	return ''

# Loads the visuals of the switches in the options menu
func options_menu_visuals():
	$PauseText3/AirDashLabel.text = "AIR DASH" if Globals.air_dash_unlocked else "?????"
	$PauseText3/AirDashLabel.modulate = Color(1,1,1) if Globals.air_dash_unlocked else Color(0.5,0.5,0.5)
	$PauseText3/ArmourLabel.text = "ARMOUR" if Globals.armour_unlocked else "?????"
	$PauseText3/ArmourLabel.modulate = Color(1,1,1) if Globals.armour_unlocked else Color(0.5,0.5,0.5)
	$PauseText3/UltimateLabel.text = "ULTIMATE" if Globals.ultimate_unlocked else "?????"
	$PauseText3/UltimateLabel.modulate = Color(1,1,1) if Globals.ultimate_unlocked else Color(0.5,0.5,0.5)
	
	$PauseText3/HealthLabel.modulate = Color(1,1,1)
	$PauseText3/MusicLabel.modulate = Color(1,1,1)
	$PauseText3/SFXLabel.modulate = Color(1,1,1)
	
	# Switch positions
	if Globals.air_dash_selected and $PauseText3/Switch1.get_position().x < 513:
		$PauseText3/Switch1.set_position($PauseText3/Switch1.get_position() + Vector2(4.75,0))
	elif not Globals.air_dash_selected and $PauseText3/Switch1.get_position().x > 475:
		$PauseText3/Switch1.set_position($PauseText3/Switch1.get_position() + Vector2(-4.75,0))
	if Globals.armour_selected and $PauseText3/Switch2.get_position().x < 513:
		$PauseText3/Switch2.set_position($PauseText3/Switch2.get_position() + Vector2(4.75,0))
	elif not Globals.armour_selected and $PauseText3/Switch2.get_position().x > 475:
		$PauseText3/Switch2.set_position($PauseText3/Switch2.get_position() + Vector2(-4.75,0))
	if Globals.ultimate_selected and $PauseText3/Switch3.get_position().x < 513:
		$PauseText3/Switch3.set_position($PauseText3/Switch3.get_position() + Vector2(4.75,0))
	elif not Globals.ultimate_selected and $PauseText3/Switch3.get_position().x > 475:
		$PauseText3/Switch3.set_position($PauseText3/Switch3.get_position() + Vector2(-4.75,0))
	
	# Meter positions
	$PauseText3/MusicFill.set_size(Vector2(496*Globals.music_volume,12))
	$PauseText3/MusicSlider.position = Vector2(496*Globals.music_volume + 251, 412)
	$PauseText3/SFXFill.set_size(Vector2(496*Globals.sfx_volume,12))
	$PauseText3/SFXSlider.position = Vector2(496*Globals.sfx_volume + 251, 458)
	
	# Switch colours
	$PauseText3/Switch1.modulate = Color(($PauseText3/Switch1.get_position().x-475)*(-7)/380 + 1,
		($PauseText3/Switch1.get_position().x-475)*(2)/380 + 1,
		($PauseText3/Switch1.get_position().x-475)*(-2)/380 + 1)
	$PauseText3/Switch2.modulate = Color(($PauseText3/Switch2.get_position().x-475)*(-7)/380 + 1,
		($PauseText3/Switch2.get_position().x-475)*(2)/380 + 1,
		($PauseText3/Switch2.get_position().x-475)*(-2)/380 + 1)
	$PauseText3/Switch3.modulate = Color(($PauseText3/Switch3.get_position().x-475)*(-7)/380 + 1,
		($PauseText3/Switch3.get_position().x-475)*(2)/380 + 1,
		($PauseText3/Switch3.get_position().x-475)*(-2)/380 + 1)
	
	# Health meter
	# warning-ignore:integer_division
	$PauseText3/HealthMeter/HealthTens.frame = Globals.set_health / 10
	$PauseText3/HealthMeter/HealthOnes.frame = Globals.set_health % 10
	$PauseText3/HealthMeterColor.set_size(Vector2(8*Globals.set_health,20))
	var modulate_for_health = Color(
		-0.00645*Globals.set_health + 0.7,
		0.01102*Globals.set_health + 0.25,
		0.3
	)
	$PauseText3/HealthMeterColor.modulate = modulate_for_health
	
	$PauseText3/HealthMeter/HealthOnes.modulate = modulate_for_health
	$PauseText3/HealthMeter/HealthTens.modulate = modulate_for_health

func file_print():
	for i in range(6):
		var file_display = $PauseText1.find_node('File'+str(i+1))
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
