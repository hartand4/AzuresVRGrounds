extends StaticBody2D


var active := false
export var start_interval := 0
export var lasts := 4
export var shadow_visible := true
export var walljump := true

var active_timer = 0

var timer = -1

func _ready():
	if walljump: return
	$Sprite.texture = preload("res://assets/Sprites/Objects/SudoBlockNoJump.png")
	set_collision_layer_bit(0, false)
	set_collision_layer_bit(6, true)
	$Sprite.visible = false

func _process(_delta):
	if Globals.game_paused:
		$AnimationPlayer.playback_speed = 0
		return
	$AnimationPlayer.playback_speed = 1
	timer = (timer+1) % 240
	
	if ((start_interval+lasts) % 8)*30 == timer:
		#$Sprite.visible = false
		$AnimationPlayer.play("Disappear")
		call_deferred("toggle_solid", false)
		active = false
	elif (start_interval%8)*30 == timer:
		active = true
		$Sprite/Shadow.visible = shadow_visible
		$AnimationPlayer.play("Appear")
		if Globals.in_camera_range(position):
			play_sound()
	
	if active and $Collision.disabled: attempt_solid()

func toggle_solid(value):
	$Collision.disabled = !value

func play_sound():
	return

func attempt_solid():
	for body in $PlayerCheck.get_overlapping_bodies():
		if body.get_collision_layer_bit(1):
			return
	call_deferred("toggle_solid", true)
