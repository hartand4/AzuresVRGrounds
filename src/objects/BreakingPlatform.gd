extends StaticBody2D


var animation_timer = 0
var breaking = false


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused: return
	elif not breaking: return
	animation_timer -= 1
	if animation_timer == 28:
		# warning-ignore:unused_variable
		for i in range(3):
			Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakingPlatform/MiniDebris.png"),
			position + Vector2(0, -24))
	elif animation_timer == 3:
		$Collision.disabled = true
		$Sprite.visible = false
		$PlayerCheckArea/PlayerCheckCollision.disabled = true
		Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakingPlatform/Debris1.png"),
		position + Vector2(-36, 0))
		Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakingPlatform/Debris2.png"),
		position + Vector2(36, 0))
	elif animation_timer == 0:
		call_deferred("disable_all")

func disable_all():
	get_parent().remove_child(self)

func _on_PlayerCheckArea_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		animation_timer = 33
		breaking = true
