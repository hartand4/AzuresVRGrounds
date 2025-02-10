extends Actor

# Integer values
var current_attack = 0
var last_state = 0
var attacking_direction = 0

var pattern_state = [0,0]
var attempted_movement = 0
var remembered_direction = 0

# Timers
var dash_timer = 0
var charge_shot_timer = 0
var attack_timer = 0
var acceleration_timer = 0
var jump_timer = 0
var walljump_momentum_timer = 0

var pattern_timer = 0

# Booleans
var just_attacked = false
var is_dashing = false
var is_pressing_dashing_button = false
var just_dashed = false
var just_jumped = false
var started_dash_on_floor := false
var near_wall := [false, false]
var is_charging = false
var is_jumping = false
export var active = false

var ignore_pause = true

var floor_angle = PI/2
onready var normal_hitbox_shape = $Hitbox/Collision.shape.extents
onready var normal_hitbox_transform = [$Hitbox/Collision.get_position(), $Collision.get_position()]
onready var normal_wallcheck_shape = $WalljumpAreaL/WalljumpBoxL.shape.extents
onready var normal_wallcheck_transform = [$WalljumpAreaL/WalljumpBoxL.get_position(), $WalljumpAreaR/WalljumpBoxR.get_position()]

var damage = 4
var debris_pos
var max_i_frames = 6
var damage_data_chart = [3,1,2,4,2,2]

var is_invulnerable = false
var was_hit = false

var list_of_projectiles = [null,null,null]
var attack_scenes := [preload("res://src/enemyobjects/FaieBallS.tscn"),
	preload("res://src/enemyobjects/FaieBallM.tscn"),
	preload("res://src/enemyobjects/FaieBallL.tscn")]

# Called when the node enters the scene tree for the first time.
func _ready():
	max_i_frames = 60
	health = 32

