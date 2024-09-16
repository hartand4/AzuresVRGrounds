extends Actor

func _ready() -> void:
	max_health = 2

func _physics_process(_delta: float) -> void:
	if Globals.game_paused or Globals.pause_menu_on: return
	
	match state:
		1:
			if anim_timer == 1:
				_velocity = Vector2(250*recurring_x_dir, -800)
			if not is_on_floor():
				_velocity.x = 250*recurring_x_dir
		4: return
	
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true)

func _process(_delta: float) -> void:
	if Globals.game_paused or Globals.pause_menu_on: return
	
	if state == 4:
		if anim_timer == 1:
			Globals.spawn_debris(load("res://assets/Sprites/Grasshopper/Debris1.png"),
			position + Vector2(0, -12))
			Globals.spawn_debris(load("res://assets/Sprites/Grasshopper/Debris2.png"),
			position + Vector2(0, -12))
			Globals.spawn_debris(load("res://assets/Sprites/Grasshopper/Debris3.png"),
			position + Vector2(0, -12))
			Globals.spawn_health(position, 2)
			Globals.spawn_explosion(position + Vector2(0,-12))
			position = original_pos
		elif not anim_timer: respawn()
	else:
		despawn()
	
	if state != 1: _velocity.x = 0

func update_state():
	if health <= 0:
		state = 4
		call_deferred("disable_all")
		anim_timer = 2
	if state == 0 and not anim_timer:
		anim_timer = 10
		if abs(Globals.find_player().position.x - position.x) > 150:
			recurring_x_dir = 1 if Globals.find_player().position.x > position.x else -1
			return 1
		else:
			anim_timer = 48
			return 3
	elif state == 1 and not anim_timer and is_on_floor():
			anim_timer = 10
			return 2
	elif state == 2 and not anim_timer:
		anim_timer = 20
		return 0
		
	elif state == 3 and not anim_timer:
		anim_timer = 20
		return 0
	return state

func get_damage():
	return 4

func animation_handler():
	if Globals.game_paused or Globals.pause_menu_on: return
	$Sprite.flip_h = recurring_x_dir+1
	match state:
		0:
			$AnimationPlayer.play("Idle")
		1:
			if anim_timer: $AnimationPlayer.play('Crouch')
			else: $AnimationPlayer.play("Jump")
		2: $AnimationPlayer.play("Crouch")
		3:
			$AnimationPlayer.play("Shoot")
			if anim_timer == 32:
				Globals.spawn_gravity_bullet(position+Vector2(0,-36), Vector2(-200,-400))
				Globals.spawn_gravity_bullet(position+Vector2(0,-36), Vector2(200,-400))

func despawn():
	if in_camera_range(position): return
	.despawn()
	if not in_camera_range(original_pos):
		anim_timer = 20
	else:
		state = 4
		anim_timer = 0
		call_deferred("disable_all")
		position = original_pos

func disable_all():
	$Collision.disabled = true
	$Sprite.visible = false
	$AttackCheck/AttackCheckColl.disabled = true
	health = max_health

func reset_values():
	.reset_values()
	anim_timer = 20
	$Collision.disabled = false
	$AttackCheck/AttackCheckColl.disabled = false
	$Sprite.visible = true

func _on_AttackCheck_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(4):
		health -= 2
	elif area.get_collision_layer_bit(9):
		is_in_water = true
	elif area.get_collision_layer_bit(11):
		health -= 1


func _on_AttackCheck_area_exited(area: Area2D) -> void:
	if area.get_collision_layer_bit(9):
		is_in_water = false
