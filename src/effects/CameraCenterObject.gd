extends Area2D

var enabled := false
var exiting := false
var exiting_timer := 0
export var vertical_lock = false
export var horizontal_lock = false

export var limit_top = -1000000
export var limit_bottom = 1000000
export var limit_left = -1000000
export var limit_right = 1000000

# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera2D.limit_left = limit_left
	$Camera2D.limit_right = limit_right
	$Camera2D.limit_top = limit_top
	$Camera2D.limit_bottom = limit_bottom


func _process(_delta):
	if Globals.find_player().health <= 0: return
	if not enabled:
		$Camera2D.position = Vector2.ZERO
		exiting = false
		return
	if exiting:
		Globals.eq_timer = 0
		exiting_timer += 1
		if (abs($Camera2D.get_camera_screen_center().x - Globals.find_player().find_node("Camera2D").get_camera_screen_center().x) <= 16 and
			abs($Camera2D.get_camera_screen_center().y - Globals.find_player().find_node("Camera2D").get_camera_screen_center().y) <= 
				(32 if exiting_timer > 30 else 16)):
				Globals.find_player().find_node("Camera2D").current = true
				$Camera2D.current = false
				$Camera2D.position = Vector2.ZERO
				exiting = false
				exiting_timer = 0
				enabled = false
				return
		Globals.find_player().find_node("Camera2D").current = true
		if horizontal_lock:
			$Camera2D.global_position.x += 12*(Globals.find_player().find_node("Camera2D").get_camera_position()-
				$Camera2D.global_position).normalized().x
			$Camera2D.global_position.y = Globals.find_player().find_node("Camera2D").get_camera_position().y
		if vertical_lock:
			var chase_camera_y = 30 if exiting_timer > 30 else 12
			$Camera2D.global_position.y += chase_camera_y*(
				Globals.find_player().find_node("Camera2D").get_camera_position()-$Camera2D.global_position).normalized().y
			$Camera2D.global_position.x = Globals.find_player().find_node("Camera2D").get_camera_position().x
		$Camera2D.current = true
		return
	exiting_timer = 0
	if vertical_lock and horizontal_lock:
		if $Camera2D.position == Vector2.ZERO: return
		Globals.eq_timer = 0
		if $Camera2D.position.length_squared() <= 68:
			$Camera2D.position = Vector2.ZERO
			return
		$Camera2D.position += 8*(-$Camera2D.position).normalized()
	
	elif horizontal_lock:
		var old_cam = Globals.get_current_camera()
		Globals.find_player().find_node("Camera2D").current = true
		$Camera2D.global_position.y = Globals.find_player().find_node("Camera2D").get_camera_position().y
		old_cam.current = true
		if $Camera2D.position.x != 0:
			$Camera2D.current = true
			Globals.eq_timer = 0
			var posx = $Camera2D.position.x
			if abs(posx) <= 10:
				$Camera2D.position.x = 0
				return
			$Camera2D.position.x += 8*-posx/abs(posx)
	
	elif vertical_lock:
		var old_cam = Globals.get_current_camera()
		Globals.find_player().find_node("Camera2D").current = true
		$Camera2D.global_position.x = Globals.find_player().find_node("Camera2D").get_camera_position().x
		old_cam.current = true
		if $Camera2D.position.y != 0:
			$Camera2D.current = true
			Globals.eq_timer = 0
			var posy = $Camera2D.position.y
			if abs(posy) <= 10:
				$Camera2D.position.y = 0
				return
			$Camera2D.position.y += 8*-posy/abs(posy)


func _on_CameraCenterObject_area_entered(area):
	if not area.get_collision_layer_bit(1): return
	if exiting:
		exiting = false
		return
	$Camera2D.global_position = Globals.get_current_camera_pos()
	Globals.find_player().find_node("Camera2D").current = false
	$Camera2D.current=true
	enabled = true
	Globals.eq_timer = 0


func _on_CameraCenterObject_area_exited(area):
	if not area.get_collision_layer_bit(1): return
	exiting = true
