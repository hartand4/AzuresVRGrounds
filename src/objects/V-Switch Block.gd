extends StaticBody2D

export var start_transparent := true
var is_solid = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.frame = 0 if start_transparent else 1
	is_solid = not start_transparent
	$Collision.disabled = not is_solid

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	$Sprite.frame = 1 if is_solid else 0
	$Collision.disabled = not is_solid

func vswitch_change_state():
	is_solid = not is_solid
