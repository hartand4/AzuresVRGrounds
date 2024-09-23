extends Health

func _ready() -> void:
	_health_to_give = 10
	$AnimationPlayer.play('Idle')
	
func _on_HealthArea_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		player_in_health()
	elif area.get_collision_layer_bit(9):
		is_in_water = true


func _on_HealthArea_area_exited(area: Area2D) -> void:
	if area.get_collision_layer_bit(9):
		is_in_water = false