func _process(_delta):
	if not (state in [ST_ATTACK, ST_AIR_ATTACK, ST_WALL_ATTACK]):
		do_slash_effect(0)
	
	outfit_animation()
	
	if Globals.game_paused or !active:
		$Tail/TailAnimation.playback_speed = 0
		return
	$Tail/TailAnimation.playback_speed = 1
	
	if health < 0: health = 0
	if dash_timer: dash_timer -= 1
	elif is_on_floor(): is_dashing = false
	if attack_timer: attack_timer -= 1
	
	if state != ST_AIR:
		walljump_momentum_timer = 0
	if walljump_momentum_timer: walljump_momentum_timer -= 1
	
	if current_attack == 1 and is_charging:
		charge_shot_timer += 1
		if charge_shot_timer > 200:
			charge_shot_timer -= 20
	if state != ST_WALK: acceleration_timer -= 1
	acceleration_timer = acceleration_timer - 1 if acceleration_timer > 0 else 0
	
	if state == ST_VICTORY: return
	
	pattern_timer += 1
	
	# Default all "just" booleans to false:
	just_attacked = false
	just_dashed = false
	just_jumped = false
	
	var player_pos = Globals.find_player().position
	
	if pattern_state[0] == 0:
		if attack_timer <= 0 and state != ST_HURT:
			recurring_x_dir = 1 if (player_pos.x - position.x) > 0 else -1
		attempted_movement = 0
		if pattern_timer >= 30:
			if player_pos.y - position.y < -300:
				pattern_state = [5,0]
			else: pattern_state = [Globals.call_rng(1,4),0]
			pattern_timer = 0
	
	# Run up to player 
	elif pattern_state[0] == 1:
		if pattern_state[1] == 0:
			if abs(position.x - player_pos.x) > 60 or _velocity.x == 0:
				attempted_movement = 1 if (player_pos.x - position.x) > 0 else -1
			else:
				recurring_x_dir = 1 if (player_pos.x - position.x) > 0 else -1
				just_attacked = true
				attacking_direction = 1 if player_pos.y - position.y < -96 else 0
				pattern_state[1] = 1
				pattern_timer = 9
		elif pattern_timer >= 20:
			pattern_timer = 600
	
	# Run to player and jump over, slashing down
	elif pattern_state[0] == 2:
		if pattern_state[1] == 0:
			if abs(position.x - player_pos.x) > 150 or _velocity.x == 0:
				attempted_movement = 1 if (player_pos.x - position.x) > 0 else -1
			else:
				recurring_x_dir = 1 if (player_pos.x - position.x) > 0 else -1
				just_jumped = true
				pattern_state[1] = 1
				pattern_timer = 0
				is_jumping = true
		elif pattern_state[1] == 1:
			is_jumping = pattern_timer < 12
			if pattern_timer == 20:
				just_attacked = true
				attacking_direction = 2 if !is_on_floor() and player_pos.y - position.y > 96 else\
					1 if player_pos.y - position.y < -96 else 0
			if is_on_floor() and pattern_timer > 30:
				pattern_timer = 600
	
	# Dash towards player
	elif pattern_state[0] == 3:
		if pattern_state[1] == 0:
			attempted_movement = 1 if (player_pos.x - position.x) > 0 else -1
			just_dashed = true
			pattern_state[1] = 1
			is_pressing_dashing_button = true
		elif !is_dashing:
			just_dashed = false
			is_pressing_dashing_button = false
			pattern_timer = 600
		else:
			just_dashed = false
			pattern_timer = 0
			is_pressing_dashing_button = true
	
	# Wall jump and attack
	elif pattern_state[0] == 4:
		if pattern_state[1] == 0:
			attempted_movement = 1 if (player_pos.x - position.x) > 0 else -1
			just_dashed = true
			pattern_state[1] = 1
			is_pressing_dashing_button = true
		elif pattern_state[1] == 1:
			just_dashed = true
			if (near_wall[0] or near_wall[1]):
				just_dashed = false
				just_jumped = true
				is_jumping = true
				pattern_state[1] = 2
				pattern_timer = 0
				attempted_movement = -1 if near_wall[0] else 1
				remembered_direction = attempted_movement
		elif pattern_state[1] == 2:
			attempted_movement = remembered_direction
			if _velocity.y < -400: attempted_movement = 0 
			just_jumped = false
			if pattern_timer == 40 and position.distance_squared_to(player_pos) > 45000:
				just_jumped = true
				attempted_movement = -attempted_movement
				pattern_state[1] = 3
				pattern_timer = 0
				is_jumping = true
			elif pattern_timer == 40:
				pattern_state[1] = 4
				just_attacked = true
		elif pattern_state[1] == 3:
			is_jumping = pattern_timer < 8
			just_attacked = pattern_timer == 28
			attacking_direction = 2 if !is_on_floor() and player_pos.y - position.y > 96 else\
				1 if player_pos.y - position.y < -96 else 0
			if is_on_floor():
				is_jumping = false
				is_pressing_dashing_button = false
				pattern_timer = 600
		elif pattern_state[1] == 4:
			attempted_movement = -1 if near_wall[0] else 1
			if is_on_floor():
				pattern_timer = 600
	
	# Special: jump up to hit player
	elif pattern_state[0] == 5:
		if pattern_state[1] == 0:
			attempted_movement = 1 if (player_pos.x - position.x) > 0 else -1
			just_dashed = true
			pattern_state[1] = 1
			is_pressing_dashing_button = true
		elif pattern_state[1] == 1:
			just_dashed = true
			attempted_movement = 1 if (player_pos.x - position.x) > 0 else -1
			if (near_wall[0] and attempted_movement < 0) or (near_wall[1] and attempted_movement > 0):
				just_dashed = false
				just_jumped = true
				is_jumping = true
				pattern_state[1] = 2
				pattern_timer = 0
				attempted_movement = -1 if near_wall[0] else 1
				remembered_direction = attempted_movement
				is_pressing_dashing_button = false
			elif player_pos.y - position.y >= -8:
				pattern_timer = 600
		elif pattern_state[1] == 2:
			attempted_movement = remembered_direction
			if _velocity.y < -400: attempted_movement = 0
			just_jumped = false
			if pattern_timer == 40 and player_pos.y - position.y < -8:
				just_jumped = true
				pattern_timer = 0
				is_jumping = true
			elif pattern_timer == 40:
				pattern_timer = 600
			
	
	if pattern_timer >= 600:
		pattern_state = [0,0]
		pattern_timer = 0
		is_jumping = false
		is_pressing_dashing_button = false

