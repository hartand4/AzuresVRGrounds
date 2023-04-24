extends Actor


# Timers
var jump_timer := 0
var stop_wallslide_timer := 0
var walljump_momentum_timer := 0
var i_frames := 0
var dash_timer := 0

# Booleans
export var dashing := false
export var air_dash_enabled := true
var started_dash_on_floor := false
var attacking := false
export var colliding_with_enemy := false
var colliding_with_wall_l := false
var colliding_with_wall_r := false
var colliding_with_ladder := false
var colliding_with_ladder_top := false
var near_wall := [false, false]
var shot_active := false
export var collected_coins := [false, false, false]

# Hitboxes
onready var hitbox_collider = $PlayerHitboxArea/PlayerHitbox
onready var hitbox := $PlayerHitboxArea
onready var wjboxl := $WalljumpAreaL
onready var wjboxr := $WalljumpAreaR
onready var attack_collision := $AttackHitboxArea
onready var attack_particle := attack_collision.find_node('AttackParticles')

# Other variables
onready var normal_hitbox_shape = hitbox_collider.shape.extents
onready var normal_hitbox_transform = [hitbox_collider.get_position(), $PlayerHitbox.get_position()]
onready var normal_wallcheck_shape = $WalljumpAreaL/WalljumpBoxL.shape.extents
onready var normal_wallcheck_transform = [$WalljumpAreaL/WalljumpBoxL.get_position(), $WalljumpAreaR/WalljumpBoxR.get_position()]

#var double_jumped := false
export var health := 32
#export var game_paused := false
var floor_angle := PI/2
var last_state := 0
var shot_damage := 5
var shot_velocity := Vector2.ZERO
var max_slope := PI/3

var animation_dict := {ST_IDLE: 'Idle', ST_WALK: 'Run', ST_WALLSLIDE: 'Wallslide', ST_WALLJUMP: 'Walljump',
					   ST_DASH: 'Dash'}

# From enemy
var damage_doing := 0

func _ready():
	recurring_x_dir = 1

# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	var is_jumping := false
	
	if Globals.get("game_paused"):
		if Input.is_action_just_pressed("pause") and not Globals.lock_input:
			Globals.set("game_paused", false)
		do_pause_menu()
		return
	elif Input.is_action_just_pressed("pause") and not Globals.lock_input:
		Globals.set("game_paused", true)
		do_pause_menu()
		return
		
	if state in [0,1,3,5]:
		if jump_timer > 0:
			jump_timer -= 1
		elif is_on_floor():
			jump_timer = 0
			if Input.is_action_just_pressed("jump"):
				jump_timer = 15
		is_jumping = Input.is_action_pressed("jump") and jump_timer > 0 and _velocity.y < 0
			
		if walljump_momentum_timer == 0:
			# Get direction of input
			direction = get_direction_normal()
			if direction.x != 0.0:
				recurring_x_dir = direction.x
		
		# Check double jump
		#if is_on_floor():
		#	double_jumped = false
		#elif Input.is_action_just_pressed("jump") and not double_jumped:
		#	double_jumped = true
			
	elif state == ST_HURT:
		direction.x = recurring_x_dir * -0.5
		
	elif state == ST_DASH:
		if jump_timer > 0:
			jump_timer -= 1
		elif Input.is_action_just_pressed("jump"):
			jump_timer = 15
		is_jumping = Input.is_action_pressed("jump") and jump_timer > 0 and _velocity.y < 0
		direction = get_direction_normal()
		direction.x = recurring_x_dir
		
	# If still in walljumping state
	if walljump_momentum_timer:
		direction = Vector2(recurring_x_dir*(-2),0)
	
	# Update position
	var snap := 15*Vector2.DOWN if not is_jumping else Vector2.ZERO
	_velocity = calculate_move_direction(_velocity, speed, direction, is_jumping)
	
	if state == ST_WALLSLIDE:
		_velocity.y = min(_velocity.y, 250.0)
	elif state == ST_WALLJUMP:
		_velocity = Vector2.ZERO
	elif state == ST_CLIMB:
		_velocity = Vector2.ZERO
		if Input.is_action_pressed("move_up"):
			self.position.y -= 4
		elif Input.is_action_pressed("move_down"):
			self.position.y += 4
		return
	elif state == ST_DASH:
		if not is_on_floor() and air_dash_enabled:
			_velocity.y = 0
	
	if dashing and state != ST_HURT: _velocity.x *= 1.8
		
	# Check for slopes
	if is_on_floor():
		var factor = abs(sin(floor_angle))
		if cos(floor_angle)*recurring_x_dir > 0 and factor != 0: factor=1/factor
		_velocity.x *= factor
		
	_velocity = move_and_slide_with_snap(_velocity, snap, FLOOR_NORMAL, true)
	

