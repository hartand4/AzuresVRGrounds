extends Actor


# Timers
var jump_timer := 0
var stop_wallslide_timer := 0
var walljump_momentum_timer := 0
var dash_timer := 0
var attack_timer := 0
var dash_dust_timer := 0

var coyote_timer := 0
var acceleration_timer := 0

var charge_shot_timer := 0

# Booleans
export var dashing := false
export var air_dash_enabled := true
export var armour_enabled := false
export var ultimate_enabled := false
var dying_process := false

var did_ultimate_already := false

var started_dash_on_floor := false
export var colliding_with_enemy := false
var colliding_with_wall_l := false
var colliding_with_wall_r := false
var colliding_with_ladder := false
var colliding_with_ladder_top := false
var near_wall := [false, false]
export var collected_coins := [false, false, false]

export var normal_exit_reached = false
export var secret_exit_reached = false

# Hitboxes
onready var hitbox_collider = $PlayerHitboxArea/PlayerHitbox
onready var hitbox := $PlayerHitboxArea
onready var wjboxl := $WalljumpAreaL
onready var wjboxr := $WalljumpAreaR
onready var attack_collision := $AttackHitboxArea
onready var attack_particle := $SlashEffects/SlashEffect

# Other variables
onready var normal_hitbox_shape = hitbox_collider.shape.extents
onready var normal_hitbox_transform = [hitbox_collider.get_position(), $PlayerHitbox.get_position()]
onready var normal_wallcheck_shape = $WalljumpAreaL/WalljumpBoxL.shape.extents
onready var normal_wallcheck_transform = [$WalljumpAreaL/WalljumpBoxL.get_position(), $WalljumpAreaR/WalljumpBoxR.get_position()]

var camera_stop_object_list = []
onready var camera_limits

var ultimate_move_timer = [0,0,-1]

var stunned_shake_counter := 0
var needed_stunned_shakes := 15
var sprite_default_location
var stunned_bump_timer := 0

# 0 = sideways, 1 = up, 2 = down
var attacking_direction := 0
# 0 = slash, 1 = shots, 2 = lob shots, 3 = ??? TODO
export var current_attack := 0
# Scenes for the attack projectiles
var attack_scenes := [preload("res://src/objects/FlameBallS.tscn"),
	preload("res://src/objects/FlameBallM.tscn"),
	preload("res://src/objects/FlameBallL.tscn")]

export var ammo := 96
export var max_ammo := 96

var list_of_projectiles = [null, null, null]

var floor_angle := PI/2
var last_state := 0
var shot_damage := 5
var shot_velocity := Vector2.ZERO
var max_slope := PI/3
export var camera_limit_min = Vector2(0,0)
export var camera_limit_max = Vector2(10000000, 10000)

var animation_dict := {ST_WALLJUMP: 'Walljump',ST_ULTIMATE: "Ultimate"}

# From enemy
var damage_doing := 0

func _ready():
	max_health = Globals.set_health
	health = max_health
	recurring_x_dir = 1
	call_deferred("_do_transition")
	change_dash_hitbox(false)
	normal_exit_reached = false
	secret_exit_reached = false
	state = ST_AIR
	
	# Unlocked abilities
	air_dash_enabled = Globals.air_dash_unlocked and Globals.air_dash_selected
	armour_enabled = Globals.armour_unlocked and Globals.armour_selected
	ultimate_enabled = Globals.ultimate_unlocked and Globals.ultimate_selected
	
	# Set camera limits
	$Camera2D.limit_left = camera_limit_min.x
	$Camera2D.limit_top = camera_limit_min.y
	$Camera2D.limit_right = camera_limit_max.x
	$Camera2D.limit_bottom = camera_limit_max.y
	
	# Respawn at checkpoint location if passed one
	if Globals.checkpoint_data[0]:
		position = Globals.checkpoint_data[4]
		for i in range(3):
			collected_coins[i] = Globals.checkpoint_data[i+1]
	
	# Cute outfit.jpeg
	var outfit_list = ['Shorts', 'Casual', 'Ace', 'Maid']
	$Sprite/Outfit.texture = load("res://assets/Sprites/Azzy/Outfits/" + outfit_list[Globals.current_costume] + ".png")
	
	# Possible use for getting stunned
	sprite_default_location = $Sprite.position
	
	# For any camera stop objects
	camera_limits = [$Camera2D.limit_top, $Camera2D.limit_bottom,
		$Camera2D.limit_left, $Camera2D.limit_right]
	
	scale.y = -1 if is_upside_down else 1

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	var is_jumping := false
	
	var floor_normal = -FLOOR_NORMAL if is_upside_down else FLOOR_NORMAL
	
	if Globals.get("game_paused"):
		return
	elif Input.is_action_just_pressed("pause") and not Globals.lock_input and (
		not Globals.retry_menu_on) and not state in [ST_VICTORY]:
		Globals.set("game_paused", true)
		Globals.pause_menu_on = true
		_velocity = move_and_slide(_velocity, floor_normal, true) if not jump_timer else _velocity
		return
	elif state == ST_OFFLOAD:
		# This offloads the logic onto another script, so we can ignore the physics
		return
		
	# Jump logic
	if state in [0,1,3,4,5,8]:
		if jump_timer > 0:
			jump_timer -= 1
		elif is_on_floor() or coyote_timer > 0:
			jump_timer = 0
			if Input.is_action_just_pressed("jump"):
				jump_timer = 30
				if coyote_timer > 0:
					_velocity.y = pow(30,4)/2150 * (-1 if !is_upside_down else 1)
					coyote_timer = 0
			else:
				jump_timer = 0
		is_jumping = Input.is_action_pressed("jump") and jump_timer > 0 and\
			((_velocity.y < 0 and !is_upside_down) or (_velocity.y > 0 and is_upside_down))
		if not Input.is_action_pressed("jump"):
			jump_timer = 0
		
		if walljump_momentum_timer == 0:
			# Get direction of input
			direction = get_direction_normal()
		
		# Exceptions to the direction normal
		if state == ST_ATTACK:
			direction.x = 0.0
		
		if direction.x != 0.0 and walljump_momentum_timer == 0 and not (
			state in [ST_AIR_ATTACK, ST_WALLSLIDE]):
				recurring_x_dir = direction.x
			
			
		# Check double jump
		#if is_on_floor():
		#	double_jumped = false
		#elif Input.is_action_just_pressed("jump") and not double_jumped:
		#	double_jumped = true
			
	elif state == ST_HURT:
		direction.x = recurring_x_dir * -0.5
	
	elif state in [ST_STUNNED, ST_STUNNED_DRAG]:
		if Input.is_action_just_pressed("move_left"):
			recurring_x_dir = -1
		elif Input.is_action_just_pressed("move_right"):
			recurring_x_dir = 1
		
	elif state == ST_DASH:
		if jump_timer > 0:
			jump_timer -= 1
		elif Input.is_action_just_pressed("jump"):
			jump_timer = 30
		is_jumping = Input.is_action_pressed("jump") and jump_timer > 0 and\
			((_velocity.y < 0 and !is_upside_down) or (_velocity.y > 0 and is_upside_down))
		direction = get_direction_normal()
		direction.x = recurring_x_dir
		
	# If still in walljumping state
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
	elif state == ST_WALLJUMP:
		_velocity = Vector2.ZERO
	elif state == ST_CLIMB:
		_velocity = Vector2.ZERO
		if Input.is_action_pressed("move_up"):
			self.position.y -= 4
		elif Input.is_action_pressed("move_down"):
			self.position.y += 4
		# warning-ignore:return_value_discarded
		move_and_slide(_velocity, floor_normal, true)
		return
	elif state == ST_DASH:
		if not is_on_floor() and air_dash_enabled:
			_velocity.y = 0
	elif state in [ST_LADDER_ATTACK, ST_STUNNED_DRAG]: return
	elif state == ST_ULTIMATE:
		_velocity = Vector2(recurring_x_dir*500, 0)
	
	if dashing and state != ST_HURT: _velocity.x *= 1.8
		
	# Check for slopes
	if is_on_floor():
		var factor = abs(sin(floor_angle))
		if cos(floor_angle)*recurring_x_dir > 0 and factor != 0: factor=1/factor
		_velocity.x *= factor
	
	if not is_jumping:
		_velocity = move_and_slide_with_snap(_velocity, snap, floor_normal, true)
	else:
		#corner_correction(6)
		_velocity = move_and_slide(_velocity, floor_normal, true)