func _physics_process(_delta):
	var direction := Vector2.ZERO
	
	var floor_normal = -FLOOR_NORMAL if is_upside_down else FLOOR_NORMAL
	
	if Globals.get("game_paused") or !active: return
	# Jump logic
	if state in [0,1,3,4,5,8]:
		if jump_timer > 0:
			jump_timer -= 1
		elif is_on_floor():
			if just_jumped:
				jump_timer = 30
				_velocity.y = pow(30,4)/2150 * (-1 if !is_upside_down else 1)
			else: jump_timer = 0
		is_jumping = is_jumping and jump_timer > 0 and\
			((_velocity.y < 0 and !is_upside_down) or (_velocity.y > 0 and is_upside_down))
		if !is_jumping:
			jump_timer = 0
		
		if !walljump_momentum_timer:
			direction = get_direction_normal()
		# Exceptions to the direction normal
		if state == ST_ATTACK:
			direction.x = 0.0
		if direction.x != 0.0 and not (state in [ST_AIR_ATTACK, ST_WALLSLIDE]):
				recurring_x_dir = direction.x
		
	elif state == ST_HURT:
		direction.x = recurring_x_dir * -0.5
	
	elif state == ST_DASH:
		if jump_timer > 0: jump_timer -= 1
		elif is_jumping: jump_timer = 30
		direction = get_direction_normal()
		direction.x = recurring_x_dir
	
	if walljump_momentum_timer:
		direction = Vector2(recurring_x_dir*(-1.5),0)
		if is_on_ceiling():
			walljump_momentum_timer = 0
	
	# Update position
	var snap := 15*Vector2.DOWN if not is_jumping else Vector2.ZERO
	_velocity = calculate_move_direction(_velocity, speed, direction, is_jumping)
	
	if state in [ST_WALLSLIDE, ST_WALL_ATTACK]:
		_velocity.y = min(_velocity.y, 250.0) if !is_upside_down else max(_velocity.y, -250.0)
		if direction.x * recurring_x_dir > 0:
			_velocity.x = 0.0
	elif state == ST_DASH:
		if not is_on_floor():_velocity.y = 0
	
	if is_dashing and state != ST_HURT: _velocity.x *= 1.8
		
	# Check for slopes
	if is_on_floor() and get_slide_count() > 0:
		floor_angle = -get_slide_collision(0).normal.angle()
		if abs(cos(floor_angle)) > cos(PI/6):
			floor_angle = PI/2
		var factor = abs(sin(floor_angle))
		if cos(floor_angle)*recurring_x_dir > 0 and factor != 0: factor=1/factor
		_velocity.x *= factor
	
	if not is_jumping:
		_velocity = move_and_slide_with_snap(_velocity, snap, floor_normal, true)
	else:
		_velocity = move_and_slide(_velocity, floor_normal, true)

func calculate_move_direction(linear_velocity: Vector2, speed: Vector2, direction: Vector2, jumping: bool) -> Vector2:
	var out_vel := linear_velocity
	var speed_x_factor := 0.1 if (state == ST_IDLE or acceleration_timer > 3) else 0.3 if acceleration_timer > 0 else 1.0
	out_vel.x = speed.x * direction.x * speed_x_factor
	out_vel.y += gravity / 60.0 * (-1 if is_upside_down else 1)
	if direction.y == -1.0:
		out_vel.y = (500.0 * direction.y)*(-1 if is_upside_down else 1) - linear_velocity.y
		
		# Account for slope jump boost
		if out_vel.x != 0:
			var factor = abs(sin(floor_angle))
			if cos(floor_angle)*recurring_x_dir > 0 and factor != 0: factor=1/factor
			out_vel.y *= (factor+2)/3
	if jumping:
		out_vel.y -= 1.2*pow(jump_timer,4)/4600*(-1 if is_upside_down else 1) #First few frames matter more
	return out_vel

func get_direction_normal() -> Vector2:
	return Vector2(attempted_movement,#1.0 if _velocity.x > 0 else -1.0 if _velocity.x < 0 else 0.0,
		-1.0 if just_jumped and is_on_floor() else 1.0)

