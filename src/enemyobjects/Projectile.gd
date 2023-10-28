extends GravityObject
class_name Projectile

export var damage = 0
var animation_timer = 0


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if Globals.game_paused: return
	if $Collision.disabled and animation_timer == 0: call_deferred("disable_all")
	if animation_timer: animation_timer -= 1
	var camera_pos = Globals.find_player().find_node('Camera2D').get_camera_screen_center()
	if not (camera_pos.x - 420 - 120 < self.position.x and camera_pos.x +420 + 120 > self.position.x and (
		camera_pos.y - 300 - 120 < self.position.y and camera_pos.y + 300 + 120 > self.position.y)):
			call_deferred('disable_all')

func get_damage():
	return damage

func disable_all():
	queue_free()

func disable_collision():
	$Collision.disabled = true
