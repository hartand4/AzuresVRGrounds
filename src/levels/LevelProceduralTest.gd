extends Node2D


onready var camera = Globals.find_player().find_node('Camera2D')
var camera_prev_place := 0
var last_layout := -2


# Called when the node enters the scene tree for the first time.
func _ready():
	camera.limit_bottom = 1140
	camera.limit_top = 540


func _process(_delta):
	camera.limit_left = Globals.get_current_camera_pos().x - 420
	$ScrollLimiter.position = Globals.get_current_camera_pos()
	
	# warning-ignore:integer_division
	var cam_current_place = int(Globals.get_current_camera_pos().x - 400) / 864
	if cam_current_place > camera_prev_place:
		camera_prev_place = cam_current_place
		generate_layout()
	if Globals.game_paused:
		print(Globals.random_permutation(7))

func generate_layout():
	var GENERATION_LIMIT = 7
	if camera_prev_place > GENERATION_LIMIT:
		camera.limit_right = 18*48*(camera_prev_place+1)
		return
	var layout_number = last_layout
	var trials = 5
	
	while layout_number == last_layout and trials > 0:
		layout_number = Globals.call_rng(0,2) if camera_prev_place < GENERATION_LIMIT else -1
		trials -= 1
	
	last_layout = layout_number
	
	for i in range(18):
		for j in range(13):
			var tile_to_add = $TileMap.get_cellv(Vector2(18*layout_number + i, j + 30))
			$TileMap.set_cellv(Vector2((camera_prev_place + 1)*18 + i,j+11), tile_to_add)
	
	var objects_to_add = []
	
	for object in self.get_children():
		if object.get('position') and (
			object.position.x >= 48*18*layout_number and object.position.x <= 48*18*(layout_number + 1)) and (
			object.position.y >= 48*30 and object.position.y <= 48*43):
			var new_obj = object.duplicate()
			new_obj.position = Vector2( 18*48*(camera_prev_place + 1) + mod_wrap(int(object.position.x) , (48*18)),
				48*11 + mod_wrap(int(object.position.y - 48*30) , (48*13)))
			objects_to_add += [new_obj]
	
	for new_obj in objects_to_add:
		self.add_child(new_obj)

func mod_wrap(input_num, mod_amt):
	if input_num > 0: return input_num % mod_amt
	return mod_wrap(input_num + mod_amt, mod_amt)
