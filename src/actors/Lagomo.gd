extends Actor

# Note: in case of ultimate kill, use a separate no_health() function like this.

var broken := false

func _ready() -> void:
	anim_timer = 80
	state = 0
	max_health = 10
	health = max_health
	recurring_x_dir = -1 if Globals.find_player().position.x < position.x else 1


func _process(_delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	
	if broken:
		if anim_timer == 1:
			call_deferred("disable_all")
		elif not anim_timer:
			respawn()
		return
	
	respawn()
	if health <= 0: no_health()
	
	if not anim_timer:
		state = 1-state
		anim_timer = 119 if state else 80
		recurring_x_dir = -1 if Globals.find_player().position.x < position.x else 1
	elif anim_timer == 80 and state == 1:
		Globals.spawn_mini_missile(position+Vector2(recurring_x_dir*34,-72), recurring_x_dir)
	elif anim_timer == 60 and state == 1:
		Globals.spawn_mini_missile(position+Vector2(recurring_x_dir*-6,-72), recurring_x_dir)
		
	
	$AnimationPlayer.play("Shoot" if state else "Idle")
	$Sprite.modulate = Color(1.7,1.8,2.2) if i_frames else Color(1,1,1)
	$Sprite.flip_h = recurring_x_dir+1
	
	$Sprite.position = Vector2(5,-80) + Vector2(recurring_x_dir*-5, 0)
	var sprite_height_list = [0, 6, 8, 10, 12, 14,16,16,18, 18, 10]
	$Collision.position = Vector2(6, -70 + sprite_height_list[$Sprite.frame])
	$AttackCheckArea/Collision.position = Vector2(6, -70 + sprite_height_list[$Sprite.frame])
	

func get_damage():
	return 4

func respawn():
	if in_camera_range(position): return
	health = max_health
	anim_timer = 80
	state = 0
	$Sprite.visible = true
	$Collision.disabled = false
	$AttackCheckArea/Collision.disabled = false
	broken = false
	$Visibility.process_parent = true
	recurring_x_dir = -1 if Globals.find_player().position.x < position.x else 1

func disable_all():
	$Sprite.visible = false
	$Collision.disabled = true
	$AttackCheckArea/Collision.disabled = true

func _on_AttackCheckArea_area_entered(area: Area2D) -> void:
	if not (area.get_collision_layer_bit(4) or area.get_collision_layer_bit(11)): return
	if area.get_collision_layer_bit(4):
		health -= 2
	else:
		health -= area.player_attack_type if area.player_attack_type < 4 else 2
	i_frames = 6
	if health <= 0:
		no_health()

func no_health():
	broken = true
	$Visibility.process_parent = false
	anim_timer = 2
	i_frames = 0
	Globals.spawn_explosion(position + Vector2(0,-48))
	Globals.spawn_health(position+Vector2(0,-40))