func get_direction_normal() -> Vector2:
	if Globals.lock_input: return Vector2.DOWN
	return Vector2(
		ceil(Input.get_action_strength("move_right")) - ceil(Input.get_action_strength("move_left")),
		-1.0 if Input.is_action_just_pressed("jump") and (is_on_floor()) else 1.0 #or not double_jumped) else 1.0
	)

func calculate_move_direction(linear_velocity: Vector2, speed: Vector2, direction: Vector2, is_jumping: bool) -> Vector2:
	var out_vel := linear_velocity
	var speed_x_factor := 0.1 if (state == ST_IDLE or acceleration_timer > 3) else 0.3 if acceleration_timer > 0 else 1.0
	out_vel.x = speed.x * direction.x * speed_x_factor
	out_vel.y += gravity / 60.0 * (3.0 if is_in_water and\
		((_velocity.y < 0 and !is_upside_down) or (_velocity.y > 0 and is_upside_down)) and
		jump_timer == 0 else 1.0) * (-1 if is_upside_down else 1)#*get_physics_process_delta_time()
	if direction.y == -1.0:
		out_vel.y = (500.0 * direction.y)*(-1 if is_upside_down else 1) - linear_velocity.y
		
		# Account for slope jump boost
		if out_vel.x != 0:
			var factor = abs(sin(floor_angle))
			if cos(floor_angle)*recurring_x_dir > 0 and factor != 0: factor=1/factor
			out_vel.y *= (factor+2)/3
	if is_jumping:
		out_vel.y -= 1*pow(jump_timer,4)/4600*(-1 if is_upside_down else 1) #First few frames matter more
	return out_vel

func _process(_delta):
	if not (state in [ST_ATTACK, ST_AIR_ATTACK, ST_WALL_ATTACK, ST_LADDER_ATTACK]):
		do_slash_effect(0)
	
	outfit_animation()
	
	if Globals.get("game_paused"):
		$Tail/TailAnimation.playback_speed = 0
		if Globals.pause_menu_on:
			do_pause_menu()
		return
	
	$Tail/TailAnimation.playback_speed = 1
	
	# Don't trigger idle animation while input is locked
	if Globals.lock_input and state == ST_IDLE:
		animation_timer = 0
	
	# Checks to kill player: health <= 0 or too far offscreen
	if health <= 0:
		if not dying_process:
			do_hurt_animation(0)
		if animation_timer < 40: return
		Globals.retry_menu_on = true
		Globals.lock_input = false
	elif (position.y > $Camera2D.get_camera_screen_center().y + 600 and
			$Camera2D.current and !is_upside_down) or\
		(position.y < $Camera2D.get_camera_screen_center().y - 600 and
			$Camera2D.current and is_upside_down):
		animation_timer = 0
		do_hurt_animation(max_health*2)
		$Camera2D.current = false
	
	# Bound the health and ammo
	if health < 0: health = 0
	elif health > max_health: health = max_health
	if ammo < 0: ammo = 0
	elif ammo > max_ammo: ammo = max_ammo
	
	
	if stop_wallslide_timer: stop_wallslide_timer -= 1
	if walljump_momentum_timer: walljump_momentum_timer -= 1
	if dash_timer: dash_timer -= 1
	elif is_on_floor(): dashing = false
	if attack_timer: attack_timer -= 1
	
	if current_attack == 1 and Input.is_action_pressed("attack") and !Globals.lock_input:
		charge_shot_timer += 1
		if charge_shot_timer > 200:
			charge_shot_timer -= 20
	
	if state != ST_AIR: coyote_timer = 0
	coyote_timer = coyote_timer - 1 if coyote_timer > 0 else 0
	if state != ST_WALK: acceleration_timer -= 1
	acceleration_timer = acceleration_timer - 1 if acceleration_timer > 0 else 0
	
	# Ultimate_move_check
	if not ultimate_enabled or state > 5 or health < max_health: ultimate_move_timer = [0,0,-1]
	elif ultimate_enabled:
		do_ultimate_check()
	$UltimateHitboxArea/CollisionShape2D.disabled = state != ST_ULTIMATE
	if state == ST_ULTIMATE:
		check_ultimate_hitbox_enemies()
	
	if state == ST_VICTORY and is_on_floor():
		victory_handler()
		return
	
	check_for_collisions()
	
	if Input.is_action_just_pressed("toggle_weapons_l") and !Globals.lock_input:
		current_attack = (current_attack + 3) % 4
		while !Globals.attacks_unlocked[current_attack]:
			current_attack = (current_attack + 3) % 4
			if current_attack == 0: break
	if Input.is_action_just_pressed("toggle_weapons_r") and !Globals.lock_input:
		current_attack = (current_attack + 1) % 4
		while !Globals.attacks_unlocked[current_attack]:
			current_attack = (current_attack + 1) % 4
			if current_attack == 0: break
	
	if last_state != state:
		print("state: %s" % state)
		last_state = state
	

