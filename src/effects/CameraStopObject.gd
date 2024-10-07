extends Node2D

export var is_top_limit := false
export var is_bottom_limit := false
export var is_left_limit := false
export var is_right_limit := false
export var is_persistent := false

var player_default_limits
var player_camera

var last_global_position
var last_limits = []

func _ready() -> void:
	player_camera = Globals.find_player().find_node('Camera2D')
	player_default_limits = [player_camera.limit_top, player_camera.limit_bottom,
	player_camera.limit_left, player_camera.limit_right]
	if is_persistent: player_camera.get_parent().camera_stop_object_update(self, 2)
	last_global_position = global_position
	last_limits = [is_top_limit, is_bottom_limit, is_left_limit, is_right_limit]


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if last_global_position != global_position:
		player_camera.get_parent().camera_stop_object_update()
	elif [is_top_limit, is_bottom_limit, is_left_limit, is_right_limit] != last_limits:
		player_camera.get_parent().camera_stop_object_update()
	last_global_position = global_position
	last_limits = [is_top_limit, is_bottom_limit, is_left_limit, is_right_limit]

func stop_update():
	is_persistent = false
	player_camera.get_parent().camera_stop_object_update(self, 1)

func start_update():
	is_persistent = true
	player_camera.get_parent().camera_stop_object_update(self, 2)
