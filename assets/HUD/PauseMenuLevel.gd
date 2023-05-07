extends TextureRect


const PAUSE_NORMAL := 0
const PAUSE_CONTROLS := 2
const PAUSE_RETURN := 1
const PAUSE_TITLE := 3

var menu_type := PAUSE_NORMAL
var selection_cursor := 0

var input_delay = 1
var is_transitioning = false

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
			get_tree().change_scene("res://src/levels/LevelMap.tscn")
		elif menu_type == 3:
			get_tree().change_scene("res://src/levels/TitleScreen.tscn")
		return
	
	for i in [0,1,2,3]:
		find_node("PauseText" + str(i)).visible = false
	find_node("PauseText" + str(menu_type)).visible = true
	$Cursor1.visible = menu_type != 2
	$Cursor2.visible = menu_type == 2
	
	var menu_input = get_menu_inputs()
	var direction_input = Vector2.ZERO if menu_input else get_menu_direction()
	
	if menu_input == 3:
		Globals.pause_menu_on = false
		Globals.game_paused = false
		return
	
	match menu_type:
		0:
			selection_cursor = (selection_cursor + int(direction_input.y)) % 4
			$Cursor1.set_position(Vector2(255, 202 + 84*selection_cursor))
			
			if selection_cursor == 0 and menu_input == 2:
				Globals.pause_menu_on = false
				Globals.game_paused = false
				return
			elif menu_input == 2:
				menu_type = selection_cursor
				selection_cursor = 0 if menu_type == 2 else 1
		1:
			selection_cursor = (selection_cursor + int(direction_input.y)) % 2
			$Cursor1.set_position(Vector2(255, 328 + 84*selection_cursor))
			if menu_input == 1 or (selection_cursor == 1 and menu_input == 2):
				selection_cursor = 1
				menu_type = 0
			elif selection_cursor == 0 and menu_input == 2:
				is_transitioning = true
				input_delay = 120
				Globals.start_transition(Vector2(420, 300), true)
		2:
			if menu_input == 1:
				selection_cursor = 2
				menu_type = 0
		3:
			selection_cursor = (selection_cursor + int(direction_input.y)) % 2
			$Cursor1.set_position(Vector2(255, 328 + 84*selection_cursor))
			if menu_input == 1 or (selection_cursor == 1 and menu_input == 2):
				selection_cursor = 3
				menu_type = 0
			elif selection_cursor == 0 and menu_input == 2:
				is_transitioning = true
				input_delay = 120
				Globals.start_transition(Vector2(420, 300), true)


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