# Handles various animations using state. Also calls change_dash_hitbox to match dash sprite
func animation_handler():
	if state == ST_OFFLOAD: return
	
	$Sprite.visible = true
	$Sprite.flip_h = recurring_x_dir + 1
	$Tail.flip_h = recurring_x_dir + 1
	$Tail.visible = true
	$TailWall.visible = false
	$Sprite/DashHand.visible = false
	$Tail/TailAnimation.play("TailWag")
	$Tail.z_as_relative = true
	
	scale.y = -1 if is_upside_down else 1
	
	# Tail Animation
	if state == ST_DASH:
		$Tail.z_index = 0
		$Tail/TailAnimation.play("TailStraight")
		if animation_timer > 4:
			$Tail.set_position(Vector2(recurring_x_dir*-35,-21))
			
		else:
			$Tail.set_position(Vector2(recurring_x_dir*-45,-31))
	elif state == ST_WALLSLIDE or state == ST_WALL_ATTACK:
		$TailWall.visible = true
		$Tail.visible = false
		$TailWall.flip_h = recurring_x_dir + 1
		$Tail/TailAnimation.play("TailWall")
		$TailWall.set_position(Vector2(recurring_x_dir*3,-5))
	elif state == ST_WALK:
		$Tail.set_position(Vector2(recurring_x_dir*-37,-35))
	else:
		$Tail.z_index = 0
		$Tail.set_position(Vector2(recurring_x_dir*-29,-35))
	
	# Add hand for dash + shoot sprite
	if $Sprite.frame == 59:
		$Sprite/DashHand.visible = true
		$Sprite/DashHand.position.x = recurring_x_dir*26.5
		$Sprite/DashHand.flip_h = recurring_x_dir + 1
	
	#Outfit flip
	$Sprite/Outfit.flip_h = $Sprite.flip_h
	
	if health > 0: change_dash_hitbox(state == ST_DASH)
	
	# Flash when charging
	$Sprite.modulate = Color(1,1,1)
	$Tail.modulate = Color(1,1,1)
	$TailWall.modulate = Color(1,1,1)
	if current_attack == 1:
		if charge_shot_timer >= 45 and charge_shot_timer < 120 and charge_shot_timer % 10 >= 5:
			$Sprite.modulate = Color(1.2,1.3,1.5)
			$Tail.modulate = Color(1.2,1.3,1.5)
			$TailWall.modulate = Color(1.2,1.3,1.5)
		elif charge_shot_timer >= 120 and charge_shot_timer % 8 >= 4:
			$Sprite.modulate = Color(1.2,1.6,1.3)
			$Tail.modulate = Color(1.2,1.6,1.3)
			$TailWall.modulate = Color(1.2,1.6,1.3)
	
	if i_frames % 8 >= 6:
		$Sprite.modulate = Color(2.2,1.8,2.3)
		$Tail.modulate = Color(2.2,1.8,2.3)
		$TailWall.modulate = Color(2.2,1.8,2.3)
	
	match state:
		ST_IDLE:
			if current_attack == 0 or attack_timer <= 0 or last_state != 0:
				_animation.play("Idle")
				if current_attack != 0: attack_timer = 0
			else:
				_animation.play("Shoot")
				if just_attacked:
					_animation.stop()
					_animation.play("Shoot")
		ST_DASH:
			if Globals.timer % 5 == 0 and animation_timer > 5 and is_on_floor():
				spawn_dust_particle(true)
			if current_attack == 0:
				_animation.play("Dash")
			elif current_attack != 0:
				if last_state != 2:
					_animation.play("Dash + Shoot" if attack_timer else "Dash")
				elif $Sprite.frame == 59 and !attack_timer:
					_animation.stop()
					$Sprite.frame = 20
				elif $Sprite.frame == 20 and attack_timer:
					_animation.stop()
					$Sprite.frame = 59
				if $Sprite.frame == 59:
					$Sprite/DashHand.visible = true
					$Sprite/DashHand.position.x = recurring_x_dir*26.5
					$Sprite/DashHand.flip_h = recurring_x_dir + 1
		ST_AIR:
			if current_attack and attack_timer:
				_animation.play('Jump + Shoot')
			elif ((_velocity.y < 0 and !is_upside_down) or (_velocity.y > 0 and is_upside_down)):
				_animation.play('Jump')
			else:
				_animation.play('Fall')
		ST_ATTACK:
			if _animation.current_animation in ["Air Slash", "Air Slash Up"]:
				var temp_anim_pos = _animation.current_animation_position
				_animation.play('Ground Slash' if attacking_direction == 0 else 'Ground Slash Up')
				_animation.seek(temp_anim_pos)
			else:
				_animation.play('Ground Slash' if attacking_direction == 0 else 'Ground Slash Up')
			if $Sprite.frame == 47: $Sprite.frame -= 2
			
			if animation_timer == 6:
				do_slash_effect(1 if attacking_direction == 0 else 3)
			update_slash_hitbox()
		ST_AIR_ATTACK:
			if attacking_direction == 0:
				_animation.play('Air Slash')
				if animation_timer == 6:
					do_slash_effect(1)
			elif attacking_direction == 1:
				_animation.play('Air Slash Up')
				if animation_timer == 6:
					do_slash_effect(3)
			elif attacking_direction == 2:
				_animation.play('Air Slash Down')
				if animation_timer == 6:
					do_slash_effect(4)
			update_slash_hitbox()
		ST_WALL_ATTACK:
			_animation.play('Wall Slash')
			if animation_timer == 6:
				do_slash_effect(2)
			update_slash_hitbox()
		ST_WALLSLIDE:
			if current_attack == 0 or !attack_timer:
				_animation.play("Wallslide")
			else:
				_animation.play("Wallslide + Shoot")
			if Globals.timer % 7 == 0 and animation_timer > 5:
				spawn_dust_particle()
		ST_VICTORY:
			if not is_on_floor(): animation_timer = 0
			elif animation_timer < 18:
				_animation.play('Victory')
			else:
				_animation.play("Victory2")
		ST_WALK:
			if current_attack == 0:
				if acceleration_timer > 0:
					_animation.play('Step Forward')
				else:
					_animation.play('Run')
			else:
				var temp_seek = [_animation.current_animation, 0.0]
				if temp_seek[0] != '': temp_seek[1] = _animation.current_animation_position
				_animation.play('Run + Shoot' if attack_timer else "Run")
				if temp_seek[0] != _animation.current_animation and temp_seek[0] != '':
					_animation.seek(temp_seek[1])

