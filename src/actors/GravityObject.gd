extends Node

class_name GravityObject

export var gravity := 1200.0
var is_obeying_gravity := true
export var velocity := Vector2.ZERO
var is_in_water := false

func _physics_process(_delta: float) -> void:
	if Globals.game_paused: return
	if not is_obeying_gravity: return
	
	gravity = 1200*(0.4 if is_in_water else 1.0)
	velocity.y += gravity / 60.0
