extends GravityObject

var broken := false
var health := 2
var original_position := Vector2.ZERO
var fly_direction := -1
var state := 0
var flash_timer = 0

var speed := Vector2(250,0)
var anim_timer = 0

func _ready() -> void:
	original_position = self.position
	reset_values()

func _process(_delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	elif broken:
		self.position = original_position
		respawn()
		return
	elif health <= 0:
		broken = true
		call_deferred("disable_all")
		Globals.spawn_explosion(self.position)
		Globals.spawn_health(self.position)
		return
	elif despawn():
		self.position = original_position
		reset_values()
		return
	
	$Sprite.visible = true
	$Collision.disabled = false
	
	var player_position = Globals.find_player().position
	
	self.position += fly_direction*speed/60.0
	
	if anim_timer:
		anim_timer -= 1
	
	if flash_timer:
		flash_timer -= 1
	$Sprite.modulate = Color(2.2,2.2,2.7) if flash_timer else Color(1,1,1)
	
	match state:
		0:
			if self.position.y < player_position.y + 50 and (
				(fly_direction > 0 and self.position.x > player_position.x - 200) or
				(fly_direction < 0 and self.position.x < player_position.x + 200)):
				state = 1
				anim_timer = 40
				spawn_jetpack_half()
		1:
			if anim_timer <= 0:
				spawn_jetpack_half()
				state = 2
				velocity.y = 0
				anim_timer = 40
		2:
			if anim_timer <= 0:
				is_obeying_gravity = true
				self.position.y += velocity.y / 60.0
	
	if state != 2:
		$AnimationPlayer.play("Fly")
	else:
		$AnimationPlayer.stop(true)
		$Sprite.frame = 4
	
	$Sprite.flip_h = (fly_direction > 0)

func respawn():
	if in_camera_range(original_position): return
	reset_values()
	broken = false

func despawn():
	if in_camera_range(self.position): return false
	call_deferred("disable_all")
	if in_camera_range(original_position):
		broken = true
	return true

func disable_all():
	$Sprite.visible = false
	$Collision.disabled = true
	health = 2

func spawn_jetpack_half():
	var bullet_scene = load("res://src/enemyobjects/JetpackHalf.tscn")
	var spawn := bullet_scene.instance() as Node2D
	get_parent().add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = self.position
	spawn.fall_direction = fly_direction

func in_camera_range(pos):
	var camera_pos = Globals.get_current_camera_pos()
	return camera_pos.x - 420 - 120 < pos.x and camera_pos.x + 420 + 120 > pos.x and (
		camera_pos.y - 300 - 120 < pos.y and camera_pos.y + 300 + 120 > pos.y)

func reset_values():
	health = 2
	fly_direction = -1 if original_position.x > Globals.find_player().position.x else 1
	$Sprite.visible = true
	$Collision.disabled = false
	state = 0
	velocity.y = 0
	is_obeying_gravity = false

func get_damage():
	return 2

func _on_Rodopack_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(4):
		health -= 2
	elif area.get_collision_layer_bit(9):
		is_in_water = true
	elif area.get_collision_layer_bit(11):
		health -= area.player_attack_type if area.player_attack_type < 4 else 2
		flash_timer = 6
