extends KinematicBody2D

export var secret_exit := false
export var obey_gravity := true
var _velocity := Vector2.ZERO
var is_in_water := false

func _ready() -> void:
	$OrbSprite.visible = true
	$OrbCollider.disabled = false
	$OrbArea/OrbHitbox.disabled = false
	$AnimationPlayer.play("Hue Changing" if not secret_exit else "Hue Changing S")


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.get("game_paused"):
		$AnimationPlayer.stop(false)
		return
	$AnimationPlayer.play("Hue Changing" if not secret_exit else "Hue Changing S")
	if obey_gravity:
		_velocity.y += 1200.0*delta*(0.4 if is_in_water else 1.0)
		_velocity.y = min(_velocity.y, 1200.0*(0.6 if is_in_water else 1.0))
		_velocity = move_and_slide(_velocity, Vector2.UP, true)

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