# Updates state if game unpaused. Also updates attack_timer and dashing variables
func update_state():
	if Globals.game_paused:
		return state
	
	if Globals.find_player().health <= 0 and is_on_floor():
		recurring_x_dir = -1
		return ST_VICTORY
	
	# GETTING HURT
	if state == ST_HURT:
		if animation_timer < 24: return ST_HURT
		state = 0
		return update_state()
	
	# DOING AN AIR ATTACK
	if just_attacked and (state == ST_AIR or (state == ST_DASH and not is_on_floor()) ):
		if current_attack == 1: pass# TODO: shoot_flameball(charge_shot_timer)
		elif current_attack > 1: pass# TODO: shoot_projectile()
		attack_timer = 16
		if current_attack == 0: return ST_AIR_ATTACK
		return state
	if state == ST_AIR_ATTACK and attack_timer <= 0: return ST_AIR
	
	# SLIDING ON A WALL
	if state in [ST_AIR, ST_AIR_ATTACK] and is_on_wall() and\
		((_velocity.y > 0 and !is_upside_down) or (_velocity.y < 0 and is_upside_down)):
		if (near_wall[0] and attempted_movement < 0) or (near_wall[1] and attempted_movement > 0):
			recurring_x_dir = 1 if near_wall[0] else -1
			dash_timer = 0
			is_dashing = false
			_velocity.y = 100.0 * (-1 if !is_upside_down else 1)
			return ST_WALLSLIDE
		
	# CONTINUE SLIDING ON WALL, OR WALLJUMP WHILE SLIDING
	if state == ST_WALLSLIDE or state == ST_WALL_ATTACK:
		if is_on_floor():
			return ST_IDLE
		elif just_jumped:
			recurring_x_dir *= -1
			if !is_pressing_dashing_button:
				dash_timer = 0
				is_dashing = false
			else: is_dashing = true
			_velocity.y = 500 * (-1 if !is_upside_down else 1)
			jump_timer = 29
			walljump_momentum_timer = 4
			return ST_AIR
		if not (near_wall[0] or near_wall[1]):
			return ST_AIR
		elif not ((near_wall[0] and attempted_movement < 0) or\
			(near_wall[1] and attempted_movement > 0)):
			return ST_AIR
		
		if just_attacked:
			if current_attack == 1: pass#TODO: shoot_flameball(charge_shot_timer)
			elif current_attack > 1: pass#TODO: shoot_projectile()
			attack_timer = 16
			return ST_WALL_ATTACK if !current_attack else state
			
	# WALL ATTACK
	if state == ST_WALL_ATTACK:
		if is_on_floor():
			attack_timer = 0
			return ST_IDLE
		elif attack_timer <= 0:
			return ST_WALLSLIDE
		elif just_jumped:
			attack_timer = 0
			recurring_x_dir *= -1
			if !just_dashed:
				dash_timer = 0
				is_dashing = false
			else: is_dashing = true
			return ST_AIR
	
	# FLOOR DASHING OR AIR DASHING
	if just_dashed:
		if not(near_wall[int((recurring_x_dir+1)/2)]) and not is_dashing:
			is_dashing = true
			dash_timer = 40 if is_on_floor() else 20
			started_dash_on_floor = is_on_floor()
			$DashDust.do_dash()
			return ST_DASH
	
	# WHILE FLOOR DASHING OR AIR DASHING
	if state == ST_DASH:
		if near_wall[int((recurring_x_dir+1)/2)] or dash_timer == 0 or !is_pressing_dashing_button or (
				started_dash_on_floor and not is_on_floor()
			):
			state = ST_AIR
			dash_timer = 0
			return update_state()
	
	# ATTACKING
	if state < 3 and just_attacked:
		if current_attack == 0: is_dashing = false
		elif current_attack == 1: pass#TODO: shoot_flameball(charge_shot_timer)
		elif current_attack > 1: pass#TODO: shoot_projectile()
		attack_timer = 16
		return ST_ATTACK if current_attack == 0 else state
	
	#STOP ATTACK
	if state == ST_ATTACK and attack_timer <= 0:
		state = 0
		attack_timer = 0
		return update_state()
	
	# BEGIN ON FLOOR
	if state == 3 and is_on_floor():
		state = 0
		return update_state()
	
	# IF LANDED BEFORE AIR ATTACK DONE, CONTINUE ATTACK
	if state == 5 and is_on_floor() and attack_timer:
		if attacking_direction < 2: return ST_ATTACK
		state = 0
		return update_state()
	
	# IF JUMPED OR FELL OR AIR ATTACK ENDED
	if state in [0,1,2,4] and just_jumped: 
		if is_on_floor() or state < 2:
			is_dashing = state == 2
		return ST_AIR
	
	elif state < 2 and _velocity.x != 0:
		if state == 0: acceleration_timer = 4
		return ST_WALK
	elif state < 2 and _velocity.x == 0: return ST_IDLE
	return state

