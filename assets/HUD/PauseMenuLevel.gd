extends TextureRect


const PAUSE_NORMAL := 0
const PAUSE_CONTROLS := 2
const PAUSE_RETURN := 1
const PAUSE_TITLE := 3

var menu_type := PAUSE_NORMAL
var selection_cursor := 0

var input_delay = 1
var is_transitioning = false
var is_editing_control = false

func _ready() -> void:
	$Cursor1.set_position(Vector2(255, 202 + 84*selection_cursor))


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if not Globals.pause_menu_on:
		menu_type = PAUSE_NORMAL
		selection_cursor = 0
		input_delay = 1
		return
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
		if menu_type == 1:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/LevelMap.tscn")
		elif menu_type == 3:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/TitleScreen.tscn")
		return
	
	for i in [0,1,2,3]:
		find_node("PauseText" + str(i)).visible = false
	find_node("PauseText" + str(menu_type)).visible = true
	$Cursor1.visible = menu_type != 2
	$Cursor2.visible = menu_type == 2
	
	var menu_input = get_menu_inputs()
	var direction_input = Vector2.ZERO if menu_input else get_menu_direction()
	if is_editing_control:
		menu_input = 0
		direction_input = Vector2.ZERO
	
	if menu_input == 3:
		Globals.pause_menu_on = false
		Globals.game_paused = false
		return
	
	match menu_type:
		0:
			selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 4)
			$Cursor1.set_position(Vector2(255, 202 + 84*selection_cursor))
			
			if selection_cursor == 0 and menu_input == 2:
				Globals.pause_menu_on = false
				Globals.game_paused = false
				return
			elif menu_input == 2:
				menu_type = selection_cursor
				selection_cursor = 8 if menu_type == 2 else 1
				$Cursor1.visible = false
		1:
			selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 2)
			$Cursor1.set_position(Vector2(255, 328 + 84*selection_cursor))
			if menu_input == 1 or (selection_cursor == 1 and menu_input == 2):
				selection_cursor = 1
				menu_type = 0
				$Cursor1.visible = false
			elif selection_cursor == 0 and menu_input == 2:
				is_transitioning = true
				input_delay = 120
				Globals.start_transition(Vector2(420, 300), true)
				$Cursor1.modulate = Color(0,1,0)
		2:
			if selection_cursor == 8:
				if direction_input.y < 0: selection_cursor = 3
				elif direction_input.y > 0: selection_cursor = 0
			elif direction_input.x != 0:
				selection_cursor = mod_wrap(selection_cursor + 4, 8)
			elif (selection_cursor == 0 or selection_cursor == 4) and direction_input.y < 0:
				selection_cursor = 8
			elif (selection_cursor == 3 or selection_cursor == 7) and direction_input.y > 0:
				selection_cursor = 8
			else: selection_cursor += direction_input.y
			
			if menu_input == 1 or (selection_cursor == 8 and menu_input == 2):
				selection_cursor = 2
				menu_type = 0
				$Cursor2.visible = false
				return
			if selection_cursor == 8: $Cursor2.set_position(Vector2(382, 453))
			else:
				$Cursor2.set_position(Vector2(196 if selection_cursor <= 3 else 564,
				243 + 42*(selection_cursor % 4)))
			
			display_controls()
			
			if is_editing_control:
				return
			if menu_input == 2:
				is_editing_control = true
				$Cursor2.modulate = Color(0,1,0)
			
		3:
			selection_cursor = mod_wrap(selection_cursor + int(direction_input.y), 2)
			$Cursor1.set_position(Vector2(255, 328 + 84*selection_cursor))
			if menu_input == 1 or (selection_cursor == 1 and menu_input == 2):
				selection_cursor = 3
				menu_type = 0
				$Cursor1.visible = false
			elif selection_cursor == 0 and menu_input == 2:
				is_transitioning = true
				input_delay = 120
				Globals.start_transition(Vector2(420, 300), true)
				$Cursor1.modulate = Color(0,1,0)

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
		'DashButtonLabel':'dash', 'PauseButtonLabel':'pause'}
	if is_editing_control: return
	for label in input_label_dict:
		$PauseText2.find_node(label).text = OS.get_scancode_string(InputMap.get_action_list(input_label_dict[label])[0].scancode)
		if InputMap.get_action_list('move_up').size() > 1:
			if InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadButton:
				$PauseText2.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].button_index)
			elif InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadMotion:
				$PauseText2.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].axis)

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
		for i in range(8):
			if event_button_index == InputMap.get_action_list(input_index_to_str(i))[0].scancode:
				return i
		return -1
	
	# If instead event is a joypad thing
	elif event is InputEventJoypadButton:
		event_button_index = event.button_index
		for i in range(8):
			var input_on_map = InputMap.get_action_list(input_index_to_str(i))[1]
			if input_on_map is InputEventJoypadButton and event_button_index == input_on_map.button_index:
				return i
		return -1
	
	elif event is InputEventJoypadMotion:
		event_button_index = event.axis
		for i in range(8):
			var input_on_map = InputMap.get_action_list(input_index_to_str(i))[1]
			if input_on_map is InputEventJoypadMotion and event_button_index == input_on_map.axis:
				return i
		return -1
	return -1

func input_index_to_str(n):
	if n in range(8):
		return ['move_up', 'move_down', 'move_left', 'move_right', 
		'jump', 'attack', 'dash', 'pause'][n]
	return ''
