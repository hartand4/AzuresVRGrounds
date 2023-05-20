extends Node2D


var animation_timer := 0
var title_screen_menu := 0

var title_gravity := 120
var title_velocity := 0
var bounce_nums = 4
var title_screen_variant = 0
var selection_cursor := 0
var is_editing_controls = false
var is_transitioning = true


func _ready() -> void:
	reset_title_screen()

func _process(delta: float) -> void:
	
	var menu_dir = get_menu_direction()
	var menu_input = get_menu_input()
	if menu_input: menu_dir = Vector2.ZERO
	if animation_timer:
		menu_dir = Vector2.ZERO
		menu_input = 0
	
	$FirstMenu/Cursor.visible = title_screen_menu == 2
	$FirstMenu.visible = title_screen_menu in [1,2]
	$ControlsMenu.visible = title_screen_menu == 4
	$ControlsMenu/Cursor.visible = title_screen_menu == 4
	
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
			# TODO: Load save file on map screen
			
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/LevelMap.tscn")
		return
	
	match title_screen_menu:
		0:
			$TitleObject/TitleVisibility/Title/Azzy/TailAnimation.play("TailWag")
			$TitleObject/TitleVisibility/Title/Azzy/AzzyAnimation.play("IdleBlink")
			$PressStart.visible = false
			if animation_timer:
				if title_screen_variant == 0:
					title_bounce(delta)
				elif title_screen_variant == 1:
					title_stretch_in()
				elif title_screen_variant == 2:
					title_build_upward()
			else:
				$TitleObject.set_position(Vector2(0,0))
				$TitleObject/TitleVisibility.set_size(Vector2(840,600))
				$TitleObject/TitleVisibility.set_position(Vector2(0,0))
				title_screen_menu = 1
		1:
			if not animation_timer:
				$TitleObject/TitleVisibility/Title/Azzy/TailAnimation.play("TailWag")
				$TitleObject/TitleVisibility/Title/Azzy/AzzyAnimation.play("IdleBlink")
				$PressStart.visible = Globals.timer % 60 < 40
				
				if menu_input == 2 or menu_input == 3:
					animation_timer = 120
					title_velocity = -25
			elif animation_timer > 60:
				$TitleObject/TitleVisibility/Title/Azzy/TailAnimation.play("TailWag")
				$PressStart.visible = Globals.timer % 15 < 8
				$TitleObject/TitleVisibility/Title/Azzy/AzzyAnimation.play("Jump" if animation_timer > 120 else "Fall")
				azzy_jump(delta)
			elif animation_timer > 1:
				$PressStart.visible = false
				$Camera2D.position = Vector2(1260,300)
			elif animation_timer == 1:
				selection_cursor = 0
				title_screen_menu = 2
		2:
			selection_cursor = mod_wrap(selection_cursor + int(menu_dir.y), 5)
			$FirstMenu/Cursor.set_position(Vector2(240,108 + 82*selection_cursor))
			if menu_input == 2:
				if selection_cursor == 0:
					Globals.start_transition(Vector2.ZERO, 5)
					animation_timer = 75
					is_transitioning = true
				elif selection_cursor == 1:
					pass
				elif selection_cursor == 2:
					selection_cursor = 8
					title_screen_menu = 4
				elif selection_cursor == 3:
					Globals.start_transition(Vector2.ZERO, 5)
					animation_timer = 75
					is_transitioning = true
				elif selection_cursor == 4:
					$FirstMenu/Cursor.modulate = Color(0,1,0)
					get_tree().quit()
				
		3:
			pass
		4:
			if selection_cursor == 8:
				if menu_dir.y < 0: selection_cursor = 3
				elif menu_dir.y > 0: selection_cursor = 0
			elif menu_dir.x != 0:
				selection_cursor = mod_wrap(selection_cursor + 4, 8)
			elif (selection_cursor == 0 or selection_cursor == 4) and menu_dir.y < 0:
				selection_cursor = 8
			elif (selection_cursor == 3 or selection_cursor == 7) and menu_dir.y > 0:
				selection_cursor = 8
			else: selection_cursor += menu_dir.y
			
			if menu_input == 1 or (selection_cursor == 8 and menu_input == 2):
				selection_cursor = 2
				title_screen_menu = 2
				$ControlsMenu/Cursor.visible = false
				return
			if selection_cursor == 8: $ControlsMenu/Cursor.set_position(Vector2(382, 453))
			else:
				$ControlsMenu/Cursor.set_position(Vector2(196 if selection_cursor <= 3 else 564,
				243 + 42*(selection_cursor % 4)))
			$ControlsMenu/Cursor.set_position($ControlsMenu/Cursor.get_position() + Vector2(-148,-16))
			
			display_controls()
			
			if is_editing_controls:
				return
			if menu_input == 2:
				is_editing_controls = true
				$ControlsMenu/Cursor.modulate = Color(0,1,0)
		
	if animation_timer:
		animation_timer -= 1