func get_direction_normal() -> Vector2:
	if Globals.lock_input: return Vector2.DOWN
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if Input.is_action_just_pressed("jump") and (is_on_floor()) else 1.0 #or not double_jumped) else 1.0
	)

func calculate_move_direction(linear_velocity: Vector2, speed: Vector2, direction: Vector2, is_jumping: bool) -> Vector2:
	var out_vel := linear_velocity
	out_vel.x = speed.x * direction.x
	out_vel.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		out_vel.y = 700.0 * direction.y - linear_velocity.y
		
		# Account for slope jump boost
		if out_vel.x != 0:
			var factor = abs(sin(floor_angle))
			if cos(floor_angle)*recurring_x_dir > 0 and factor != 0: factor=1/factor
			out_vel.y *= (factor+2)/3
	if is_jumping:
		out_vel.y -= 0.6 * pow(jump_timer,2) #First few frames matter more
	return out_vel

# warning-ignore:unused_argument
func _process(delta):
	if state != ST_ATTACK and state != ST_AIR_ATTACK:
		do_punch_effect(false)
		
	if Globals.get("game_paused"): return
		
	if i_frames:
		i_frames -= 1
	if health < 0:
		health = 0
	if stop_wallslide_timer:
		stop_wallslide_timer -= 1
	if walljump_momentum_timer:
		walljump_momentum_timer -= 1
	if dash_timer:
		dash_timer -= 1
	elif is_on_floor():
		dashing = false
		
	check_for_collisions()
	
	if last_state != state:
		print(state)
		last_state = state
	
	
func animation_handler():
	$Sprite.visible = true
	$Sprite.flip_h = recurring_x_dir + 1
	
	if i_frames and Globals.timer % 8 <= 1:
		$Sprite.visible = false
	
	if health > 0: change_dash_hitbox(state == ST_DASH)
	
	if state in animation_dict:
		_animation.play(animation_dict[state])
		return
	match state:
		ST_AIR:
			if _velocity.y < 0:
				_animation.play('Jump')
			else:
				_animation.play('Fall')
		ST_ATTACK:
			_animation.play('Punch')
			if animation_timer == 5:
				do_punch_effect(true)
		ST_AIR_ATTACK:
			_animation.play('Kick')
			if animation_timer == 5:
				do_punch_effect(true)
	