# Handles various animations of player using state. Also calls change_dash_hitbox to match dash sprite
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
	$Sprite/HurtEffect.visible = false
	
	scale.y = -1 if is_upside_down else 1
	
	$SlashEffects/UltimateFire.visible = state == ST_ULTIMATE and animation_timer > 4 and animation_timer < 42
	$SlashEffects/UltimateFire.flip_h = recurring_x_dir == 1
	
	
	if i_frames % 8 >= 6:
		$Sprite.visible = false
		$Tail.visible = false
		$TailWall.visible = false
	
	# Tail Animation
	if state in [ST_CLIMB, ST_LADDER_ATTACK]:
		$Tail.z_index = 1
		$Tail.set_position(Vector2(recurring_x_dir*-32,-35))
	elif state in [ST_DASH, ST_ULTIMATE]:
		$Tail.z_index = 0
		$Tail/TailAnimation.play("TailStraight")
		if animation_timer > 4:
			$Tail.set_position(Vector2(recurring_x_dir*-35,-20))
			
		else:
			$Tail.set_position(Vector2(recurring_x_dir*-45,-30))
	elif state == ST_WALLSLIDE or state == ST_WALL_ATTACK:
		$TailWall.visible = true
		$Tail.visible = false
		$TailWall.flip_h = recurring_x_dir + 1
		$Tail/TailAnimation.play("TailWall")
		$TailWall.set_position(Vector2(recurring_x_dir*3,-5))
	elif state == ST_WALK:
		$Tail.set_position(Vector2(recurring_x_dir*-36,-35))
	else:
		$Tail.z_index = 0
		$Tail.set_position(Vector2(recurring_x_dir*-28,-35))
	
	# Add hand for dash + shoot sprite
	if $Sprite.frame == 59:
		$Sprite/DashHand.visible = true
		$Sprite/DashHand.position.x = recurring_x_dir*26.5
		$Sprite/DashHand.flip_h = recurring_x_dir + 1
	
	#Outfit flip
	$Sprite/Outfit.flip_h = $Sprite.flip_h
	
	if health > 0: change_dash_hitbox(state in [ST_DASH, ST_ULTIMATE])
	
	# Sprite bumping during stun
	if not state in [ST_STUNNED, ST_STUNNED_DRAG]: stunned_bump_timer = 0
	if stunned_bump_timer > 0: stunned_bump_timer -= 1
	$Sprite.position = sprite_default_location if not (
		state in [ST_STUNNED, ST_STUNNED_DRAG] and stunned_bump_timer
	) else $Sprite.position
	
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
	
	if state in animation_dict:
		_animation.play(animation_dict[state])
		$Sprite/Outfit.frame = $Sprite.frame
		return
	match state:
		ST_IDLE:
			if current_attack == 0 or attack_timer <= 0 or last_state != 0:
				if current_attack != 0: attack_timer = 0
				if _animation.current_animation == "Idle" and animation_timer > 0 and\
					animation_timer % 600 == 0:
					print("why?")
					var idle_variation = Globals.call_rng(1,2)
					_animation.play("IdleVar"+str(idle_variation))
				elif _animation.current_animation == "IdleVar1":
					if animation_timer % 600 == 594:
						_animation.play("Idle")
						animation_timer = 0
				elif _animation.current_animation == "IdleVar2":
					if animation_timer % 600 == 306:
						_animation.play("Idle")
						animation_timer = 0
				else:
					_animation.play("Idle")
			else:
				_animation.play("Shoot")
				if Input.is_action_just_pressed("attack"):
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
			_animation.play('Ground Slash' if attacking_direction == 0 else 'Ground Slash Up')
			_animation.seek((18-attack_timer)/60.0)
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
		ST_LADDER_ATTACK:
			if !current_attack:
				_animation.play('Ladder Slash')
				if animation_timer == 6:
					do_slash_effect(2)
				update_slash_hitbox()
			else:
				_animation.stop()
				$Sprite.frame = 61
				#_animation.play("Ladder Shoot")
		ST_CLIMB:
			if Input.is_action_pressed("move_up"):
				_animation.play('Climb')
			elif Input.is_action_pressed("move_down"):
				_animation.play_backwards('Climb')
			else:
				_animation.stop(false)
		ST_WALLSLIDE:
			if current_attack == 0 or !attack_timer:
				_animation.play("Wallslide")
			else:
				_animation.play("Wallslide + Shoot")
			if Globals.timer % 7 == 0 and animation_timer > 5:
				spawn_dust_particle()
		ST_VICTORY:
			if not is_on_floor(): animation_timer = 0
			elif animation_timer < 20:
				_animation.play('Victory')
			else:
				_animation.play("Victory2")
		ST_STUNNED:
			$AnimationPlayer.play("Hurt")
			if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump") or (
				Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_up") or
				Input.is_action_just_pressed("dash")
				):
				$Sprite.position.x += 6 if stunned_shake_counter % 2 == 0 else -6
				stunned_bump_timer = 2
		ST_STUNNED_DRAG:
			$AnimationPlayer.play("Hurt")
			if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump") or (
				Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_up") or
				Input.is_action_just_pressed("dash")
				):
				$Sprite.position.x += 6 if stunned_shake_counter % 2 == 0 else -6
				stunned_bump_timer = 2
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
		ST_HURT:
			$Sprite/HurtEffect.flip_h = recurring_x_dir > 0
			$Sprite/HurtEffect.visible = animation_timer % 10 >= 5 and animation_timer % 10 <= 8

