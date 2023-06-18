extends Area2D

export var collected := false
export var coin_number := 1
var _anim_timer := 0
var _anim_index := 0


func _ready() -> void:
	if Globals.coins_collected_in_level[coin_number - 1] or (
		Globals.checkpoint_data[0] and Globals.checkpoint_data[coin_number]):
		_anim_index = 4
	else:
		_anim_index = coin_number


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if collected and _anim_timer == 0: pass
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if _anim_timer: _anim_timer -= 1
	if not collected or _anim_timer > 18:
		$AnimationPlayer.playback_speed = 1
		$AnimationPlayer.play('Spin' + str(_anim_index))
	
	if _anim_timer > 18:
		self.position.y -= pow(_anim_timer, 2)/1000
		$AnimationPlayer.playback_speed = 6
	elif _anim_timer <= 18 and _anim_timer >= 2:
		$AnimationPlayer.playback_speed = 1
		$AnimationPlayer.play("Sparkle" + str(_anim_index))
	elif _anim_timer == 1:
		$Sprite.visible = false
		
	
func disable_hitbox(): $ValCollision.disabled = true

func _on_ValMedal_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		collected = true
		Globals.find_player().collected_coins[coin_number-1] = true
		_anim_timer = 60
		call_deferred('disable_hitbox')