func update_state():
	var dir = Vector2(
		-1.0 if Input.is_action_pressed("move_left") else 1.0 if Input.is_action_pressed("move_right") else 0.0,
		1.0 if Input.is_action_pressed("move_down") else -1.0 if Input.is_action_pressed("move_up") else 0.0)
	
	# GETTING HURT
	if state == ST_HURT:
		if animation_timer < 20 or health == 0: return ST_HURT
		state = 0
		return update_state()
	# Consider other states, like wallslide taking damage
	if not (state in [ST_HURT, ST_INTERACT]) and colliding_with_enemy and i_frames == 0:
		i_frames = 60
		do_hurt_animation(damage_doing)
		return ST_HURT
		
	# DOING AN AIR ATTACK
	if state == ST_AIR and Input.is_action_just_pressed("attack"): return ST_AIR_ATTACK
	if state == ST_AIR_ATTACK and animation_timer >= 25: return ST_AIR
	
	# SLIDING ON A WALL
	if state == ST_AIR and is_on_wall() and _velocity.y > 0:
		if (colliding_with_wall_l and dir.x < 0) or (colliding_with_wall_r and dir.x > 0):
			stop_wallslide_timer = 8
			recurring_x_dir = 1 if dir.x < 0 else -1
			dash_timer = 0
			dashing = false
			_velocity.y = -100.0
			return ST_WALLSLIDE
		
	# CONTINUE SLIDING ON WALL, OR WALLJUMP WHILE SLIDING
	if state == ST_WALLSLIDE:
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
			
	# ANOTHER WAY TO WALLJUMP
	if state == ST_AIR and Input.is_action_just_pressed('jump') and (colliding_with_wall_l or colliding_with_wall_r):
		recurring_x_dir = -1 if colliding_with_wall_l else 1
		return start_walljump()
			
	# WALLJUMP LAG
	if state == ST_WALLJUMP and stop_wallslide_timer == 0:
		walljump_momentum_timer = 4
		_velocity.y = -700
		jump_timer = 15
		return ST_AIR
	
	# FLOOR DASHING OR AIR DASHING
	if ((state == ST_AIR and air_dash_enabled) or state < 2) and Input.is_action_just_pressed("dash"):
		if not(near_wall[int((recurring_x_dir+1)/2)]) and not dashing:
			dashing = true
			dash_timer = 40 if is_on_floor() else 20
			started_dash_on_floor = is_on_floor()
			return ST_DASH
	
	# WHILE FLOOR DASHING OR AIR DASHING
	if state == ST_DASH:
		if near_wall[int((recurring_x_dir+1)/2)] or dir.x == -recurring_x_dir or (
			not Input.is_action_pressed('dash') or dash_timer == 0) or (
				started_dash_on_floor and not is_on_floor()
			):
			state = ST_AIR
			dash_timer = 0
			return update_state()
	
	# ATTACKING
	if state < 3 and Input.is_action_just_pressed("attack"): return ST_ATTACK
	
	#STOP ATTACK
	if state == ST_ATTACK and animation_timer >= 25:
		state = 0
		return update_state()
	
	#CLIMB LADDER
	if (state < 6 and colliding_with_ladder and dir.y < 0) or (
		state < 3 and colliding_with_ladder and dir.y != 0):
		dashing = false
		self.position.x = nearest_block(self.position.x)
		return ST_CLIMB
		
	if state < 3 and colliding_with_ladder_top and dir.y > 0:
		self.position = Vector2(nearest_block(self.position.x), self.position.y+48)
		return ST_CLIMB
		
	if state == ST_CLIMB:
		if not(colliding_with_ladder or colliding_with_ladder_top) or Input.is_action_just_pressed('jump'):
			state = ST_AIR
		if colliding_with_ladder_top and not colliding_with_ladder and dir.y < 0:
			state = ST_IDLE
			self.position.y = nearest_block(self.position.y)-24
	
	### if interaction finished: return ST_IDLE
	
	# BEGIN ON FLOOR
	if (state == 3 or state == 5) and is_on_floor():
		state = 0
		return update_state()
		
	# IF JUMPED OR FELL OR AIR ATTACK ENDED
	if state < 3 and Input.is_action_just_pressed("jump"): 
		if is_on_floor() or state < 2:
			dashing = Input.is_action_pressed("dash")
			return ST_AIR
	elif state in [0,1,4] and not is_on_floor(): return ST_AIR
	
	#if state < 2 and Input.is_action_just_pressed("interact") and interactable thing: return ST_INTERACT
	elif state < 2 and dir.x != 0: return ST_WALK
	elif state < 2 and dir.x == 0: return ST_IDLE
	return state
	
func start_walljump():
	stop_wallslide_timer = 6
	if not Input.is_action_pressed('dash'):
		dash_timer = 0
		dashing = false
	else: dashing = true
	return ST_WALLJUMP

func do_pause_menu(): #TODO
	return

