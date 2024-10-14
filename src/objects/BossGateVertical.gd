extends StaticBody2D

var _anim_timer := 0
var used := false

var going_through = false
var going_through_timer = 300

export var x_limits = [-600,600]
export var gate_to_the_bottom = true
var player

export var center_x = 0
export var player_camera_after = true

export var use_new_limits = [false, false, false, false]
export var new_camera_limits = [0,0,0,0]

var player_previous_state = 0
export var destroy_enemies = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.checkpoint_data[0] > 0 and (Globals.checkpoint_data[4].y >= position.y == gate_to_the_bottom):
		used = true
	if gate_to_the_bottom:
		$PlayerCheckArea/CollisionBottom.disabled = true
	else:
		$PlayerCheckArea/CollisionTop.disabled = true
	if gate_to_the_bottom == used:
		$CameraStopObject.is_top_limit = true
	else:
		$CameraStopObject.is_bottom_limit = true
	
	$Collision.position.y = 24 if gate_to_the_bottom else -24


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if !player:
		player = Globals.find_player()
	if player.position.x - position.x < x_limits[0] or player.position.x - position.x > x_limits[1]:
		if $CameraStopObject.is_persistent: $CameraStopObject.stop_update()
	else:
		if !$CameraStopObject.is_persistent: $CameraStopObject.start_update()
	if used: return
	if going_through:
		animation_doing()
		going_through_timer -= 1
		if going_through_timer == 0:
			Globals.lock_input = false
			Globals.game_paused = false
			player.find_node("PlayerHitboxArea").find_node("PlayerHitbox").disabled = false
			player.state = 3
			used = true
			going_through = false
			
			if player_camera_after:
				player.find_node("Camera2D").current = true
			
		return
	if Globals.game_paused: return
	check_for_player()

func check_for_player():
	var player_overlapping = false
	for body in $PlayerCheckArea.get_overlapping_bodies():
		if body.get_collision_layer_bit(1):
			player_overlapping = true
			break
	if !player_overlapping: return
	if (player.position.x > position.x + 90 or player.position.x < position.x - 90): return
	going_through = true
	Globals.game_paused = true
	player.find_node("PlayerHitboxArea").find_node("PlayerHitbox").disabled = true
	player_previous_state = player.state
	player.state = 7
	player._velocity.y = 0
	
	$Camera.global_position = Globals.get_current_camera_pos()
	var curr_cam = Globals.get_current_camera()
	if curr_cam.get_parent().get("enabled"):
		curr_cam.get_parent().enabled = false
	curr_cam.current = false
	$Camera.current=true
	Globals.eq_timer = 0
	Globals.prevent_enemy_spawn = destroy_enemies

func animation_doing():
	var start_time = 299
	if going_through_timer == start_time:
		$AnimationPlayer.play("Open")
		
		$CameraStopObject.stop_update()
		
	elif going_through_timer > start_time - 84:
		$Camera.position.x += 4 if $Camera.position.x < center_x else\
			-4 if $Camera.position.x > center_x else 0
		if abs($Camera.position.x - center_x) < 4:
			$Camera.position.x  = center_x
		
	elif going_through_timer <= start_time - 84 and going_through_timer > 85:
		player.position.y += 2.3*(1.0 if gate_to_the_bottom else -1.0)
		
		player.get_node("Tail/TailAnimation").playback_speed = 1
		
		$Camera.position.y += (1 if gate_to_the_bottom else -1)*8
		
		if (gate_to_the_bottom and $Camera.position.y == 312) or (
			!gate_to_the_bottom and $Camera.position.y == -312):
			going_through_timer = 86
			
			$CameraStopObject.is_top_limit = true if gate_to_the_bottom else false
			$CameraStopObject.is_bottom_limit = false if gate_to_the_bottom else true
			$CameraStopObject.start_update()
		
	elif going_through_timer == 85:
		$AnimationPlayer.play("Close")
		
		var player_cam = player.find_node("Camera2D")
		if use_new_limits[0]:
			player_cam.limit_top = new_camera_limits[0]
		if use_new_limits[1]:
			player_cam.limit_bottom = new_camera_limits[1]
		if use_new_limits[2]:
			player_cam.limit_left = new_camera_limits[2]
		if use_new_limits[3]:
			player_cam.limit_right = new_camera_limits[3]
		
		
	elif going_through_timer < 85 and player_camera_after:
		var player_cam = player.find_node("Camera2D")
		player_cam.current = true
		$Camera.position.y += 22 if $Camera.get_camera_position().y < player_cam.get_camera_screen_center().y - 22 else\
			-22 if $Camera.get_camera_position().y > player_cam.get_camera_screen_center().y + 22 else 0
		$Camera.position.x += 22 if $Camera.get_camera_position().x < player_cam.get_camera_screen_center().y - 22 else\
			-22 if $Camera.get_camera_position().y > player_cam.get_camera_screen_center().y + 22 else 0
		$Camera.current = true
		if (abs($Camera.get_camera_screen_center().x - player_cam.get_camera_screen_center().x) <= 22 and
			abs($Camera.get_camera_screen_center().y - player_cam.get_camera_screen_center().y) <= 22):
			player_cam.current = true
