extends Projectile

export var direction := -1

func _ready() -> void:
	damage = 4
	velocity = Vector2(400, 0)
	$ExplosionColl.disabled = true
	is_obeying_gravity = false


func _process(delta: float) -> void:
	if Globals.game_paused: return
	elif animation_timer:
		if animation_timer == 1:
			$ExplosionColl.disabled = true
		return
	self.position += direction*velocity*delta
	$Sprite.flip_h = direction + 1

func enable_explosion():
	$ExplosionColl.disabled = false

func _on_MiniMissile_area_entered(area: Area2D) -> void:
	if not (area.get_collision_layer_bit(1) or area.get_collision_layer_bit(0)): return
	animation_timer = 18
	$Sprite.visible = false
	call_deferred("disable_collision")
	call_deferred("enable_explosion")
	Globals.spawn_explosion(self.position)


func _on_MiniMissile_body_entered(body: Node) -> void:
	if not body.get_collision_layer_bit(0): return
	animation_timer = 18
	$Sprite.visible = false
	call_deferred("disable_collision")
	call_deferred("enable_explosion")
	Globals.spawn_explosion(self.position)
