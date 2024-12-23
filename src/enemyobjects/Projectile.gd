extends GravityObject
class_name Projectile

export var damage = 0
var animation_timer = 0


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if Globals.game_paused: return
	if $Collision.disabled and animation_timer == 0: call_deferred("disable_all")
	if Globals.prevent_enemy_spawn:
		if !self.get("player_attack_type"): call_deferred("disable_all")
	
	if animation_timer: animation_timer -= 1
	var camera_pos = Globals.get_current_camera_pos()
	if not (camera_pos.x - 432 - 120 < self.position.x and camera_pos.x +432 + 120 > self.position.x and (
		camera_pos.y - 312 - 120 < self.position.y and camera_pos.y + 312 + 120 > self.position.y)):
			call_deferred('disable_all')

func get_damage():
	return damage

func disable_all():
	queue_free()

func disable_collision():
	$Collision.disabled = true
