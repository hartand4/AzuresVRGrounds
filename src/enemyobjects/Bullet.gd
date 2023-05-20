extends Area2D


export var velocity = Vector2.ZERO
export var damage = 2
var animation_timer = 0


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if Globals.game_paused: return
	elif $Collision.disabled and animation_timer == 0: call_deferred("disable_all")
	animation_timer -= 1
	position += velocity*delta
	var camera_pos = Globals.find_player().find_node('Camera2D').get_camera_screen_center()
	if not (camera_pos.x - 420 - 120 < position.x and camera_pos.x +420 + 120 > position.x and (
		camera_pos.y - 300 - 120 < position.y and camera_pos.y + 300 + 120 > position.y)):
			call_deferred('disable_all')

func disable_all():
	get_parent().remove_child(self)

func disable_collision():
	$Collision.disabled = true

func _on_Bullet_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		animation_timer = 2
		$Bullet.visible = false
		call_deferred("disable_collision")
