extends Area2D

var original_position = Vector2.ZERO
var damage := 3
var health := 4
var broken := false
var state := 0
var anim_timer := 0
var right_side := true

var akdc := [1.0,1.0,0.0]

var hurt_frame_timer := 0

# Called when the node enters the scene tree for the first time.
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
	animation_handler()
	
	if anim_timer:
		anim_timer -= 1
	
	match state:
		# Go to corner of screen
		0:
			if go_to_corner() and not anim_timer:
				anim_timer = 120
				state += 1
		1:
			go_to_corner()
			if not anim_timer:
				state += 1
				anim_timer = 40
			elif anim_timer == 100:
				spawn_homing_sparks()
		2:
			go_to_corner()
			if not anim_timer:
				state += 1
				anim_timer = 80
				
				akdc[0] = (Globals.find_player().position.y - 48) - self.position.y
				akdc[1] = PI*0.0015625*8
				akdc[2] = self.position.y
		3:
			position.y = akdc[0]*sin(akdc[1]*(80-anim_timer)) + akdc[2]
			position.x += (-1 if right_side else 1)*8
			if not anim_timer:
				state += 1
				anim_timer = 40
				right_side = self.position.x > Globals.find_player().position.x
		4:
			if go_to_corner() and not anim_timer:
				state = 1
				anim_timer = 120


func animation_handler():
	$Sprite.flip_h = (Globals.find_player().position.x > position.x)
	$Sprite.modulate = Color(1.8,1.8,1.8) if hurt_frame_timer else Color(1,1,1)
	
	if hurt_frame_timer:
		hurt_frame_timer -= 1
	
	if state == 0:
		$AnimationPlayer.play('Idle')
	elif state == 1:
		if anim_timer > 100:
			$AnimationPlayer.play("Open Wings")
		elif anim_timer > 50:
			$AnimationPlayer.play("Wings Open")
		elif anim_timer > 30:
			$AnimationPlayer.play("Close Wings")
		else:
			$AnimationPlayer.play("Idle")
	elif state == 2:
		if anim_timer > 20:
			$AnimationPlayer.play("Open Wings")
		else:
			$AnimationPlayer.play("Wings Open")
	elif state == 3:
		$AnimationPlayer.play("Wings Open")
	elif state == 4:
		if anim_timer > 20:
			$AnimationPlayer.play("Close Wings")
		else:
			$AnimationPlayer.play("Idle")


func go_to_corner():
	var target_corner = Globals.get_current_camera_pos() + (Vector2(320, -220) if right_side else Vector2(-320, -220))
	if (position - target_corner).length_squared() > 400:
		position += (target_corner - position).normalized()*9
		#return false
	elif (position - target_corner).length_squared() > 10:
		position += vector_min( (target_corner - position).normalized()*5.5, target_corner - position)
		#return false
	
	return (position - target_corner).length_squared() < 400

func vector_min(v1, v2):
	return v1 if v1.length_squared() < v2.length_squared() else v2


func get_damage():
	return damage

func reset_values():
	state = 0
	health = 4
	$Sprite.visible = true
	$Collision.disabled = false
	anim_timer = 80
	right_side = (Globals.find_player().position.x < position.x)
	hurt_frame_timer = 0
	$Sprite.modulate = Color(1,1,1)

func respawn():
	if in_camera_range(original_position): return
	reset_values()
	broken = false

func despawn():
	if state >= 3 or in_camera_range(self.position): return false
	call_deferred("disable_all")
	if in_camera_range(original_position):
		broken = true
	return true

func disable_all():
	$Sprite.visible = false
	$Collision.disabled = true
	health = 4

func in_camera_range(pos):
	var camera_pos = Globals.get_current_camera_pos()
	return camera_pos.x - 420 - 120 < pos.x and camera_pos.x + 420 + 120 > pos.x and (
		camera_pos.y - 300 - 120 < pos.y and camera_pos.y + 300 + 120 > pos.y)

func spawn_homing_sparks():
	for i in range(4):
		var current_scene = self
		var bullet_scene = load("res://src/enemyobjects/Homing Spark.tscn")
		var spawn := bullet_scene.instance() as Node2D
		current_scene.add_child(spawn)
		spawn.set_as_toplevel(true)
		spawn.global_position = self.position
		spawn.first_position = Vector2(60*(-1 if i % 2 == 0 else 1), 60*(-1 if i > 1 else 1))


func _on_Plume_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(4):
		health -= 2
		hurt_frame_timer = 12
