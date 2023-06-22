extends Area2D

# 1 for clockwise, -1 for ccw
export var starting_dir := 1
export var sticking_to := 0
export var speed := 1
export var has_been_in := false

onready var side_list = [$DownCheck, $LeftCheck, $UpCheck, $RighttCheck]
var direction_list = [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	$AnimationPlayer.play("Rotate")
	$AnimationPlayer.playback_speed = speed*1.5
	$Sprite.flip_h = starting_dir > 0
	position += direction_list[mod_wrap(sticking_to - starting_dir, 4)]*speed
	move_to_nearest_tile()
	
	if has_exited():
		sticking_to = mod_wrap(sticking_to + starting_dir, 4)
		move_to_nearest_tile()
		has_been_in = false
	elif has_entered():
		sticking_to = mod_wrap(sticking_to - starting_dir, 4)
		move_to_nearest_tile()


func has_exited():
	for body in side_list[sticking_to].get_overlapping_bodies():
		if body.get_collision_layer_bit(0):
			has_been_in = true
			return false
	return has_been_in

func has_entered():
	for body in side_list[mod_wrap(sticking_to - starting_dir, 4)].get_overlapping_bodies():
		if body.get_collision_layer_bit(0):
			return true
	return false

func move_to_nearest_tile():
	if sticking_to == 0:
		position.y = ceil(position.y/48)*48 - 21
	elif sticking_to == 1:
		position.x = floor(position.x/48)*48 + 21
	elif sticking_to == 2:
		position.y = floor(position.y/48)*48 + 21
	else:
		position.x = ceil(position.x/48)*48 - 21

func get_damage():
	return 6

func mod_wrap(input_num, mod_amt):
	if input_num > 0: return input_num % mod_amt
	return mod_wrap(input_num + mod_amt, mod_amt)
