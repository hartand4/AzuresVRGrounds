extends Area2D

var _anim_timer := 0
var used := false

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	$AnimationPlayer.play('Open')
