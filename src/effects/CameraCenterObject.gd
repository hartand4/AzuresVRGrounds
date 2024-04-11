extends Area2D

var exiting = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(_delta):
	if not $Camera2D.current:
		$Camera2D.position = Vector2.ZERO
		exiting = false
		return
	if exiting:
		if (abs($Camera2D.get_camera_screen_center().x - Globals.find_player().find_node("Camera2D").get_camera_screen_center().x) <= 18 and
			abs($Camera2D.get_camera_screen_center().y - Globals.find_player().find_node("Camera2D").get_camera_screen_center().y) <= 32):
				Globals.find_player().find_node("Camera2D").current = true
				$Camera2D.current = false
				$Camera2D.position = Vector2.ZERO
				exiting = false
				return
		Globals.find_player().find_node("Camera2D").current = true
		$Camera2D.global_position.x += 15*(Globals.find_player().find_node("Camera2D").get_camera_position()-
			$Camera2D.global_position).normalized().x
		$Camera2D.global_position.y += 30*(Globals.find_player().find_node("Camera2D").get_camera_position()-
			$Camera2D.global_position).normalized().y
		$Camera2D.current = true
	
	elif $Camera2D.position != Vector2.ZERO:
		if $Camera2D.position.length_squared() <= 68:
			$Camera2D.position = Vector2.ZERO
			return
		$Camera2D.position += 8*(-$Camera2D.position).normalized()


func _on_CameraCenterObject_area_entered(area):
	if not area.get_collision_layer_bit(1): return
	if exiting:
		exiting = false
		return
	$Camera2D.global_position = Globals.get_current_camera_pos()
	Globals.find_player().find_node("Camera2D").current = false
	$Camera2D.current=true


func _on_CameraCenterObject_area_exited(area):
	if not area.get_collision_layer_bit(1): return
	exiting = true
