extends StaticBody2D


export var length := 1
export var move_right := false
var direction := -1
export var speed := 1

var blocklist = null
var block_animation := 'Single'


func _ready() -> void:
	direction = 1 if move_right else -1
	if length > 1:
		block_animation = 'Left End'
	for i in range(length - 1):
		var new_block = self.duplicate()
		new_block.set_as_toplevel(true)
		new_block.position = self.position + Vector2(48*(i+1), 0)
		new_block.name = self.name + 'Block' + str(i+2)
		new_block.length = 1
		new_block.set_block_type('Right End' if i == length-2 else 'Middle')
		new_block.remove_child(new_block.find_node("ObjectMoveArea"))
		blocklist = new_block
		
		get_parent().call_deferred('add_child', new_block)
	if find_node("ObjectMoveArea"):
		for i in range(length-1):
			var collision_copy = $ObjectMoveArea/Collision.duplicate()
			$ObjectMoveArea.add_child(collision_copy)
			collision_copy.position.x += 48*(i+1)

func _process(_delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if direction > 0:
		$AnimationPlayer.playback_speed = speed
		$AnimationPlayer.play(block_animation)
	else:
		$AnimationPlayer.playback_speed = speed
		$AnimationPlayer.play_backwards(block_animation)
	
	if not find_node("ObjectMoveArea"): return
	
	for area in $ObjectMoveArea.get_overlapping_areas():
		if area.get_collision_layer_bit(1):
			area.get_parent().add_position(Vector2(speed*direction, 1))
			#area.get_parent().position.x += speed*direction
		
		elif (area.get_collision_layer_bit(2) or area.get_collision_layer_bit(3)):
			var top_node = area
			while (top_node.get_parent() != Globals.get_current_scene()) and top_node.get_parent() != null:
				top_node = top_node.get_parent()
			top_node.position.x += speed*direction

func set_block_type(anim_str):
	block_animation = anim_str
