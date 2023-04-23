extends Node


export var spawn_scene: PackedScene
var _timer = 0

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if get_child_count() > 0:
		return
	if _timer: _timer -= 1
	if _timer == 0:
		spawn()
		_timer = 120

func spawn(_spawn_scene := spawn_scene):
	if spawn_scene == null: return
	var spawn := _spawn_scene.instance() as Node2D
	add_child(spawn)
	
	spawn.set_as_toplevel(true)
	spawn.global_position = self.global_position
