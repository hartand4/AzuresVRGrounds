extends Sprite


var animation_timer := 0
var pos := Vector2.ZERO


func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if Globals.game_paused or not visible:
		$AnimationPlayer.stop(false)
		return
	if animation_timer:
		animation_timer -= 1
	elif animation_timer == 0:
		visible = false
		$AnimationPlayer.stop(true)
	global_position = pos
	$AnimationPlayer.play("DashDust")

func do_dash():
	visible = true
	$AnimationPlayer.stop(false)
	$AnimationPlayer.play("DashDust")
	animation_timer = 12
	flip_h = get_parent().recurring_x_dir > 0
	pos = get_parent().get_position() + Vector2(-30 if flip_h else 30,-25)
	