# Updates the player state if game unpaused. Also updates attack_timer and dashing variables,
# and calls start_walljump()
func update_state():
	if Globals.game_paused:
		return state
	elif Globals.lock_input:
		return 0 if is_on_floor() else state
	
	var dir = Vector2(
		-1.0 if Input.is_action_pressed("move_left") else 1.0 if Input.is_action_pressed("move_right") else 0.0,
		1.0 if Input.is_action_pressed("move_down") else -1.0 if Input.is_action_pressed("move_up") else 0.0)
	
	if normal_exit_reached or secret_exit_reached: return ST_VICTORY
	
	# GETTING HURT
	if state == ST_HURT:
		if animation_timer < 20 or health == 0: return ST_HURT
		state = 0
		return update_state()
	# Consider other states, like wallslide taking damage
	if not (state in [ST_HURT, ST_OFFLOAD, ST_ULTIMATE]) and colliding_with_enemy and i_frames == 0:
		do_hurt_animation(damage_doing)
		return ST_HURT
	
	# STUNNED STATE, SHAKE OUT OF IT
	if state == ST_STUNNED:
		if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump") or (
			Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_up") or
			Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right") or
			Input.is_action_just_pressed("dash")
		):
			stunned_shake_counter += 1
		if stunned_shake_counter >= needed_stunned_shakes:
			state = ST_IDLE
			return update_state()
	
	# STOP DOING ULTIMATE AFTER TIME EXPIRES
	if state == ST_ULTIMATE:
		if animation_timer >= 45:
			state = ST_IDLE
			return update_state()
	
	# DOING AN AIR ATTACK
	if state == ST_AIR and did_attack():
		if current_attack == 1: shoot_flameball(charge_shot_timer)
		elif current_attack > 1: shoot_projectile()
		attack_timer = 18
		if current_attack == 0:
			attacking_direction = 1 if Input.is_action_pressed("move_up" if !is_upside_down else "move_down")\
				else 2 if Input.is_action_pressed("move_down" if !is_upside_down else "move_up") else 0
			return ST_AIR_ATTACK
		return state
	elif state == ST_DASH and did_attack() and not is_on_floor():
		if current_attack == 1: shoot_flameball(charge_shot_timer)
		elif current_attack > 1: shoot_projectile()
		attack_timer = 18
		if current_attack == 0:
			attacking_direction = 1 if Input.is_action_pressed("move_up" if !is_upside_down else "move_down")\
				else 2 if Input.is_action_pressed("move_down" if !is_upside_down else "move_up") else 0
			return ST_AIR_ATTACK
		return state
	if state == ST_AIR_ATTACK and attack_timer <= 0: return ST_AIR
	
	# SLIDING ON A WALL
	if state in [ST_AIR, ST_AIR_ATTACK] and is_on_wall() and\
		((_velocity.y > 0 and !is_upside_down) or (_velocity.y < 0 and is_upside_down)):
		if (colliding_with_wall_l and dir.x < 0) or (colliding_with_wall_r and dir.x > 0):
			stop_wallslide_timer = 8
			recurring_x_dir = 1 if dir.x < 0 else -1
			dash_timer = 0
			dashing = false
			_velocity.y = 100.0 * (-1 if !is_upside_down else 1)
			return ST_WALLSLIDE
		
	# CONTINUE SLIDING ON WALL, OR WALLJUMP WHILE SLIDING
	if state == ST_WALLSLIDE or state == ST_WALL_ATTACK:
		if is_on_floor():
			stop_wallslide_timer = 0
			return ST_IDLE
		elif Input.is_action_just_pressed('jump'):
			recurring_x_dir *= -1
			return start_walljump()
		if not (colliding_with_wall_l or colliding_with_wall_r):
			stop_wallslide_timer = 0
			return ST_AIR
		if not ((colliding_with_wall_l and dir.x < 0) or (colliding_with_wall_r and dir.x > 0)):
			if stop_wallslide_timer == 0:
				return ST_AIR
		else:
			stop_wallslide_timer = 8
		
		if did_attack():
			if current_attack == 1: shoot_flameball(charge_shot_timer)
			elif current_attack > 1: shoot_projectile()
			attack_timer = 18
			return ST_WALL_ATTACK if !current_attack else state
			
	# ANOTHER WAY TO WALLJUMP
	if state == ST_AIR and Input.is_action_just_pressed('jump') and (colliding_with_wall_l or colliding_with_wall_r):
		recurring_x_dir = -1 if colliding_with_wall_l else 1
		return start_walljump()
			
	# WALLJUMP LAG
	if state == ST_WALLJUMP and stop_wallslide_timer == 0:
		walljump_momentum_timer = 4
		_velocity.y = 500 * (-1 if !is_upside_down else 1)
		jump_timer = 29
		return ST_AIR
	
	# WALL ATTACK
	if state == ST_WALL_ATTACK:
		if is_on_floor():
			attack_timer = 0
			return ST_IDLE
		elif attack_timer <= 0:
			return ST_WALLSLIDE
		elif Input.is_action_just_pressed("jump"):
			attack_timer = 0
			recurring_x_dir *= -1
			return start_walljump()
	
	# FLOOR DASHING OR AIR DASHING
	if ((state == ST_AIR and air_dash_enabled) or state in [0,1,4]) and Input.is_action_just_pressed("dash"):
		if not(near_wall[int((recurring_x_dir+1)/2)]) and not dashing:
			dashing = true
			dash_timer = 40 if is_on_floor() else 20
			started_dash_on_floor = is_on_floor()
			$DashDust.do_dash()
			return ST_DASH
	
	# WHILE FLOOR DASHING OR AIR DASHING
	if state == ST_DASH:
		if near_wall[int((recurring_x_dir+1)/2)] or dir.x == -recurring_x_dir or (
			not Input.is_action_pressed('dash') or dash_timer == 0) or (
				started_dash_on_floor and not is_on_floor()
			):
			state = ST_AIR
			dash_timer = 0
			if (started_dash_on_floor and not is_on_floor()): set_coyote_timer()
			return update_state()
	
	# ATTACKING
	if state < 3 and did_attack():
		if current_attack == 0: dashing = false
		elif current_attack == 1: shoot_flameball(charge_shot_timer)
		elif current_attack > 1: shoot_projectile()
		attack_timer = 18
		attacking_direction = 1 if (Input.is_action_pressed("move_up" if !is_upside_down else "move_down")
			and current_attack == 0) else 0
		return ST_ATTACK if current_attack == 0 else state
	
	#STOP ATTACK
	if state == ST_ATTACK and attack_timer <= 0:
		state = 0
		attack_timer = 0
		return update_state()
	
	#CLIMB LADDER
	if (state < 6 and colliding_with_ladder and dir.y < 0) or (
		state < 3 and colliding_with_ladder and dir.y != 0):
		dashing = false
		self.position.x = nearest_block(self.position.x)
		_animation.play('Climb')
		return ST_CLIMB
		
	if state < 3 and colliding_with_ladder_top and dir.y > 0:
		self.position = Vector2(nearest_block(self.position.x), self.position.y+48)
		_animation.play('Climb')
		$Sprite.frame = 21
		return ST_CLIMB
		
	if state == ST_CLIMB:
		if colliding_with_ladder_top and not colliding_with_ladder and dir.y < 0:
			state = ST_IDLE
			self.position.y = nearest_block(self.position.y)-24
			_velocity = Vector2.ZERO
		elif not(colliding_with_ladder or colliding_with_ladder_top) or Input.is_action_just_pressed('jump'):
			state = ST_AIR
		if did_attack():
			if current_attack == 1: shoot_flameball(charge_shot_timer)
			elif current_attack > 1: shoot_projectile()
			if dir.x != 0:
				recurring_x_dir = dir.x
			attack_timer = 18 if !current_attack else 12
			return ST_LADDER_ATTACK
	
	# LADDER ATTACK
	if state == ST_LADDER_ATTACK:
		if attack_timer <= 0:
			_animation.play('Climb')
			$Sprite.frame = 21
			return ST_CLIMB
		elif current_attack and did_attack():
			if current_attack == 1: shoot_flameball(charge_shot_timer)
			elif current_attack > 1: shoot_projectile()
			attack_timer = 18
			return state
	
	### if interaction finished: return ST_IDLE
	
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
	if state in [0,1,2,4] and Input.is_action_just_pressed("jump"): 
		if is_on_floor() or state < 2:
			dashing = state == 2
			return ST_AIR
	elif state in [0,1,4] and not is_on_floor():
		set_coyote_timer()
		return ST_AIR
	
	#if state < 2 and Input.is_action_just_pressed("interact") and interactable thing: return ST_INTERACT
	elif state < 2 and dir.x != 0:
		if state == 0 and (Input.is_action_just_pressed("move_left") or 
			Input.is_action_just_pressed("move_right")): acceleration_timer = 4
		return ST_WALK
	elif state < 2 and dir.x == 0: return ST_IDLE
	return state

