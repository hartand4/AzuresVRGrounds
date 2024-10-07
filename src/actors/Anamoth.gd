extends Area2D

var damage := 3
var original_position := Vector2.ZERO
var fly_direction := Vector2.DOWN
export var starting_fly_direction := Vector2.DOWN
var linear_speed := 3
var angular_speed := 3
var health := 1
var broken := false

func _ready() -> void:
	original_position = position
	fly_direction = starting_fly_direction


func _process(_delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	elif broken:
		position = original_position
		respawn()
		return
	elif health <= 0:
		broken = true
		call_deferred("disable_all")
		Globals.spawn_explosion(position)
		Globals.spawn_health(position, 2.4)
		return
	elif despawn():
		position = original_position
		health = 1
		fly_direction = starting_fly_direction
		return
	
	$Sprite.visible = true
	$Collision.disabled = false
	$AnimationPlayer.play("Flap")
	
	var target_direction = Globals.find_player().position - position + Vector2(0,-48)
	fly_direction = update_angle(target_direction)
	position += fly_direction*linear_speed
	$Sprite.flip_h = fly_direction.x > 0

func update_angle(target):
	var angle_to_target = angle_positive(target.angle() - fly_direction.angle())
	var factor = 1 if angle_to_target <= PI else -1
	return fly_direction.rotated((PI * angular_speed * factor)/120)

func angle_positive(angle):
	return angle if angle >= 0 else 2*PI + angle

func despawn():
	if in_camera_range(position): return false
	call_deferred("disable_all")
	if in_camera_range(original_position):
		broken = true
	return true

func respawn():
	if in_camera_range(original_position): return
	health = 1
	fly_direction = starting_fly_direction
	$Sprite.visible = true
	$Collision.disabled = false
	broken = false

func in_camera_range(pos):
	var camera_pos = Globals.get_current_camera_pos()
	return camera_pos.x - 432 - 120 < pos.x and camera_pos.x + 432 + 120 > pos.x and (
		camera_pos.y - 312 - 120 < pos.y and camera_pos.y + 312 + 120 > pos.y)

func disable_all():
	$Sprite.visible = false
	$Collision.disabled = true
	health = 1

func get_damage():
	return damage # set to 0 for a sweet ride

func _on_Anamoth_area_entered(area: Area2D) -> void:
	if not (area.get_collision_layer_bit(4) or area.get_collision_layer_bit(11)): return
	health -= 2
