extends Sprite


var animation_timer = 24
export var has_collision := false
export var damage := 3

func _process(_delta) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if animation_timer <= 0:
		call_deferred("disable_all")
	$AnimationPlayer.play("Explode")
	animation_timer -= 1
	call_deferred("change_collision", not(has_collision and animation_timer > 2))

func get_damage():
	return damage

func change_collision(value):
	$CollisionArea/Collision.disabled = value

func disable_all():
	queue_free()
