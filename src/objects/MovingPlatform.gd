extends KinematicBody2D

export var starting_dir := Vector2.RIGHT
export var track_length := 7
export var flip := true
export var vertical := false
export var period := 360

var _pos := 0.0
var _timer := 0

func _ready() -> void:
	if vertical:
		$Sprite.rotation = PI/2
		$CollisionShape2D.rotation = PI/2


func _physics_process(_delta) -> void:
	if Globals.game_paused: return
	if flip:
		# warning-ignore:integer_division
		var dir := starting_dir if _timer < period/2 else -starting_dir
		$Arrow.rotation = closest_right_angle(dir)
	_timer += 1
	if _timer >= period:
		_timer = 0
	_pos = track_length*24*(-cos(_timer*2*PI/period) + cos((_timer-1)*2*PI/period))
	self.position += Vector2(starting_dir)*_pos


func closest_right_angle(dir):
	if dir.x > dir.y:
		if dir.y > -dir.x:
			return 0.0
		return 3*PI/2
	if dir.y > -dir.x:
		return PI/2
	return PI

