extends Actor

export var secret_exit := false

func _ready() -> void:
	$OrbSprite.visible = true
	$OrbCollider.disabled = false
	$OrbArea/OrbHitbox.disabled = false
	$AnimationPlayer.play("Hue Changing" if not secret_exit else "Hue Changing S")
	_velocity = Vector2.ZERO


func _process(_delta: float) -> void:
	if Globals.get("game_paused"):
		$AnimationPlayer.stop(false)
		return
	$AnimationPlayer.play("Hue Changing" if not secret_exit else "Hue Changing S")
	if obeys_actor_gravity:
		_velocity = move_and_slide(_velocity, Vector2.UP, true)
	$OrbSprite.flip_v = is_upside_down

func disable_all():
	$OrbSprite.visible = false
	$OrbCollider.disabled = true
	$OrbArea/OrbHitbox.disabled = true

func get_velocity():
	return _velocity
func set_velocity(vel):
	_velocity = vel

func _on_OrbArea_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		if secret_exit:
			Globals.find_player().secret_exit_reached = true
		else:
			Globals.find_player().normal_exit_reached = true
		call_deferred("disable_all")
	
	elif area.get_collision_layer_bit(9):
		is_in_water = true


func _on_OrbArea_area_exited(area: Area2D) -> void:
	if area.get_collision_layer_bit(9):
		is_in_water = false
