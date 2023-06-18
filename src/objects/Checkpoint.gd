extends Area2D

var anim_timer := 0
export var checkpoint_spawn := Vector2.ZERO
var active := false
export var checkpoint_number := 1


func _ready() -> void:
	if Globals.checkpoint_data[0] == checkpoint_number:
		active = true
	$Sprite.frame = 4 if active else 0
	checkpoint_spawn = position


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if anim_timer:
		anim_timer -= 1
		$AnimationPlayer.play("Raise")
	else:
		#$AnimationPlayer.stop(true)
		$Sprite.frame = 4 if active else 0


func _on_Checkpoint_area_entered(area: Area2D) -> void:
	if not area.get_collision_layer_bit(1): return
	elif active: return
	anim_timer = 16
	active = true
	area.get_parent().set_checkpoint(checkpoint_number, checkpoint_spawn)
