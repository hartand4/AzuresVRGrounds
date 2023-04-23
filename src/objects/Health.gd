extends KinematicBody2D
class_name Health

var _velocity := Vector2.ZERO
var _giving_health := false
var _health_to_give = 8
var _animation = 'Idle'
onready var _player = Globals.find_player()


func _process(delta: float) -> void:
	if (Globals.get("game_paused") and not _giving_health) or _health_to_give == 0:
		$AnimationPlayer.stop(false)
		return
	elif _giving_health:
		if _health_to_give and Globals.timer % 2 == 0:
			_health_to_give -= 1
			_player.health += 1
			if not _health_to_give or _player.health == 32:
				_health_to_give = 0
				Globals.lock_input = false
				Globals.game_paused = false
				_giving_health = false
				call_deferred('disable_all')
		return
	$AnimationPlayer.play(_animation)
	_velocity.y += 1200.0*delta
	_velocity.y = min(_velocity.y, 1200.0)
	_velocity = move_and_slide(_velocity, Vector2.UP, true)

func disable_all():
	$HealthHitbox.disabled = true
	$HealthArea/HealthHitbox2.disabled = true
	get_parent().remove_child(self)

func player_in_health():
	_velocity = Vector2.ZERO
	$HealthSprite.visible = false
	if _player.health < 32:
		Globals.game_paused = true
		Globals.lock_input = true
		_giving_health = true
		return
	_health_to_give = 0
	call_deferred('disable_all')
