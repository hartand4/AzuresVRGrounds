extends StaticBody2D

var _anim_timer := 0
var used := false

var going_through = false
var going_through_timer = 300

export var y_limits = [-2000,600]
export var gate_to_the_right = true
var player

export var center_height = 0
export var player_camera_after = true

export var use_new_limits = [false, false, false, false]
export var new_camera_limits = [0,0,0,0]

var player_previous_state = 0
export var destroy_enemies = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.checkpoint_data[0] > 0 and (Globals.checkpoint_data[4].x >= position.x == gate_to_the_right):
		used = true
	if gate_to_the_right:
		$PlayerCheckArea/CollisionRight.disabled = true
	else:
		$PlayerCheckArea/CollisionLeft.disabled = true
	if gate_to_the_right == used:
		$CameraStopObject.is_left_limit = true
	else:
		$CameraStopObject.is_right_limit = true
	#$TopBorder.position.y = center_height - 648
	#$BottomBorder.position.y = center_height + 648
	
	$Collision.position.x = 24 if gate_to_the_right else -24


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if !player:
		player = Globals.find_player()
	if player.position.y - position.y < y_limits[0] or player.position.y - position.y > y_limits[1]:
		if $CameraStopObject.is_persistent: $CameraStopObject.stop_update()
	else:
		if !$CameraStopObject.is_persistent: $CameraStopObject.start_update()
	if used: return
	if going_through:
		animation_doing()
		going_through_timer -= 1
		if going_through_timer == 0:
			Globals.lock_input = false
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
	if (player.position.y > position.y + 74 or player.position.y < position.y + 10)\
		and !player.is_upside_down: return
	elif (player.position.y < position.y - 74 or player.position.y > position.y - 10)\
		and player.is_upside_down: return
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
		$Camera.position.y += 4 if $Camera.position.y < center_height else\
			-4 if $Camera.position.y > center_height else 0
		if abs($Camera.position.y - center_height) < 4:
			$Camera.position.y  = center_height
		
	elif going_through_timer <= start_time - 84 and going_through_timer > 85:
		player.position.x += 1.2 if gate_to_the_right else -1.2
		
		player.get_node("AnimationPlayer").playback_speed = 1
		if player_previous_state == 1:
			player.get_node("AnimationPlayer").play("Run")
			player.get_node("Tail/TailAnimation").playback_speed = 1
		
		$Camera.position.x += (1 if gate_to_the_right else -1)*8
		
		if (gate_to_the_right and $Camera.position.x == 432) or (
			!gate_to_the_right and $Camera.position.x == -432):
			going_through_timer = 86
			
			$CameraStopObject.is_left_limit = true if gate_to_the_right else false
			$CameraStopObject.is_right_limit = false if gate_to_the_right else true
			$CameraStopObject.start_update()
		
	elif going_through_timer == 85:
		Globals.game_paused = false
		Globals.lock_input = true
		player.state = 3
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
		$Camera.position.y += 32 if $Camera.get_camera_position().y < player_cam.get_camera_screen_center().y else\
			-32 if $Camera.get_camera_position().y > player_cam.get_camera_screen_center().y else 0
		$Camera.current = true
		if abs($Camera.get_camera_position().y - player_cam.get_camera_screen_center().y) < 32:
			player_cam.current = true
