extends Node2D

# This is mainly used to store lookup tables about map tiles, and triggering map events.
var anim_timer := 0
var anim_frame := 0

var current_event_trigger := 0
var event_number := 0

var done_initial_setup := false
var doing_map_events := false

const FRAME_DELAY := 15

# Lists where each warp will go. Each formatted as [true iff target is a warp else false, level/warp number]
export var warp_info_list = [
	[], [true, 2], [true, 1]
	]

onready var tilemaps = [
	$MapTileset/MapBottomLayer, $MapTileset/MapMidLayer, $MapTileset/MapTopLayer, $MapTileset/MapMaskLayerBottom,
	$MapTileset/MapMaskLayer
	]

onready var path_tilemaps = [
	$"Paths/Non-Curved Unlocked", $Paths/OneoverX/TileMap, $Paths/MinusOneOverX/TileMap,
	$Paths/Ladders/TileMap, $Paths/Locked
	]

# Lists every map event based on the exit recently completed
# Index of events are (level number)*2 + (1 if secret exit else 0)
var map_events = [
	[[0,0,Vector2(4,4), [2,1]]], [[0,1,Vector2(7,6), [2,1]]],
	
	# Level 1 Normal Exit
	[ [0,1,Vector2(9,9), [4,-1]], [0,3,0,[0,1,2]], [0,3,0,[0,2,3]], [1,1,Vector2(8,9), [4,-1]],
	[2,1,Vector2(7,9), [4,-1]], [3,1,Vector2(6,9), [4,-1]],
	[4, 2,0,{"type":"level", "number": 2, "unlocked":true}]                             ],
	# Level 1 Secret Exit
	[],
	# Level 2 Normal Exit
	[],
	# Level 2 Secret Exit
	[],
	# Level 3 Normal Exit
	[],
	# Level 3 Secret Exit
	[],
	# Level 4 Normal Exit
	[],
	# Level 4 Secret Exit
	[],
	# Level 5 Normal Exit
	[],
	# Level 5 Secret Exit
	[],
	# Level 6 Normal Exit
	[],
	# Level 6 Secret Exit
	[],
	# Level 7 Normal Exit
	[],
	# Level 7 Secret Exit
	[],
	# Level 8 Normal Exit
	[],
	# Level 8 Secret Exit
	[],
	# Level 9 Normal Exit
	[],
	# Level 9 Secret Exit
	[],
	# Level 10 Normal Exit
	[],
	# Level 10 Secret Exit
	[],
	# Level 11 Normal Exit
	[],
	# Level 11 Secret Exit
	[],
	# Level 12 Normal Exit
	[],
	# Level 12 Secret Exit
	[],
	# Level 13 Normal Exit
	[],
	# Level 13 Secret Exit
	[],
	# Level 14 Normal Exit
	[],
	# Level 14 Secret Exit
	[],
	# Level 15 Normal Exit
	[],
	# Level 15 Secret Exit
	[],
	# Level 16 Normal Exit
	[],
	# Level 16 Secret Exit
	[],
	# Level 17 Normal Exit
	[],
	# Level 17 Secret Exit
	[],
	# Level 18 Normal Exit
	[],
	# Level 18 Secret Exit
	[],
	# Level 19 Normal Exit
	[],
	# Level 19 Secret Exit
	[],
	# Level 20 Normal Exit
	[],
	# Level 20 Secret Exit
	[],
	# Level 21 Normal Exit
	[],
	# Level 21 Secret Exit
	[],
	# Level 22 Normal Exit
	[],
	# Level 22 Secret Exit
	[],
	# Level 23 Normal Exit
	[],
	# Level 23 Secret Exit
	[],
	# Level 24 Normal Exit
	[],
	# Level 24 Secret Exit
	[],
	# Level 25 Normal Exit
	[],
	# Level 25 Secret Exit
	[],
	# Level 26 Normal Exit
	[],
	# Level 26 Secret Exit
	[],
	# Level 27 Normal Exit
	[],
	# Level 27 Secret Exit
	[],
	# Level 28 Normal Exit
	[],
	# Level 28 Secret Exit
	[],
	# Level 29 Normal Exit
	[],
	# Level 29 Secret Exit
	[],
	# Level 30 Normal Exit
	[],
	# Level 30 Secret Exit
	[],
	# Level 31 Normal Exit
	[],
	# Level 31 Secret Exit
	[]
]

# Map events are of the form: [frame number, type, coordinates, extra info]
# Frame number is what animation frame the event occurs on
# Type - 0: Map Tile Change, 1: Path tile change, 2: Object property change, 3: Path direction set
# Coordinates of tile change, object appearing, etc
# Extra info - if type is 0, [tileset number, index of tile].
#	if type is 2, dictionary of the object details {"type": "level/warp/other", "number":*, "visible":true/false...}.
# 	if type is 3, [level/warp, number, direction index(up/down/left/right)]

