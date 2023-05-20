extends Node2D

export var is_top_limit := false
export var is_bottom_limit := false
export var is_left_limit := false
export var is_right_limit := false
export var is_persistent := false

func _ready() -> void:
	camera_update()


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if is_persistent: camera_update()

func camera_update():
	var player_camera = Globals.find_player().find_node('Camera2D')
	if is_top_limit: player_camera.limit_top = position.y
	if is_bottom_limit: player_camera.limit_bottom = position.y
	if is_left_limit: player_camera.limit_left = position.x
	if is_right_limit: player_camera.limit_right = position.x
