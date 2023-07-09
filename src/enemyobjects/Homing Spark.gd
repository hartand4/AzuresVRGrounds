extends Projectile

var state := 0
var direction = Vector2.ZERO
export var first_position := Vector2.ZERO
var speed := 12

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage = 4
	animation_timer = 30


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	$AnimationPlayer.play("Idle")
	
	if state == 0:
		var target_position = self.get_parent().position + first_position
		if (target_position - self.position).length_squared() > 10:
			self.position += vector_min( (target_position - self.position).normalized()*speed, (target_position - self.position) )
		if not animation_timer:
			direction = (Globals.find_player().position - self.position - Vector2(0,48)).normalized()
			state += 1
	elif state == 1:
		self.position += direction*speed

func vector_min(v1, v2):
	return v1 if v1.length_squared() < v2.length_squared() else v2
