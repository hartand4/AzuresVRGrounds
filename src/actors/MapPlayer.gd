extends KinematicBody2D


export onready var on_level
var direction := Vector2.ZERO
var anim_dict := {Vector2.UP: "Backward", Vector2.DOWN: "Forward",
				  Vector2.LEFT: "Left", Vector2.RIGHT: "Left"}

var is_moving := false
var turning_ccw := false
var turning_cw := false
var turning_timer := 0
const TURNING_TIMER_SET := 15

# Mini state things
var animation_timer := 0
var entering_level = false

var orig_dir = Vector2.ZERO

onready var transition_layer = get_parent().find_node('Transition')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	entering_level = false
	animation_timer = 40
	call_deferred("_do_transition")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#set_transition_position()
	
	if is_moving:
		animate_direction()
		
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
		
		position += 160 * delta * Vector2(direction.x, direction.y*0.8)
		
		if on_level and get_global_position().distance_to(on_level.get_global_position()) < 4:
			is_moving = false
			global_position = on_level.get_global_position()
		return
	
	# Rare instance of not being on level
	if not on_level:
		animate_direction()
		return
	
	# Not moving and on a level
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		if Input.is_action_just_pressed("pause") and not Globals.lock_input:
			Globals.game_paused = false
		do_pause_menu()
		return
	elif Input.is_action_just_pressed("pause") and not Globals.lock_input and not entering_level:
		Globals.game_paused = true
		do_pause_menu()
		return
	
	if animation_timer: animation_timer -= 1
	if entering_level:
		$AnimationPlayer.play("Start")
		if animation_timer == 0:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/TestLevel.tscn")
		return
	
	if Globals.lock_input or animation_timer: return
	
	direction = get_direction_movement()
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
		animate_direction()
	
	if not is_moving:
		if Input.is_action_just_pressed("pause"):
			Globals.game_paused = true
	
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack"):
		transition_layer.start_transition(get_position() - $Camera2D.get_camera_screen_center() + Vector2(420,300), true)
		animation_timer = 120
		entering_level = true

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

func animate_direction():
	var dir = closest_right_angle(direction)
	if dir == Vector2.RIGHT:
		$MapSprite.flip_h = true
	else:
		$MapSprite.flip_h = false

	if dir == Vector2.ZERO:
		$AnimationPlayer.play("Forward")
	else:
		$AnimationPlayer.play(anim_dict[dir])

func _on_LevelCheckArea_area_entered(area: Area2D) -> void:
	if not area.get('level_number') == null:
		on_level = area
		print(on_level)
		return
	if turning_ccw or turning_cw:
		return
	orig_dir = direction
	if area.get_collision_layer_bit(0):
		if direction.y != 0:
			turning_ccw = true
			set_turning_timer()
			return
		if direction.x != 0:
			turning_cw = true
			set_turning_timer()
			return
	elif area.get_collision_layer_bit(1):
		if direction.x != 0:
			turning_ccw = true
			set_turning_timer()
			return
		if direction.y != 0:
			turning_cw = true
			set_turning_timer()
			return

func set_turning_timer():
	turning_timer = TURNING_TIMER_SET
	return

func closest_right_angle(dir):
	if dir == Vector2.ZERO: return dir
	if dir.x > -dir.y:
		if -dir.y > -dir.x:
			return Vector2.RIGHT
		return Vector2.DOWN
	if -dir.y > -dir.x:
		return Vector2.UP
	return Vector2.LEFT

func do_pause_menu(): #TODO
	pass

func _do_transition():
	Globals.start_transition(Vector2(420, 300), false)