# Briefly creates some walljumping frames and checks for dash being held
func start_walljump():
	stop_wallslide_timer = 6
	if not Input.is_action_pressed('dash'):
		dash_timer = 0
		dashing = false
	else: dashing = true
	return ST_WALLJUMP

# Redundant function with PauseMenuLevel
func do_pause_menu():
	return

# Animates the slash effect and prepares the initial hitboxes accordingly.
# start -> 0=end, 1=normal, 2=wall, 3=up, 4=down
func do_slash_effect(start):
	match start:
		0:
			attack_particle.visible = false
			$SlashEffects/SlashEffectAlt.visible = false
			$SlashEffects/SlashEffectUp.visible = false
			$SlashEffects/SlashEffectDown.visible = false
			attack_collision.find_node('AttackHitbox').disabled = true
		1:
			attack_particle.visible = true
			attack_particle.flip_h = (recurring_x_dir + 1)/2
	
			attack_collision.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * 2.0,-46))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(48.75, 16)
			attack_collision.find_node('AttackHitbox').disabled = false
		2:
			$SlashEffects/SlashEffectAlt.visible = true
			$SlashEffects/SlashEffectAlt.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffectAlt.position.x = recurring_x_dir*61
			
			attack_collision.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * 10.0,-60))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(40.75, 34)
			attack_collision.find_node('AttackHitbox').disabled = false
		3:
			$SlashEffects/SlashEffectUp.visible = true
			$SlashEffects/SlashEffectUp.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffectUp.position.x = recurring_x_dir*-4
			
			attack_collision.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * -46,-111.0))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(41.5, 29)
			attack_collision.find_node('AttackHitbox').disabled = false
		4:
			$SlashEffects/SlashEffectDown.visible = true
			$SlashEffects/SlashEffectDown.flip_h = (recurring_x_dir + 1)/2
			$SlashEffects/SlashEffectDown.position.x = recurring_x_dir*6
			
			attack_collision.set_position(Vector2(recurring_x_dir * 48.0,0))
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * -42.0,8.0))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(42, 32)
			attack_collision.find_node('AttackHitbox').disabled = false

# Updates the slash hitboxes throughout the full slash effect
func update_slash_hitbox():
	if state in [ST_ATTACK, ST_AIR_ATTACK] and attacking_direction == 0:
		if $SlashEffects/SlashEffect.frame == 1:
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * -36.0,-40))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(62, 18)
		elif $SlashEffects/SlashEffect.frame == 2:
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * -102.0,-38))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(26, 12)
	
	elif state in [ST_ATTACK, ST_AIR_ATTACK] and attacking_direction == 1:
		if $SlashEffects/SlashEffectUp.frame == 1:
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * -85.0,-102))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(15, 22)
	
	elif state == ST_AIR_ATTACK and attacking_direction == 2:
		if $SlashEffects/SlashEffectDown.frame == 1:
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * -76.0,-1.0))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(8, 23)
	
	elif state in [ST_WALL_ATTACK, ST_LADDER_ATTACK]:
		if $SlashEffects/SlashEffectAlt.frame == 1:
			attack_collision.find_node('AttackHitbox').set_position(Vector2(recurring_x_dir * 6.0,-34))
			attack_collision.find_node('AttackHitbox').shape.extents = Vector2(32,14)

