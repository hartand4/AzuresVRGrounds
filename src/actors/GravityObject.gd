extends Node

class_name GravityObject

export var gravity := 1200.0
var is_obeying_gravity := true
export var velocity := Vector2.ZERO
var is_in_water := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Globals.game_paused: return
	if not is_obeying_gravity: return
	
	# warning-ignore:incompatible_ternary
	gravity = 1200*(0.4 if is_in_water else 1)
	velocity.y += gravity*delta