func title_bounce(delta):
	if not bounce_nums:
		$TitleObject.set_position(Vector2(0,0))
		return
	if $TitleObject.get_position().y >= 0 and title_velocity > 0 and bounce_nums:
		title_velocity = -9*bounce_nums
		bounce_nums -= 1
	if bounce_nums:
		title_velocity += title_gravity*delta
		$TitleObject.set_position(Vector2($TitleObject.get_position() + Vector2(0,title_velocity)))

func title_stretch_in():
	var current_size = $TitleObject/TitleVisibility.get_size()
	$TitleObject/TitleVisibility.set_size(current_size + Vector2(20,0))
	$TitleObject/TitleVisibility.set_position(Vector2(420-(current_size.x)/2, 0))
	$TitleObject/TitleVisibility/Title.set_position(Vector2(-420+(current_size.x)/2, 0))
	if current_size.x >= 840:
		$TitleObject/TitleVisibility.set_size(Vector2(840,600))
		$TitleObject/TitleVisibility.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility/Title.set_position(Vector2(0, 0))

func title_build_upward():
	var current_size = $TitleObject/TitleVisibility.get_size()
	$TitleObject/TitleVisibility.set_size(current_size + Vector2(0,15))
	$TitleObject/TitleVisibility.set_position(Vector2(0, 600-current_size.y))
	$TitleObject/TitleVisibility/Title.set_position(Vector2(0, current_size.y-600))
	if current_size.y >= 600:
		$TitleObject/TitleVisibility.set_size(Vector2(840,600))
		$TitleObject/TitleVisibility.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility/Title.set_position(Vector2.ZERO)

func get_menu_direction():
	var x_dir = 1.0 if Input.is_action_just_pressed("move_right") else (
		-1.0 if Input.is_action_just_pressed("move_left") else 0.0)
	var y_dir = 1.0 if Input.is_action_just_pressed("move_down") else (
		-1.0 if Input.is_action_just_pressed("move_up") else 0.0)
	return Vector2(x_dir, y_dir)

func get_menu_input():
	if Input.is_action_just_pressed("jump"):
		return 2
	if Input.is_action_just_pressed("attack"):
		return 1
	if Input.is_action_just_pressed("pause"):
		return 3
	return 0

func reset_title_screen():
	title_screen_variant = Globals.call_rng(0,2)
	animation_timer = 100
	selection_cursor = 0
	title_screen_menu = 0
	title_velocity = 0
	is_transitioning = false
	is_editing_controls = false
	$PressStart.visible = false
	$TitleObject/TitleVisibility/Title/Azzy.set_position(Vector2(725,172))
	$Camera2D.position = Vector2(420,300)
	if title_screen_variant == 0:
		$TitleObject.set_position(Vector2(0,-500))
		bounce_nums = 4
		return
	if title_screen_variant == 1:
		$TitleObject.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility.set_size(Vector2(0,600))
		$TitleObject/TitleVisibility.set_position(Vector2(420,0))
		$TitleObject/TitleVisibility/Title.set_position(Vector2(-420,0))
		return
	if title_screen_variant == 2:
		$TitleObject.set_position(Vector2.ZERO)
		$TitleObject/TitleVisibility.set_size(Vector2(840,0))
		$TitleObject/TitleVisibility.set_position(Vector2(0,600))
		$TitleObject/TitleVisibility/Title.set_position(Vector2(-600,0))
		return

func azzy_jump(delta):
	title_velocity += 60*delta
	var current_pos = $TitleObject/TitleVisibility/Title/Azzy.get_position()
	$TitleObject/TitleVisibility/Title/Azzy.set_position(current_pos+Vector2(-4,title_velocity))

func mod_wrap(input_num, mod_amt):
	if input_num > 0: return input_num % mod_amt
	return mod_wrap(input_num + mod_amt, mod_amt)

func display_controls():
	var input_label_dict = {
		'UpButtonLabel':'move_up', 'DownButtonLabel':'move_down', 'LeftButtonLabel':'move_left',
		'RightButtonLabel':'move_right', 'JumpButtonLabel':'jump', 'AttackButtonLabel':'attack',
		'DashButtonLabel':'dash', 'PauseButtonLabel':'pause'}
	if is_editing_controls: return
	for label in input_label_dict:
		$ControlsMenu/PauseText2.find_node(label).text = OS.get_scancode_string(InputMap.get_action_list(input_label_dict[label])[0].scancode)
		if InputMap.get_action_list('move_up').size() > 1:
			if InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadButton:
				$ControlsMenu/PauseText2.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].button_index)
			elif InputMap.get_action_list(input_label_dict[label])[1] is InputEventJoypadMotion:
				$ControlsMenu/PauseText2.find_node(label).text += ', Joypad: ' + str(InputMap.get_action_list(input_label_dict[label])[1].axis)

func _unhandled_input(event):
	if not is_editing_controls: return
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
	 
	$ControlsMenu/Cursor.modulate = Color(1,1,1)
	is_editing_controls = false
	animation_timer = 1

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
