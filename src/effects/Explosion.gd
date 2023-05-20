extends Sprite


var animation_timer = 24

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if animation_timer <= 0:
		call_deferred("disable_all")
	$AnimationPlayer.play("Explode")
	animation_timer -= 1

func disable_all():
	get_parent().remove_child(self)
