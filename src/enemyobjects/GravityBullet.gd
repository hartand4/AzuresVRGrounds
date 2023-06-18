extends Projectile

func _ready() -> void:
	damage = 2


func _process(delta: float) -> void:
	if Globals.game_paused: return
	self.position += velocity*delta

func _on_GravityBullet_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		animation_timer = 2
		$Sprite.visible = false
		call_deferred("disable_collision")
	elif area.get_collision_layer_bit(9):
		is_in_water = true

func _on_GravityBullet_area_exited(area: Area2D) -> void:
	if area.get_collision_layer_bit(9):
		is_in_water = false
