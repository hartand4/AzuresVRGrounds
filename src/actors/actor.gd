extends KinematicBody2D
class_name Actor


const FLOOR_NORMAL := Vector2.UP

export var speed := Vector2(300.0,1200.0)
export var gravity := 1200.0
export var up_gravity := 3000.0
var _velocity := Vector2.ZERO
export var recurring_x_dir = -1
var state := 0
var animation_timer := 0
# Second animation timer that counts down
var anim_timer := 0
export var health := 1
var max_health := 1
var i_frames := 0

var original_pos := Vector2.ZERO

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
const ST_ULTIMATE := 14

# Enemy State constants:
const EN_IDLE := 0
const EN_WALK := 1
const EN_AIR := 2
const EN_ATTACK := 3
const EN_HURT := 4
const EN_DEAD := 5


func _ready():
	original_pos = self.position

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
		if anim_timer:
			anim_timer -= 1
		if i_frames:
			i_frames -= 1
	else:
		_animation.stop(false)

func animation_handler():
	return

func update_state():
	return state
	
func nearest_block(pos):
	return pos - fmod(pos, 48) + 24
	
func bitwise_check(bits, num):
	return bits & int(pow(2, (num-1)))

func unit_direction_vector(dir1, dir2):
	if dir2 == dir1: return 0.0
	return (dir2 - dir1)/abs(dir2 - dir1)

func in_camera_range(pos):
	var camera_pos = Globals.get_current_camera_pos()
	return camera_pos.x - 420 - 120 < pos.x and camera_pos.x + 420 + 120 > pos.x and (
		camera_pos.y - 300 - 120 < pos.y and camera_pos.y + 300 + 120 > pos.y)

func disable_all():
	health = max_health

func reset_values():
	state = 0
	anim_timer = 0
	health = max_health

# If an actor is destroyed, they should note it, set their position to their initial spawn, then attempt to respawn
# every frame before returning. As an example, see Anamoth.gd
func respawn():
	if in_camera_range(original_pos): return
	reset_values()

# Some actors should generally attempt to despawn every frame. Then if so, simply return.
# If original position not in camera range, consider actor broken and disable it. Check Grasshopper.gd for debugging
func despawn():
	if in_camera_range(position): return false
	reset_values()
	self.position = original_pos
	return true


# Getters and setters
func get_i_frames():
	return i_frames
func set_i_frames(n):
	i_frames = n
func get_state():
	return state
func set_state(n):
	state = n
func get_velocity():
	return _velocity
func set_velocity(vel):
	_velocity = vel