# Alters dash hitbox and walljump detectors based on the dashing state
func change_dash_hitbox(dash_state):
	if dash_state:
		$Hitbox/Collision.shape.extents = Vector2(11.5, 27.0)
		$Hitbox/Collision.set_position(Vector2(0.0, 12.0))
		$Collision.disabled = true
		$DashCollision.disabled = false
		$WalljumpAreaL/WalljumpBoxL.shape.extents = Vector2(13.0,30.0)
		$WalljumpAreaL/WalljumpBoxL.set_position(Vector2(normal_wallcheck_transform[0][0], -40))
		$WalljumpAreaR/WalljumpBoxR.set_position(Vector2(normal_wallcheck_transform[1][0], -40))
		return
	
	$Hitbox/Collision.shape.extents = normal_hitbox_shape
	$Hitbox/Collision.set_position(normal_hitbox_transform[0])
	$Collision.disabled = false
	$DashCollision.disabled = true
	$WalljumpAreaL/WalljumpBoxL.shape.extents = normal_wallcheck_shape
	$WalljumpAreaL/WalljumpBoxL.set_position(normal_wallcheck_transform[0])
	$WalljumpAreaR/WalljumpBoxR.set_position(normal_wallcheck_transform[1])

# Spawns dust when sliding down a wall, with slight variance
func spawn_dust_particle(for_dash=false):
	var spawn_scene = load("res://src/effects/WallSlideDust.tscn")
	var spawn := spawn_scene.instance() as Node2D
	spawn.is_upside_down = is_upside_down
	add_child(spawn)
	
	spawn.set_as_toplevel(true)
	
	if for_dash:
		spawn.global_position = self.global_position + Vector2(-30*recurring_x_dir,0)
		return
	
	spawn.global_position = self.global_position + Vector2(-15 if recurring_x_dir > 0 else 15,
		50*(-1 if !is_upside_down else 1))
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	spawn.global_position += Vector2(rng.randi_range(0, 6), 0)

