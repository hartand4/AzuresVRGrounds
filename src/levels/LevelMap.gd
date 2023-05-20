extends Node2D

# This is mainly used to store lookup tables about map tiles, and triggering map events.


# Lists where each warp will go. Each formatted as [true iff target is a warp else false, level/warp number]
export var warp_info_list = [
	[], [true, 2], [true, 1]
	]

export var level_index_to_scene_name = [
	"", "Level1", "Level2", "Level3", "Level4", "Level5", "Level6", "Boss1"
	]

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
