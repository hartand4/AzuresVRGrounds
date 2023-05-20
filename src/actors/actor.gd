extends KinematicBody2D
class_name Actor


const FLOOR_NORMAL := Vector2.UP

export var speed := Vector2(300.0,1200.0)
export var gravity := 1200.0
export var up_gravity := 3000.0
var _velocity := Vector2.ZERO
export var recurring_x_dir = -1
export var state := 0
export var animation_timer := 0

onready var _animation := $AnimationPlayer
onready var _player = Globals.find_player()

# Player state constants:
const ST_IDLE := 0
const ST_WALK := 1
const ST_DASH := 2
const ST_AIR := 3
const ST_ATTACK := 4
const ST_AIR_ATTACK := 5
const ST_HURT := 6
const ST_INTERACT := 7 # Necessary?
const ST_WALLSLIDE := 8
const ST_WALLJUMP := 9
const ST_CLIMB := 10
const ST_WALL_ATTACK := 11
const ST_LADDER_ATTACK := 12
const ST_VICTORY := 13

# Enemy State constants:
const EN_IDLE := 0
const EN_WALK := 1
const EN_AIR := 2
const EN_ATTACK := 3
const EN_HURT := 4
const EN_DEAD := 5


func _physics_process(delta: float) -> void:
	if _player and (Globals.get("game_paused") or Globals.pause_menu_on):
		return
	
	# Perform gravity updates (different for upward gravity)
	if _velocity.y > 0: _velocity.y += gravity*delta
	else: _velocity.y += up_gravity*delta
	
	# Cap speed at a certain point
	_velocity.y = min(_velocity.y, speed.y)
	

# warning-ignore:unused_argument
func _process(delta):
	var last_state := state
	state = update_state()
	if state != last_state:
		animation_timer = 0
	
	if not Globals.get("game_paused") and not Globals.pause_menu_on:
		animation_handler()
		animation_timer += 1
	else:
		_animation.stop(false)

func animation_handler():
	return

func get_velocity():
	return _velocity
func set_velocity(vel):
	_velocity = vel
	
func update_state():
	return state
	
func nearest_block(pos):
	return pos - fmod(pos, 48) + 24
	
func bitwise_check(bits, num):
	return bits & int(pow(2, (num-1)))

func unit_direction_vector(dir1, dir2):
	if dir2 == dir1: return 0.0
	return (dir2 - dir1)/abs(dir2 - dir1)
