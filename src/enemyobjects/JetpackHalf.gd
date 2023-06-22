extends Projectile


export var fall_direction := -1
var anim_timer := -1

func _ready() -> void:
	velocity = Vector2(fall_direction*220, 200)

func _process(delta: float) -> void:
	if Globals.game_paused: return
	
	velocity.x = fall_direction*220
	$Sprite.flip_h = fall_direction > 0
	
	self.position += velocity*delta
	if anim_timer < 0: return
	
	elif anim_timer > 0:
		call_deferred("disable_collision")
	else:
		call_deferred("disable_all")

func get_damage():
	return 4

func _on_JetpackHalf_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		anim_timer = 3
		Globals.spawn_explosion(self.position)
	elif area.get_collision_layer_bit(9):
		is_in_water = true


func _on_JetpackHalf_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(0):
		anim_timer = 3
		Globals.spawn_explosion(self.position, true, 4)