func do_punch_effect(start):
	if not start:
		attack_particle.visible = false
		attack_collision.find_node('AttackHitbox').disabled = true
		return
	attack_particle.visible = true
	attack_particle.set_position(Vector2(recurring_x_dir * 6.0,-48.0))
	attack_particle.find_node('AttackPlayer').play('Hit Particle')
	
	attack_collision.set_position(Vector2(recurring_x_dir * 48.0,0))
	attack_collision.find_node('AttackHitbox').disabled = false
	
func do_hurt_animation(damage):
	health -= damage
	_animation.play("Hurt")
	_velocity = Vector2(recurring_x_dir * -500.0,-500)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
	if health <= 0:
		$Camera2D.current = false
		$PlayerHitbox.disabled = true
		$PlayerHitboxArea/PlayerHitbox.disabled = true
		$PlayerDashHitbox.disabled = true
		colliding_with_enemy = false
		Globals.lock_input = true
	return
	
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
		return
	hitbox_collider.shape.extents = normal_hitbox_shape
	hitbox_collider.set_position(normal_hitbox_transform[0])
	#$PlayerHitbox.set_position(normal_hitbox_transform[1])
	$PlayerHitbox.disabled = false
	$PlayerDashHitbox.disabled = true
	$WalljumpAreaL/WalljumpBoxL.shape.extents = normal_wallcheck_shape
	$WalljumpAreaL/WalljumpBoxL.set_position(normal_wallcheck_transform[0])
	$WalljumpAreaR/WalljumpBoxR.set_position(normal_wallcheck_transform[1])
	
func check_for_collisions():
	# Record floor normal angle if on floor
	if is_on_floor() and get_slide_count() > 0:
		floor_angle = -get_slide_collision(0).normal.angle()
		if abs(cos(floor_angle)) > cos(PI/2-max_slope):
			floor_angle = PI/2
	
	# Check for crush death
	for box in hitbox.get_overlapping_bodies():
		if (box.get_collision_layer_bit(0) or box.get_collision_layer_bit(6)) and near_wall[0] and (
			near_wall[1] and not box.get_collision_layer_bit(8)):
			colliding_with_enemy = true
			damage_doing = 32

func _on_PlayerHitboxArea_area_entered(area: Area2D) -> void:
	# Check if the player is colliding with other areas (enemies or damage tiles)
	if (area.get_collision_layer_bit(2) or area.get_collision_layer_bit(7)) and not colliding_with_enemy:
		colliding_with_enemy = true
		# If an enemy...
		if area.get_collision_layer_bit(2):
			damage_doing = area.get_parent().damage
		# Otherwise must be a stage hazard
		elif area.get_collision_layer_bit(7):
			damage_doing = area.damage
	elif area.get_collision_layer_bit(8):
		colliding_with_ladder = true
# warning-ignore:unused_argument
func _on_PlayerHitboxArea_area_exited(area: Area2D) -> void:
	colliding_with_enemy = false
	colliding_with_ladder = false
	for box in hitbox.get_overlapping_areas():
		if (box.get_collision_layer_bit(2) or box.get_collision_layer_bit(7)) and not colliding_with_enemy:
			colliding_with_enemy = true
			# If an enemy...
			if box.get_collision_layer_bit(2):
				damage_doing = box.get_parent().damage
			# Otherwise must be a stage hazard
			else:
				damage_doing = box.damage
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
# warning-ignore:unused_argument
func _on_WalljumpAreaL_body_exited(body: Node) -> void:
	colliding_with_wall_l = false
	near_wall[0] = false
	for box in wjboxl.get_overlapping_bodies():
		if box.get_collision_layer_bit(0):
			colliding_with_wall_l = true
			near_wall[0] = true
		elif box.get_collision_layer_bit(6):
			near_wall[0] = true
# warning-ignore:unused_argument
func _on_WalljumpAreaR_body_exited(body: Node) -> void:
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
# warning-ignore:unused_argument
func _on_LadderTopArea_body_exited(body: Node) -> void:
	colliding_with_ladder_top = false
	for box in $LadderTopArea.get_overlapping_bodies():
		if box.get_collision_layer_bit(8):
			colliding_with_ladder_top = true
