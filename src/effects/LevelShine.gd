extends Sprite


var anim_timer := 24

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if anim_timer:
		$AnimationPlayer.play("Shine")
	else:
		call_deferred("disable")
	anim_timer -= 1

func disable():
	get_parent().remove_child(self)
	queue_free()