func update_slash_hitbox():
	var attack_collision = $AttackHitbox/Collision
	if state in [ST_ATTACK, ST_AIR_ATTACK] and attacking_direction == 0:
		if $SlashEffects/SlashEffect.frame == 1:
			attack_collision.set_position(Vector2(recurring_x_dir * -36.0,-40))
			attack_collision.shape.extents = Vector2(62, 18)
		elif $SlashEffects/SlashEffect.frame == 2:
			attack_collision.set_position(Vector2(recurring_x_dir * -102.0,-38))
			attack_collision.shape.extents = Vector2(26, 12)
	
	elif state in [ST_ATTACK, ST_AIR_ATTACK] and attacking_direction == 1:
		if $SlashEffects/SlashEffectUp.frame == 1:
			attack_collision.set_position(Vector2(recurring_x_dir * -85.0,-102))
			attack_collision.shape.extents = Vector2(15, 22)
	
	elif state == ST_AIR_ATTACK and attacking_direction == 2:
		if $SlashEffects/SlashEffectDown.frame == 1:
			attack_collision.set_position(Vector2(recurring_x_dir * -76.0,-1.0))
			attack_collision.shape.extents = Vector2(8, 23)
	
	elif state in [ST_WALL_ATTACK, ST_LADDER_ATTACK]:
		if $SlashEffects/SlashEffectAlt.frame == 1:
			attack_collision.set_position(Vector2(recurring_x_dir * 6.0,-34))
			attack_collision.shape.extents = Vector2(32,14)

# Animates the slash effect and prepares the initial hitboxes accordingly.
# start -> 0=end, 1=normal, 2=wall, 3=up, 4=down
func do_slash_effect(start):
	var attack_collision = $AttackHitbox/Collision
	match start:
		0:
			$SlashEffects/SlashEffect.visible = false
			$SlashEffects/SlashEffectAlt.visible = false
			$SlashEffects/SlashEffectUp.visible = false
			$SlashEffects/SlashEffectDown.visible = false
			attack_collision.disabled = true
		1:
			$SlashEffects/SlashEffect.visible = true
			$SlashEffects/SlashEffect.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffect.position.x = 0 if state == ST_ATTACK else 4*recurring_x_dir
	
			$AttackHitbox.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.set_position(Vector2(recurring_x_dir * 2.0,-46))
			attack_collision.shape.extents = Vector2(48.75, 16)
			attack_collision.disabled = false
		2:
			$SlashEffects/SlashEffectAlt.visible = true
			$SlashEffects/SlashEffectAlt.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffectAlt.position.x = recurring_x_dir*61
			
			$AttackHitbox.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.set_position(Vector2(recurring_x_dir * 10.0,-60))
			attack_collision.shape.extents = Vector2(40.75, 34)
			attack_collision.disabled = false
		3:
			$SlashEffects/SlashEffectUp.visible = true
			$SlashEffects/SlashEffectUp.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffectUp.position.x = recurring_x_dir*-4
			
			$AttackHitbox.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.set_position(Vector2(recurring_x_dir * -46,-111.0))
			attack_collision.shape.extents = Vector2(41.5, 29)
			attack_collision.disabled = false
		4:
			$SlashEffects/SlashEffectDown.visible = true
			$SlashEffects/SlashEffectDown.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffectDown.position.x = recurring_x_dir*6
			
			$AttackHitbox.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.set_position(Vector2(recurring_x_dir * -42.0,8.0))
			attack_collision.shape.extents = Vector2(42, 32)
			attack_collision.disabled = false

func get_damage():
	return damage

