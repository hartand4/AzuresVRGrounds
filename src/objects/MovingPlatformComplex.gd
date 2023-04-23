extends KinematicBody2D

export var points := [Vector2(0.0,0.0)]
export var max_time := 360
export var flip := true
export var vertical := false
export var on_walk := false
export var smooth_return := false
export var needs_player := false

var _pos := Vector2.ZERO
var _timer := 0
var _total_dist := 0.0
var _speed := 1.0
var _total_dist_moved := 0.0
var _current_point := 0
var _activated = false
var _blinking_phase = false

func _ready() -> void:
	if vertical:
		$Sprite.rotation = PI/2
		$CollisionShape2D.rotation = PI/2
	if smooth_return:
		points += [-vector_arr_sum(points)]
	for i in points:
		_total_dist += i.length()
	_speed = _total_dist / max_time

# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused: return
	
	$CollisionShape2D.disabled = false
	$ActivationArea/ActivationCollision.disabled = false
	
	if on_walk != _activated:
		$Sprite.visible = false
		$SpriteInactive.visible = true
		$Arrow.visible = false
		_activated = check_activity()
		return
		
	$Sprite.visible = true
	$SpriteInactive.visible = false
	$Arrow.visible = true
	
	if flip:
		$Arrow.rotation = closest_right_angle(points[_current_point])
	
	_timer += 1
	if _timer >= max_time:
		_timer = 0
		
	if _blinking_phase and _timer < 90:
		$Sprite.visible = (_timer % 4 < 2)
		$Arrow.visible = false
		return
	elif _blinking_phase:
		_timer = 0
		_blinking_phase = false
		$Arrow.visible = false
		$CollisionShape2D.disabled = true
		$ActivationArea/ActivationCollision.disabled = true
		self.position += -vector_arr_sum(points)*48
		_activated = false
		
	if needs_player: _activated = check_activity()
	
	_pos = _speed*unit_direction_vector_single(points[_current_point])
	_total_dist_moved += _pos.length()
	self.position += _pos*48
	if _total_dist_moved >= points[_current_point].length():
		_current_point = (_current_point + 1) % points.size()
		_total_dist_moved = 0
		if _current_point == 0:
			if not on_walk:
				self.position += -vector_arr_sum(points)*48
				$CollisionShape2D.disabled = true
			elif not smooth_return:
				_blinking_phase = true
			else:
				_activated = false

func check_activity():
	for box in $ActivationArea.get_overlapping_areas():
		if box.get_collision_layer_bit(1): return true

func closest_right_angle(dir):
	if dir.x > dir.y:
		if dir.y > -dir.x:
			return 0.0
		return 3*PI/2
	if dir.y > -dir.x:
		return PI/2
	return PI

func unit_direction_vector_single(dir):
	if dir == Vector2.ZERO: return Vector2.ZERO
	return dir / dir.length()

func vector_arr_sum(arr):
	var sum = Vector2.ZERO
	for i in arr:
		sum += i
	return sum
		
