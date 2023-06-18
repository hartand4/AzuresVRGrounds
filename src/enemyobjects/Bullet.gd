extends Projectile

func _ready() -> void:
	damage = 2
	is_obeying_gravity = false


func _process(delta: float) -> void:
	if Globals.game_paused: return
	self.position += velocity*delta

func _on_Bullet_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		animation_timer = 2
		$Bullet.visible = false
		call_deferred("disable_collision")
