extends KinematicBody2D


export onready var on_level
var direction := Vector2.ZERO
var anim_dict := {Vector2.UP: "Backward", Vector2.DOWN: "Forward",
				  Vector2.LEFT: "Left", Vector2.RIGHT: "Right"}

var is_moving := false
var turning_ccw := false
var turning_cw := false
var turning_timer := 0
const TURNING_TIMER_SET := 15

# Mini state things
var animation_timer := 0
var entering_level = false
var is_warping = false

var orig_dir = Vector2.ZERO
var on_ladder = false

func _ready() -> void:
	entering_level = false
	animation_timer = 40
	call_deferred("_do_transition")
	$MapSprite.flip_h = false
	
	if Globals.current_level < 300:
		on_level = self.get_parent().find_node('Levels').find_node('Level'+str(Globals.current_level))
	else:
		on_level = get_parent().find_node('Warps').find_node('Warp'+str(Globals.current_level - 300))
	self.position = on_level.position
	print('current level is ' + str(Globals.current_level))


func _process(_delta: float) -> void:
	# Check for camera limit areas
	camera_limit_checks()
		
	
	if is_moving:
		
		if not turning_timer and (turning_ccw or turning_cw):
			turning_ccw = false
			turning_cw = false
			direction = closest_right_angle(direction)
			
			if direction.x == 0:
				
				position.x = round((position.x-16)/32) * 32 + 16
			elif direction.y == 0:
				position.y = round((position.y-12)/16) * 16 + 12
		
		if turning_ccw:
			direction = Vector2(cos(direction.angle()-PI/(2*TURNING_TIMER_SET)),
			sin(direction.angle()-PI/(2*TURNING_TIMER_SET)))
			
		elif turning_cw:
			direction = Vector2(cos(direction.angle()+PI/(2*TURNING_TIMER_SET)),
			sin(direction.angle()+PI/(2*TURNING_TIMER_SET)))
		
		if turning_timer: turning_timer -= 1
		
		# Slight correction
		if turning_timer % 5 == 1:
			if orig_dir.y > 0:
				position.y -= 1
			elif orig_dir.y < 0:
				pass
			elif orig_dir.x > 0:
				position.x -= 1
			else:
				position.x += 1
		
		position += (8.0 / 3.0) * Vector2(direction.x, direction.y*0.8)
		
		if on_level and get_global_position().distance_to(on_level.get_global_position()) < 4:
			is_moving = false
			global_position = on_level.get_global_position()
			#direction = Vector2.ZERO
			
		animate_direction()
		return
	
	# Rare instance of not being on level
	if not on_level:
		animate_direction()
		return
	
	# Not moving and on a level
	if Globals.game_paused or Globals.pause_menu_on:
		$AnimationPlayer.stop(false)
		return
	elif Input.is_action_just_pressed("pause") and not Globals.lock_input and not entering_level and not is_warping:
		Globals.game_paused = true
		Globals.pause_menu_on = true
		return
	
	if animation_timer: animation_timer -= 1
	if entering_level:
		$AnimationPlayer.play("Start")
		if animation_timer == 0:
			var scene_name = get_parent().level_index_to_scene_name[on_level.level_number]
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/" + scene_name + ".tscn")
		return
	
	elif is_warping:
		if animation_timer == 1:
			var warp_info = get_parent().warp_info_list[on_level.warp_number]
			if warp_info[0]:
				position = get_parent().find_node("Warps").find_node("Warp" + str(warp_info[1])).get_position()
			else:
				position = get_parent().find_node("Levels").find_node("Level" + str(warp_info[1])).get_position()
			$Camera2D.smoothing_enabled = false
		elif animation_timer == 0:
			$Camera2D.smoothing_enabled = true
			is_warping = false
			animation_timer = 40
			Globals.start_transition(Vector2(0,0), 4)
		return
	
	animate_direction()
	if Globals.lock_input: return
	
	direction = get_direction_movement()
	if animation_timer: direction = Vector2.ZERO
	
	is_moving = true
	if direction.y > 0 and on_level.path_list[1]:
		print('going down')
		on_level = null
	elif direction.y < 0 and on_level.path_list[0]:
		print('going up')
		on_level = null
	elif direction.x < 0 and on_level.path_list[2]:
		print('going left')
		on_level = null
	elif direction.x > 0 and on_level.path_list[3]:
		print('going right')
		on_level = null
	else:
		is_moving = false
		direction = Vector2.ZERO
		animate_direction()
	
	if not is_moving:
		if Input.is_action_just_pressed("pause"):
			Globals.game_paused = true
	
	if (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack")) and not animation_timer:
		if not on_level.is_warp:
			Globals.start_transition(get_position() - $Camera2D.get_camera_screen_center() + Vector2(432,312), 1)
			animation_timer = 120
			entering_level = true
			Globals.goal_reached_in_current_level = [false, false]
			return
		else:
			Globals.start_transition(Vector2(432,312), 3)
			animation_timer = 40
			is_warping = true

# Get direction of input
func get_direction_movement():
	if Globals.lock_input: return Vector2.ZERO
	if Input.is_action_pressed("move_down"):
		return Vector2.DOWN
	if Input.is_action_pressed("move_up"):
		return Vector2.UP
	if Input.is_action_pressed("move_left"):
		return Vector2.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2.RIGHT
	return Vector2.ZERO

# Animate based on the movement direction, or if on ladder
func animate_direction():
	var dir = closest_right_angle(direction)
	if dir == Vector2.ZERO:
		$AnimationPlayer.play("Forward")
	elif on_ladder:
		$AnimationPlayer.play("Backward")
	else:
		$AnimationPlayer.play(anim_dict[dir])

# Checks when map player overlaps with areas
func _on_LevelCheckArea_area_entered(area: Area2D) -> void:
	
	# This should be a level/warp
	if not area.get('level_number') == null:
		on_level = area
		if area.level_number:
			Globals.current_level = area.level_number
		elif area.warp_number:
			Globals.current_level = area.warp_number + 300
		print(on_level)
		return
	
	# Ignore non-level areas when turning
	if turning_ccw or turning_cw:
		return
	orig_dir = direction
	
	# Area that asks player to turn -1/x style
	if area.get_collision_layer_bit(0):
		if direction.y != 0:
			turning_ccw = true
			set_turning_timer()
			return
		if direction.x != 0:
			turning_cw = true
			set_turning_timer()
			return
	
	# Area that asks player to turn 1/x style
	elif area.get_collision_layer_bit(1):
		if direction.x != 0:
			turning_ccw = true
			set_turning_timer()
			return
		if direction.y != 0:
			turning_cw = true
			set_turning_timer()
			return
	
	#Area is a ladder
	elif area.get_collision_layer_bit(2):
		on_ladder = true

# Sets variable turning_timer to TURNING_TIMER_SET
func set_turning_timer():
	turning_timer = TURNING_TIMER_SET

# Returns a vector of the nearest right angle to the given dir vector
func closest_right_angle(dir):
	if dir == Vector2.ZERO: return dir
	if dir.x > -dir.y:
		if -dir.y > -dir.x:
			return Vector2.RIGHT
		return Vector2.DOWN
	if -dir.y > -dir.x:
		return Vector2.UP
	return Vector2.LEFT

# Redundant function
func do_pause_menu():
	pass

# Specifies how to start a transition into a level
func _do_transition():
	Globals.start_transition(get_position() - $Camera2D.get_camera_screen_center() + Vector2(432,292), 2)

# May be good to specify some specific camera locations in the overworld (like the warp island)
func camera_limit_checks():
	# Warp Isle
	if position.x >= 5952 and position.x <= 6792 and position.y <= 240 and position.y >= 0:
		$Camera2D.limit_left = 5950
		$Camera2D.limit_right = 6804
		$Camera2D.limit_top = -112
		$Camera2D.limit_bottom = 512
	else:
		$Camera2D.limit_left = 0
		$Camera2D.limit_right = 10000000
		$Camera2D.limit_top = 0
		$Camera2D.limit_bottom = 10000000

# Only real concern is seeing if a ladder has been exited
func _on_LevelCheckArea_area_exited(area: Area2D) -> void:
	if area.get_collision_layer_bit(2): on_ladder = false
