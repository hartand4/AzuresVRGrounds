extends KinematicBody2D
class_name Health

var _velocity := Vector2.ZERO
var _giving_health := false
var _health_to_give = 8
var _animation = 'Idle'
onready var _player = Globals.find_player()
export var persistent := false
var persist_timer := 420

var is_in_water := false
var _gravity := 2000.0


func _process(_delta: float) -> void:
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
	_velocity.y += _gravity*(1.0 / 60.0)*(0.4 if is_in_water else 1.0)
	_velocity.y = min(_velocity.y, 1200.0*(0.6 if is_in_water else 1.0))
	_velocity = move_and_slide(_velocity, Vector2.UP, true)
	
	# Failsafe for despawning
	if get_position().y > 999999: call_deferred("disable_all")
	
	if persistent: return
	
	persist_timer -= 1
	visible = true
	if not persist_timer: call_deferred("disable_all")
	elif persist_timer < 90 and Globals.timer % 3 > 0:
		visible = false

func disable_all():
	$HealthHitbox.disabled = true
	$HealthArea/HealthHitbox2.disabled = true
	get_parent().remove_child(self)
	queue_free()

func get_velocity():
	return _velocity
func set_velocity(vel):
	_velocity = vel

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
