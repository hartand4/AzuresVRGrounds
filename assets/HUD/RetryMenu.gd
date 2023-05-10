extends TextureRect


var selection_cursor := false
var input_delay = 1
var is_transitioning = false

func _ready() -> void:
	$RetryCursor.set_position(Vector2(163, 82))

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if not Globals.retry_menu_on:
		selection_cursor = false
		input_delay = 1
		return
	if input_delay and not is_transitioning:
		input_delay -= 1
		$RetryCursor.visible = false
		return
	elif input_delay and is_transitioning:
		input_delay -= 1
		return
	elif is_transitioning and not input_delay:
		Globals.retry_menu_on = false
		Globals.game_paused = false
		if selection_cursor:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/LevelMap.tscn")
		else:
			# warning-ignore:return_value_discarded
			Globals.find_player().reload_level()
		return
	
	$RetryCursor.visible = true
	$RetryCursor.set_position(Vector2(163, 168 if selection_cursor else 82))
	
	if Globals.lock_input: return
	if Input.is_action_just_pressed("jump"):
		is_transitioning = true
		input_delay = 120
		Globals.start_transition(Vector2(420, 300), true)
		$RetryCursor.modulate = Color(0,1,0)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_up"):
		selection_cursor = not selection_cursor