# Lowers player health by damage (halved if armour) and handles hurt/death animations.
# Called in _process function if health <= 0
func do_hurt_animation(damage):
	if armour_enabled:
		damage = ceil(float(damage)/2)
	health -= damage
	if damage > 0:
		i_frames = 60
	change_dash_hitbox(false)
	
	state = ST_HURT
	animation_timer = 0
	
	_animation.play("Hurt")
	_velocity = Vector2(recurring_x_dir * -500.0,500* (-1 if !is_upside_down else 1) )
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL if !is_upside_down else -FLOOR_NORMAL)
	if health <= 0:
		
		# Just for bookkeeping
		if $Camera2D.current:
			Globals.set_current_camera_pos($Camera2D.get_camera_screen_center())
		
		$Camera2D.current = false
		$PlayerHitbox.disabled = true
		$PlayerHitboxArea/PlayerHitbox.disabled = true
		$PlayerDashHitbox.disabled = true
		colliding_with_enemy = false
		Globals.lock_input = true
		animation_timer = 0
		dying_process = true
		

	return

# Alters dash hitbox and walljump/crush detectors based on the dashing state
func change_dash_hitbox(dash_state):
	if dash_state:
		hitbox_collider.shape.extents = Vector2(11.5, 27.0)
		hitbox_collider.set_position(Vector2(0.0, 12.0))
		#$PlayerHitbox.set_position(Vector2(0.0, -29.0))
		$PlayerHitbox.disabled = true
		$PlayerDashHitbox.disabled = false
		$WalljumpAreaL/WalljumpBoxL.shape.extents = Vector2(13.0,30.0)
		$WalljumpAreaL/WalljumpBoxL.set_position(Vector2(normal_wallcheck_transform[0][0], -40))
		$WalljumpAreaR/WalljumpBoxR.set_position(Vector2(normal_wallcheck_transform[1][0], -40))
		
		$CrushCheckArea/Collision.disabled = true
		$CrushCheckArea/DashCollision.disabled = false
		return
	
	hitbox_collider.shape.extents = normal_hitbox_shape
	hitbox_collider.set_position(normal_hitbox_transform[0])
	#$PlayerHitbox.set_position(normal_hitbox_transform[1])
	$PlayerHitbox.disabled = false
	$PlayerDashHitbox.disabled = true
	$WalljumpAreaL/WalljumpBoxL.shape.extents = normal_wallcheck_shape
	$WalljumpAreaL/WalljumpBoxL.set_position(normal_wallcheck_transform[0])
	$WalljumpAreaR/WalljumpBoxR.set_position(normal_wallcheck_transform[1])
	
	$CrushCheckArea/Collision.disabled = false
	$CrushCheckArea/DashCollision.disabled = true

# Updates the floor angle, and checks for crush death
func check_for_collisions():
	# Record floor normal angle if on floor
	if is_on_floor() and get_slide_count() > 0:
		floor_angle = -get_slide_collision(0).normal.angle()
		if abs(cos(floor_angle)) > cos(PI/2-max_slope):
			floor_angle = PI/2
	
	# Check for crush death
	for box in $CrushCheckArea.get_overlapping_bodies():
		if (box.get_collision_layer_bit(0) or box.get_collision_layer_bit(6)) and near_wall[0] and (
			near_wall[1] and not box.get_collision_layer_bit(8)):
			colliding_with_enemy = true
			damage_doing = max_health * 2

# Does a transition effect in centre of screen
func _do_transition():
	Globals.start_transition(Vector2(432, 312), 2)

# Checks the areas (enemy, ladder, water,...) colliding with the player
func _on_PlayerHitboxArea_area_entered(area: Area2D) -> void:
	if state == ST_OFFLOAD: return
	# Check if the player is colliding with other areas (enemies or damage tiles)
	if (area.get_collision_layer_bit(2) or area.get_collision_layer_bit(7) or 
		area.get_collision_layer_bit(5)) and !colliding_with_enemy:
		colliding_with_enemy = true
		# If an enemy...
		if area.has_method("get_damage"):
			# warning-ignore:narrowing_conversion
			damage_doing = area.get_damage()
		elif area.get_parent().has_method("get_damage"):
			# warning-ignore:narrowing_conversion
			damage_doing = area.get_parent().get_damage()
		else:
			print('no get_damage() function')
			damage_doing = 0
	elif area.get_collision_layer_bit(8):
		colliding_with_ladder = true
	
	elif area.get_collision_layer_bit(9):
		is_in_water = true

func _on_PlayerHitboxArea_area_exited(area: Area2D) -> void:
	if state == ST_OFFLOAD: return
	if area.get_collision_layer_bit(9):
		is_in_water = false
		return
	colliding_with_enemy = false
	colliding_with_ladder = false
	for box in hitbox.get_overlapping_areas():
		if (box.get_collision_layer_bit(2) or box.get_collision_layer_bit(7) or 
		box.get_collision_layer_bit(5)) and not colliding_with_enemy:
			colliding_with_enemy = true
			# If an enemy...
			if box.has_method("get_damage"):
				# warning-ignore:narrowing_conversion
				damage_doing = box.get_damage()
			elif box.get_parent().has_method("get_damage"):
				# warning-ignore:narrowing_conversion
				damage_doing = box.get_parent().get_damage()
			else:
				print('no get_damage() function')
				damage_doing = 0
		elif box.get_collision_layer_bit(8):
			colliding_with_ladder = true

# Check if near walls, either walljump-able or not:
func _on_WalljumpAreaL_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(0):
		colliding_with_wall_l = true
		near_wall[0] = true
	elif body.get_collision_layer_bit(6):
		near_wall[0] = true