# Matches outfit's frame to current animation frame
func outfit_animation():
	$Sprite/Outfit.frame = $Sprite.frame
	$Sprite/BowL.frame = $Sprite.frame
	$Sprite/BowR.frame = $Sprite.frame
	$Sprite/BowL.visible = !$Sprite.flip_h
	$Sprite/BowR.visible = $Sprite.flip_h

# Handles hurt/death animations.
func do_hurt_animation():
	call_deferred("change_dash_hitbox", false)
	
	state = ST_HURT
	animation_timer = 0
	pattern_state = [0,0]
	pattern_timer = -18
	attempted_movement = 0
	jump_timer = 0
	charge_shot_timer = 0
	
	i_frames = max_i_frames
	
	_animation.play("Hurt")
	_velocity = Vector2(recurring_x_dir * -500.0,500* (-1 if !is_upside_down else 1) )
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL if !is_upside_down else -FLOOR_NORMAL)
	return

# Check if near walls, either walljump-able or not:
func _on_WalljumpAreaL_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(0) or body.get_collision_layer_bit(6):
		near_wall[0] = true
func _on_WalljumpAreaR_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(0) or body.get_collision_layer_bit(6):
		near_wall[1] = true
func _on_WalljumpAreaL_body_exited(_body: Node) -> void:
	near_wall[0] = false
	for box in $WalljumpAreaL.get_overlapping_bodies():
		if box.get_collision_layer_bit(0) or box.get_collision_layer_bit(6):
			near_wall[0] = true
func _on_WalljumpAreaR_body_exited(_body: Node) -> void:
	near_wall[1] = false
	for box in $WalljumpAreaR.get_overlapping_bodies():
		if box.get_collision_layer_bit(0) or box.get_collision_layer_bit(6):
			near_wall[1] = true

# Bounces if player was struck with a down slash.
func _on_AttackHitbox_area_entered(area):
	if not (attacking_direction == 2 and state == ST_AIR_ATTACK): return
	if not area.get_collision_layer_bit(1): return
	_velocity.y = 800.0 * (-1 if !is_upside_down else 1)

# Helper function to check if there is even room for a flameball to be made.
func room_for_projectile():
	var index_for_projectile = 0
	while index_for_projectile < 3:
		if list_of_projectiles[index_for_projectile] and is_instance_valid(list_of_projectiles[index_for_projectile])\
		and list_of_projectiles[index_for_projectile].get("active"):
			index_for_projectile += 1
		else:
			break
	if index_for_projectile >= 3:
		return -1
	return index_for_projectile

# Creates a flameball object based on the length of the current attack charge.
# Returns true iff there is enough room for a projectile.
func shoot_flameball(charge_length):
	var index_for_projectile = room_for_projectile()
	
	var current_scene = Globals.get_current_scene()
	if not current_scene: return
	var flameball_scene = attack_scenes[0 if charge_length < 45 else 1 if charge_length < 120 else 2]
	var spawn = flameball_scene.instance() as Node2D
	current_scene.add_child(spawn)
	spawn.set_as_toplevel(true)
	
	# Determines the position of shots based on the current state
	var shot_position = [54 if state == ST_DASH else 36,
		(-52 if state in [ST_IDLE, ST_AIR, ST_CLIMB, ST_LADDER_ATTACK] else
		-48 if state in [ST_WALK, ST_AIR_ATTACK, ST_WALLSLIDE, ST_WALL_ATTACK] else -32)]
	
	spawn.global_position = self.position + Vector2(recurring_x_dir*shot_position[0], shot_position[1])
	spawn.direction = recurring_x_dir > 0
	spawn.player_attack_type = 1 if charge_length < 45 else 3 if charge_length >= 120 else 2
	
	charge_shot_timer = 0
	list_of_projectiles[index_for_projectile] = spawn

# TODO: SHOOT OTHER TYPES OF PROJECTILES
func shoot_projectile():
	pass


func _on_Hitbox_area_entered(area):
	if i_frames: return
	if area.get_collision_layer_bit(4):
		health -= damage_data_chart[0]
		do_hurt_animation()
		return
	if area.get_collision_layer_bit(11):
		health -= damage_data_chart[area.player_attack_type]
		i_frames = max_i_frames
		return
