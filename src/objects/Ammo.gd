extends KinematicBody2D
class_name Ammo

var _velocity := Vector2.ZERO
var giving_ammo := false
export var ammo_to_give = 24
var _animation = 'Idle'
onready var _player = Globals.find_player()
export var persistent := false
var persist_timer := 420

var is_in_water := false
var _gravity := 2000.0

var ignore_pause = true

func _process(_delta: float) -> void:
	if (Globals.get("game_paused") and not giving_ammo) or ammo_to_give == 0:
		$AnimationPlayer.stop(false)
		return
	elif giving_ammo:
		if ammo_to_give and Globals.timer % 2 == 0:
			ammo_to_give -= 2
			_player.ammo += 2
			if not ammo_to_give or _player.ammo == _player.max_ammo:
				ammo_to_give = 0
				Globals.lock_input = false
				#Globals.game_paused = false
				Globals.pause_nodes(true)
				giving_ammo = false
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
	$Collision.disabled = true
	$Hitbox/Collision.disabled = true
	queue_free()

func get_velocity():
	return _velocity
func set_velocity(vel):
	_velocity = vel

func player_in_ammo():
	_velocity = Vector2.ZERO
	$Sprite.visible = false
	if _player.ammo < _player.max_ammo:
		#Globals.game_paused = true
		Globals.pause_nodes()
		Globals.lock_input = true
		giving_ammo = true
		return
	ammo_to_give = 0
	call_deferred('disable_all')

func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		player_in_ammo()
	elif area.get_collision_layer_bit(9):
		is_in_water = true


func _on_Hitbox_area_exited(area: Area2D) -> void:
	if area.get_collision_layer_bit(9):
		is_in_water = false
