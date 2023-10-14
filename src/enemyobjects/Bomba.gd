extends Projectile


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ExplosionColl.disabled = true
	damage = 4
	gravity = 1200.0


func _process(_delta: float) -> void:
	if Globals.game_paused: return
	elif animation_timer:
		if animation_timer == 1:
			$ExplosionColl.disabled = true
		return
	velocity.y = min(velocity.y + gravity/60.0, 1200.0)
	self.position += velocity/60.0

func enable_explosion():
	$ExplosionColl.disabled = false

func _on_Bomba_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1) or area.get_collision_layer_bit(0):
		animation_timer = 18
		$Sprite.visible = false
		call_deferred("disable_collision")
		call_deferred("enable_explosion")
		Globals.spawn_explosion(self.position)


func _on_Bomba_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(0):
		animation_timer = 18
		$Sprite.visible = false
		call_deferred("disable_collision")
		call_deferred("enable_explosion")
		Globals.spawn_explosion(self.position)
