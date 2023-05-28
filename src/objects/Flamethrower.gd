extends StaticBody2D

var damage := 6
var anim_timer := 0
var state := 0 #Idle, lighting, lit, shrinking

export var anim_timer_list = [60, 42, 60, 20]
export var starting_offset := 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = 0
	anim_timer = starting_offset


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused:
		$Flame/AnimationPlayer.stop(false)
		return
	if not anim_timer:
		state += 1
		state = state % 4
		anim_timer = anim_timer_list[state]
	
	animation_handler()
	if anim_timer > 0:
		anim_timer -= 1

func get_damage():
	return damage

func animation_handler():
	var anim_state_list = ["Idle", "Light", "Flaming", "Down"]
	$Flame/AnimationPlayer.play(anim_state_list[state])
	$Sprite.frame = 0 if state == 0 else 1
	$Flame/Collision.disabled = (state != 2)
