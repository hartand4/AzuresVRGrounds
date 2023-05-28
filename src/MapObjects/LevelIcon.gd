extends Area2D


export var level_number := 0
export var warp_number := 0
export var level_name := ""
export var is_warp := false
export var is_boss := false
export var is_unlocked := false
export var is_complete := false
var anim_str := ""

# List of paths on map
export var has_up_path := false
export var has_down_path := false
export var has_left_path := false
export var has_right_path := false
var path_list := [false, false, false, false]

# Event types on map
# Map event will be level_number * 2 for normal exit, (level_number*2+1) for secret exit
export var got_normal_exit := false
export var got_secret_exit := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path_list = [has_up_path, has_down_path, has_left_path, has_right_path]
	if is_warp:
		anim_str = "WarpTile"
		$AnimationPlayer.play("WarpTile")
		return
	anim_str = "Yellow" if is_complete else "Red" if is_unlocked else "Grey"
	anim_str += "Boss" if is_boss else "Level"
	$AnimationPlayer.play(anim_str)

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	path_list = [has_up_path, has_down_path, has_left_path, has_right_path]
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	$AnimationPlayer.play(anim_str)
	
func mark_completed():
	is_complete = true
	anim_str = "Yellow" + ("Boss" if is_boss else "Level")

func mark_unlocked():
	is_unlocked = true
	anim_str = "Yellow" if is_complete else "Red"
	anim_str += "Boss" if is_boss else "Level"