func _on_WalljumpAreaR_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(0):
		colliding_with_wall_r = true
		near_wall[1] = true
	elif body.get_collision_layer_bit(6):
		near_wall[1] = true

func _on_WalljumpAreaL_body_exited(_body: Node) -> void:
	colliding_with_wall_l = false
	near_wall[0] = false
	for box in wjboxl.get_overlapping_bodies():
		if box.get_collision_layer_bit(0):
			colliding_with_wall_l = true
			near_wall[0] = true
		elif box.get_collision_layer_bit(6):
			near_wall[0] = true
func _on_WalljumpAreaR_body_exited(_body: Node) -> void:
	colliding_with_wall_r = false
	near_wall[1] = false
	for box in wjboxr.get_overlapping_bodies():
		if box.get_collision_layer_bit(0):
			colliding_with_wall_r = true
			near_wall[1] = true
		elif box.get_collision_layer_bit(6):
			near_wall[1] = true

# Check for ladder top
func _on_LadderTopArea_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(8):
		colliding_with_ladder_top = true
func _on_LadderTopArea_body_exited(_body: Node) -> void:
	colliding_with_ladder_top = false
	for box in $LadderTopArea.get_overlapping_bodies():
		if box.get_collision_layer_bit(8):
			colliding_with_ladder_top = true

# Reloads current level
func reload_level():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(get_tree().current_scene.filename)

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

# Handles victory protocol when in victory state and on floor initially. Loads map after some time
func victory_handler():
	if animation_timer < 80: return
	elif animation_timer == 80:
		if $Camera2D.current:
			Globals.start_transition(get_position() - $Camera2D.get_camera_screen_center() +
				Vector2(432,272 if !is_upside_down else 352), 1)
		else:
			Globals.start_transition(get_position() - Globals.get_current_camera_pos() + 
				Vector2(432,272 if !is_upside_down else 352), 1)
		Globals.goal_reached_in_current_level[0] = normal_exit_reached
		Globals.goal_reached_in_current_level[1] = secret_exit_reached
		for i in range(3):
			Globals.coins_collected_in_level[i] = collected_coins[i]
	
	elif animation_timer >= 200:
		# warning-ignore:return_value_discarded
		get_tree().change_scene("res://src/levels/LevelMap.tscn")

# Handles checks to perform ultimate. ultimate_move_timer is in the form [index, time left, direction]
# where index is how many moves in you are, time left is the time that you still have to complete the next move,
# and direction is -1 if left was tapped first, or 1 if right was.
func do_ultimate_check():
	var ULTIMATE_TIMER := 45
	if is_on_floor():
		did_ultimate_already = false
	if ultimate_move_timer[0] and not ultimate_move_timer[1]:
		ultimate_move_timer = [0,0,-1]
		return
	match ultimate_move_timer[0]:
		0:
			if Input.is_action_just_pressed('move_down' if !is_upside_down else 'move_up'):
				ultimate_move_timer = [1,ULTIMATE_TIMER,-1]
		1:
			if Input.is_action_just_pressed("move_left"):
				ultimate_move_timer[0] = 2
				ultimate_move_timer[2] = -1
			elif Input.is_action_just_pressed("move_right"):
				ultimate_move_timer[0] = 2
				ultimate_move_timer[2] = 1
			elif Input.is_action_just_pressed('move_down' if !is_upside_down else 'move_up'):
				ultimate_move_timer[1] = ULTIMATE_TIMER
			else:
				for action in ['move_up' if !is_upside_down else 'move_down', 'jump', 'attack', 'dash', 'pause']:
					if Input.is_action_just_pressed(action): ultimate_move_timer = [0,0,-1]
		2:
			if Input.is_action_just_pressed('move_left'):
				if ultimate_move_timer[2] == 1: ultimate_move_timer[0] = 3
				elif ultimate_move_timer[2] == -1: ultimate_move_timer[0] = 0
			if Input.is_action_just_pressed('move_right'):
				if ultimate_move_timer[2] == -1: ultimate_move_timer[0] = 3
				elif ultimate_move_timer[2] == 1: ultimate_move_timer[0] = 0
			elif Input.is_action_just_pressed('move_down' if !is_upside_down else 'move_up'):
				ultimate_move_timer = [1,ULTIMATE_TIMER,-1]
			else:
				for action in ['jump', 'attack', 'dash', 'pause']:
					if Input.is_action_just_pressed(action): ultimate_move_timer = [0,0,-1]
		3:
			if Input.is_action_just_pressed("attack") and not did_ultimate_already:
				state = ST_ULTIMATE
				animation_timer = 0
				dashing = false
				ultimate_move_timer = [0,0,-1]
				# Comment out this line for some real fun
				did_ultimate_already = true
			else:
				for action in ['move_up', 'move_down', 'move_left', 'move_right', 'jump', 'dash', 'pause']:
					if Input.is_action_just_pressed(action): ultimate_move_timer = [0,0,-1]
	if ultimate_move_timer[1]: ultimate_move_timer[1] -= 1

# Matches outfit's frame to the player's current animation frame
func outfit_animation():
	$Sprite/Outfit.frame = $Sprite.frame

# Checks all areas with health when doing the ultimate move, lower their health by 1 each frame,
# and reset their i-frames. Makes sure to not consider self as a target.
func check_ultimate_hitbox_enemies():
	var check_list = []
	for a in $UltimateHitboxArea.get_overlapping_areas():
		if a.get_parent() != self: check_list += [a]
	for area in check_list:
		if not area.get_parent().get("i_frames") == null:
			area.get_parent().set_i_frames(0)
		elif not area.get("i_frames") == null:
			area.set_i_frames(0)
		if not area.get_parent().get("health") == null:
			area.get_parent().health -= 1
		elif not area.get("health") == null:
			area.health -= 1

# Sets the variable jump_timer to n. Likely for bouncy objects to use.
func set_jump_timer(n):
	jump_timer = n

