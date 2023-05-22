extends Projectile

export var gravity := 2

func _ready() -> void:
	damage = 2


func _process(delta: float) -> void:
	if Globals.game_paused: return
	velocity.y += gravity*delta
	self.position += velocity*delta


func _on_GravityBullet_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		animation_timer = 2
		$Sprite.visible = false
		call_deferred("disable_collision")
