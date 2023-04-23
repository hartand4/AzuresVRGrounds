extends Area2D

export var collected := false
export var coin_number := 1
var _anim_timer := 0


func _ready() -> void:
	pass


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if collected and _anim_timer == 0: pass
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	if _anim_timer: _anim_timer -= 1
	if not collected or _anim_timer > 18:
		$AnimationPlayer.play('Spin' + str(coin_number))
	
	if _anim_timer > 18:
		self.position.y -= pow(_anim_timer, 2)/1000
	elif _anim_timer <= 18 and _anim_timer >= 2:
		$AnimationPlayer.play("Sparkle" + str(coin_number))
	elif _anim_timer == 1:
		$Sprite.visible = false
		
	
func disable_hitbox(): $ValCollision.disabled = true

func _on_ValMedal_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(1):
		collected = true
		Globals.find_player().collected_coins[coin_number-1] = true
		_anim_timer = 60
		call_deferred('disable_hitbox')
