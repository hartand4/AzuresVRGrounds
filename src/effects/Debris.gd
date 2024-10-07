extends KinematicBody2D


var _velocity = Vector2.ZERO
export onready var tex


func _ready() -> void:
	var vel_x = Globals.call_rng(-400,400)
	var vel_y = Globals.call_rng(-700,0)
	_velocity = Vector2(vel_x, vel_y)
	
	call_deferred("set_texture")

func _process(_delta: float) -> void:
	if Globals.game_paused: return
	
	position += _velocity / 60.0
	_velocity.y += 20
	$Sprite.visible = true
	if Globals.timer % 2 == 0: $Sprite.visible = false
	
	if position.y > Globals.current_camera_pos.y + 800:
		call_deferred("disable_all")

func disable_all():
	queue_free()

func set_texture():
	$Sprite.texture = tex
