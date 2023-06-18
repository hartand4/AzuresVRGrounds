extends StaticBody2D


var anim_timer := 0
var bouncing := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bouncing = false


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	
	for area in $TopCheck.get_overlapping_areas():
		if area.get_collision_layer_bit(1) or area.get_collision_layer_bit(2) or area.get_collision_layer_bit(3):
			do_bounce_up(area)
	for area in $BottomCheck.get_overlapping_areas():
		if area.get_collision_layer_bit(1) or area.get_collision_layer_bit(2) or area.get_collision_layer_bit(3):
			do_bounce_down(area)
	
	if bouncing:
		anim_timer -= 1
		if not anim_timer:
			bouncing = false
			return
		$AnimationPlayer.play("Boing")
		return
	
	$AnimationPlayer.play("Idle")
	


func do_bounce_up(area):
	var curr_vel = Vector2.ZERO
	if area.get_collision_layer_bit(1):
		area.get_parent().set_jump_timer(0)
		area.get_parent().dashing = Input.is_action_pressed("dash")
		curr_vel = area.get_parent().get_velocity()
		area.get_parent().set_velocity(Vector2(curr_vel.x, start_bounce()*(1.6 if Input.is_action_pressed("jump") else 1)))
	elif area.has_method("set_velocity") and area.has_method("get_velocity"):
		curr_vel = area.get_velocity()
		area.set_velocity(Vector2(curr_vel.x, start_bounce()))
	elif area.get_parent().has_method("set_velocity") and area.get_parent().has_method("get_velocity"):
		curr_vel = area.get_parent().get_velocity()
		area.get_parent().set_velocity(Vector2(curr_vel.x, start_bounce()))

func start_bounce():
	bouncing = true
	anim_timer = 23
	return -1000

func do_bounce_down(area):
	var curr_vel = Vector2.ZERO
	if area.get_collision_layer_bit(1):
		curr_vel = area.get_parent().get_velocity()
		area.get_parent().set_velocity(Vector2(curr_vel.x, -start_bounce()*(1.5 if Input.is_action_pressed("jump") else 1.0)))
	elif area.has_method("set_velocity") and area.has_method("get_velocity"):
		curr_vel = area.get_velocity()
		area.set_velocity(Vector2(curr_vel.x, -start_bounce()))
	elif area.get_parent().has_method("set_velocity") and area.get_parent().has_method("get_velocity"):
		curr_vel = area.get_parent().get_velocity()
		area.get_parent().set_velocity(Vector2(curr_vel.x, -start_bounce()))