# Sets checkpoint info to Globals: the checkpoint number num, the position of the place to spawn
# from the checkpoint, and the collected coins obtained so far. Used by checkpoint objects.
func set_checkpoint(num, pos):
	Globals.checkpoint_data[0] = num
	Globals.checkpoint_data[1] = collected_coins[0]
	Globals.checkpoint_data[2] = collected_coins[1]
	Globals.checkpoint_data[3] = collected_coins[2]
	Globals.checkpoint_data[4] = pos
	print(Globals.checkpoint_data)

# Safely adds a vector to your current position, then slides to correct. Used for conveyors.
func add_position(add_pos):
	# warning-ignore:return_value_discarded
	position += add_pos
	move_and_slide(Vector2.ZERO, FLOOR_NORMAL if !is_upside_down else -FLOOR_NORMAL, true)
	#move_and_slide(add_pos, FLOOR_NORMAL, true)

# Activates player stun state, including the needed stun inputs.
func set_stun(stun_amount, type=0):
	stunned_shake_counter = stun_amount
	if type == 0:
		state = ST_STUNNED
	elif type == 1:
		state = ST_STUNNED_DRAG

# Sets the coyote timer variable (4)
func set_coyote_timer():
	coyote_timer = 4

# Return the tile type of the background tile the player is in front of.
func get_background_tiles():
	var tilemap = Globals.get_tilemap(2)
	var positions = [Vector2(-8, -72), Vector2(0,-72), Vector2(8,-72),
					Vector2(-8, -14), Vector2(0,-14), Vector2(8,-14)]
	var block_types = []
	for pos in positions:
		var block_pos = Vector2(nearest_block((position+pos).x)-24, nearest_block((position+pos).y)-24)/48
		block_types += [Globals.get_block_type(tilemap.get_cellv(block_pos), 2)]
	return block_types

# Return the floor type type.
func get_floor_tile_type():
	var tilemap = Globals.get_tilemap()
	var block_pos = Vector2(nearest_block(position.x)-24, nearest_block(position.y)-22)/48
	return Globals.get_block_type(tilemap.get_cellv(block_pos))

# Bounces player if object was struck with a down slash.
func _on_AttackHitboxArea_area_entered(area):
	if not (attacking_direction == 2 and state == ST_AIR_ATTACK) or area.get_collision_layer_bit(3)\
	or area.get_collision_layer_bit(0):
		return
	#print(area)
	_velocity.y = 800.0 * (-1 if !is_upside_down else 1)

# Corner correction juts you left/right when jumping into a corner (unused)
func corner_correction(pixel_amt):
	if _velocity.y >= 0: return
	if test_move(global_transform, Vector2(0, _velocity.y)):
		for i in range(1, pixel_amt+1):
			if !test_move(global_transform.translated(Vector2(i,0.0)), Vector2(0, _velocity.y)):
				translate(Vector2(i,0.0))
				_velocity.x = min(_velocity.x, 0)
				return
			elif !test_move(global_transform.translated(Vector2(-i,0.0)), Vector2(0, _velocity.y)):
				translate(Vector2(-i,0.0))
				_velocity.x = max(_velocity.x, 0)
				return

# Determine what counts as "attacking" to affect states in update_state
func did_attack():
	if current_attack != 1:
		return Input.is_action_just_pressed("attack")
	if Input.is_action_just_pressed("attack"):
		charge_shot_timer = 0
		return room_for_projectile() > -1
	if Input.is_action_pressed("attack"): return false
	if charge_shot_timer < 45:
		charge_shot_timer = 0
		return false
	return room_for_projectile() > -1

# Helper function to check if there is even room for a flameball to be made.
func room_for_projectile():
	var ammo_drop_amt = 4
	if current_attack == 1:
		ammo_drop_amt = 1 if charge_shot_timer < 45 else 8 if charge_shot_timer >= 120 else 4
	if ammo < ammo_drop_amt:
		charge_shot_timer = 0
		return -1
	
	var index_for_projectile = 0
	while index_for_projectile < 3:
		if list_of_projectiles[index_for_projectile] and is_instance_valid(list_of_projectiles[index_for_projectile])\
		and list_of_projectiles[index_for_projectile].get("active"):
			index_for_projectile += 1
		else:
			break
	if index_for_projectile >= 3:
		charge_shot_timer = 0
		return -1
	return index_for_projectile

# Creates a flameball object based on the length of the current attack charge.
# Returns true iff there is enough room for a projectile.
func shoot_flameball(charge_length):
	var index_for_projectile = room_for_projectile()
	var ammo_drop_amt = 1 if charge_length < 45 else 8 if charge_length >= 120 else 4
	
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
	spawn.player_attack_type = 1 if (charge_length < 45 and !dashing) else 3 if charge_length >= 120 else 2
	spawn.dash_flame = true if charge_length < 45 and dashing else false
	
	charge_shot_timer = 0
	list_of_projectiles[index_for_projectile] = spawn
	
	ammo -= ammo_drop_amt

# TODO: SHOOT OTHER TYPES OF PROJECTILES
func shoot_projectile():
	pass

# Function for CameraStopObjects, updates camera bounds based on all their limits
func camera_stop_object_update(camera_stop_obj=null, mode=0):
	if mode==2:
		camera_stop_object_list += [camera_stop_obj]
	elif mode==1:
		for i in range(camera_stop_object_list.size()):
			if camera_stop_object_list[i] == camera_stop_obj:
				camera_stop_object_list.remove(i)
				break
	$Camera2D.limit_top = camera_limits[0]
	$Camera2D.limit_bottom = camera_limits[1]
	$Camera2D.limit_left = camera_limits[2]
	$Camera2D.limit_right = camera_limits[3]
	for item in camera_stop_object_list:
		if item.is_persistent:
			if item.is_top_limit:
				$Camera2D.limit_top = max($Camera2D.limit_top, item.global_position.y)
			if item.is_bottom_limit:
				$Camera2D.limit_bottom = min($Camera2D.limit_bottom, item.global_position.y)
			if item.is_left_limit:
				$Camera2D.limit_left = max($Camera2D.limit_left, item.global_position.x)
			if item.is_right_limit:
				$Camera2D.limit_right = min($Camera2D.limit_right, item.global_position.x)
