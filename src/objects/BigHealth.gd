extends Health

func _ready() -> void:
	_health_to_give = 8
	$AnimationPlayer.play('Idle')
	
func _on_HealthArea_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		player_in_health()
