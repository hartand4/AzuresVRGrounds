extends Sprite

var animation_timer := 21
export var is_upside_down := false

func _process(_delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if animation_timer: animation_timer -= 1
	elif animation_timer == 0:
		call_deferred("remove_self")
	$AnimationPlayer.play("Dust")
	position.y -= 2 if !is_upside_down else -2

func remove_self():
	queue_free()
