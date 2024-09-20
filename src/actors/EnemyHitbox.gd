extends Area2D

export var match_collision := true

func _ready():
	if not match_collision: return
	var parent_collision = get_parent().find_node("Collision")
	if parent_collision:
		$Collision.shape = parent_collision.shape
		position = parent_collision.position


func _on_Hitbox_area_entered(area):
	if not (area.get_collision_layer_bit(4) or area.get_collision_layer_bit(11)): return
	if get_parent().get("health"):
		if get_parent().get("i_frames"): get_parent().i_frames = 6
		if not get_parent().get("damage_data_chart"):
			get_parent().health -= 2 if area.get_collision_layer_bit(4) else 2
			return
		var damage_values = get_parent().damage_data_chart
		if area.get_collision_layer_bit(4):
			get_parent().health -= damage_values[0]
			return
		if area.get("player_attack_type"):
			get_parent().health -= damage_values[area.player_attack_type]
		else: get_parent().health -= 1