export var level_index_to_scene_name = [
	"TestLevel", "Level1", "Level2", "Level3", "Level4", "Level5", "Level6", "Boss1"
	]

func _ready() -> void:
	Globals.checkpoint_data[0] = 0
	anim_frame = 0
	anim_timer = 45
	
	if Globals.goal_reached_in_current_level[0] and not Globals.level_flags[Globals.current_level][0]:
		doing_map_events = true
		current_event_trigger = Globals.current_level*2
		print('normal exit just obtained!')
	
	elif Globals.goal_reached_in_current_level[1] and not Globals.level_flags[Globals.current_level][1]:
		doing_map_events = true
		current_event_trigger = Globals.current_level*2 + 1
		print('secret exit just obtained!')
	
	if Globals.goal_reached_in_current_level[0] or Globals.goal_reached_in_current_level[1]:
		add_val_coins()

func add_val_coins():
	for i in range(3):
		Globals.val_coin_list[Globals.current_level][i] = (
			Globals.val_coin_list[Globals.current_level][i] or Globals.coins_collected_in_level[i])

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	
	if done_initial_setup and not doing_map_events:
		if Globals.current_level < 200:
			for i in range(3):
				Globals.coins_collected_in_level[i] = Globals.val_coin_list[Globals.current_level][i]
		else:
			Globals.coins_collected_in_level = [false, false, false]
		return
	
	Globals.lock_input = true
	
	if not done_initial_setup:
		for i in range(Globals.LEVEL_COUNT):
			if Globals.level_flags[i][0]:
				$Levels.find_node(level_index_to_scene_name[i]).mark_completed()
				for ev in map_events[2*i]:
					do_map_event(ev)
			if Globals.level_flags[i][1]:
				for ev in map_events[2*i+1]:
					do_map_event(ev)
		done_initial_setup = true
		
		# Account for most recent level completion:
		if Globals.goal_reached_in_current_level[0] or Globals.goal_reached_in_current_level[1]:
			$Levels.find_node(level_index_to_scene_name[Globals.current_level]).mark_completed()
		
		if not doing_map_events:
			Globals.lock_input = false
			return

	if anim_timer > 0:
		anim_timer -= 1
		return
	
	if event_number >= map_events[current_event_trigger].size():
		doing_map_events = false
		Globals.lock_input = false
		Globals.level_flags[Globals.current_level][0] = Globals.goal_reached_in_current_level[0] or Globals.level_flags[Globals.current_level][0]
		Globals.level_flags[Globals.current_level][1] = Globals.goal_reached_in_current_level[1] or Globals.level_flags[Globals.current_level][1]
		return
	
	for event in map_events[current_event_trigger]:
		if event[0] == anim_frame:
			do_map_event(event)
			event_number += 1
	anim_frame += 1
	anim_timer = FRAME_DELAY

func do_map_event(event):
	match event[1]:
		0:
			var coords = event[2]
			var using_tilemap = tilemaps[event[3][0]]
			var tile_to_add = event[3][1]
			#print("Adding tile " + str(tile_to_add) + " from tileset " + str(using_tilemap) + " at coordinates " + str(coords))
			using_tilemap.set_cellv(coords, tile_to_add)
		1:
			var coords = event[2]
			var using_tilemap = path_tilemaps[event[3][0]]
			var tile_to_add = event[3][1]
			print("Adding tile " + str(tile_to_add) + " from tileset " + str(using_tilemap) + " at coordinates " + str(coords))
			using_tilemap.set_cellv(coords, tile_to_add)
		2:
			var object_type = event[3]["type"]
			var object
			if object_type == "level":
				object = $Levels.find_node(level_index_to_scene_name[event[3]["number"]])
			elif object_type == "warp":
				object = $Warps.find_node("Warp" + str(event[3]["number"]))
			
			if "visible" in event[3]:
				object.visible = true
				if done_initial_setup:
					make_level_shine(object.position-Vector2(0,4))
			if "unlocked" in event[3]:
				object.mark_unlocked()
				if done_initial_setup:
					make_level_shine(object.position-Vector2(0,4))
		
		3:
			var object
			if event[3][0] == 0:
				object = $Levels.find_node(level_index_to_scene_name[event[3][1]])
			elif event[3][0] == 1:
				object = $Warps.find_node("Warp" + str(event[3][1]))
			
			if event[3][2] == 0:
				object.has_up_path = true
			elif event[3][2] == 1:
				object.has_down_path = true
			elif event[3][2] == 2:
				object.has_left_path = true
			elif event[3][2] == 3:
				object.has_right_path = true

func make_level_shine(pos):
	var shine_scene = load("res://src/effects/LevelShine.tscn")
	var spawn := shine_scene.instance() as Node2D
	add_child(spawn)
	spawn.set_as_toplevel(true)
	spawn.global_position = pos
