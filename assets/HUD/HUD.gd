extends CanvasLayer

onready var _health
onready var max_health
onready var ammo
onready var max_ammo

export var extend_health_animation_timer := 0

var ignore_pause = true

func _process(_delta):
	_health = get_parent().health
	max_health = get_parent().max_health
	for i in range(64):
		$VisibleHealth.find_node("HealthBar"+str(i+1)).visible = _health >= i+1
	
	var bar_scale_factor = int(clamp(max_health, 1, 32))
	
	$Bar/HealthBarAlong.rect_scale.y = bar_scale_factor * 2 - 1
	$Bar/HealthBarAlong.rect_position.y = 72-2*bar_scale_factor
	$Bar/HealthBarTop.rect_position.y = 68-2*bar_scale_factor
	
	$Bar/HealthIndicator.visible = max_health > 32
	$Bar/HealthIndicator.frame = 1 if max_health == 64 else 0
	$Bar/HealthIndicator.position.y = 72.5 - 2*(max_health-32)
	
	ammo = get_parent().ammo
	max_ammo = get_parent().max_ammo
	
	for i in range(48):
		$Bar/AmmoBar.find_node("Ammo"+str(i+1)).visible = (ammo >= 2*i+1)
	$Bar/AmmoBar.visible = get_parent().current_attack != 0
	$Bar/AmmoBar.frame = 0 if max_health >= 26 else 26-max_health
	$Bar/AmmoBar/WeaponIcon.frame = max(0, get_parent().current_attack-1)
	
	
	$VSwitchTimer.visible = (Globals.vswitch_timer > 0)
	# warning-ignore:integer_division
	$VSwitchTimer/TimerH.frame = ((Globals.vswitch_timer+30)/3000) % 10
	# warning-ignore:integer_division
	$VSwitchTimer/TimerT.frame = ((Globals.vswitch_timer+30)/300) % 10
	# warning-ignore:integer_division
	$VSwitchTimer/TimerU.frame = ((Globals.vswitch_timer+30)/30) % 10
	
	if Globals.pause_menu_on:
		$PauseMenu.visible = true
		$PauseMenu/ValcoinRed.visible = Globals.coins_collected_in_level[0] or Globals.find_player().collected_coins[0]
		$PauseMenu/ValcoinBlue.visible = Globals.coins_collected_in_level[1] or Globals.find_player().collected_coins[1]
		$PauseMenu/ValcoinGreen.visible = Globals.coins_collected_in_level[2] or Globals.find_player().collected_coins[2]
	else:
		$PauseMenu.visible = false
	
	if Globals.retry_menu_on: $RetryMenu.visible = true
	else: $RetryMenu.visible = false
	
	if extend_health_animation_timer > 0:
		#Globals.game_paused = true
		Globals.pause_nodes()
		print(Globals.get_max_health())
		if Globals.set_health >= Globals.get_max_health() - 2:
			extend_health()
		extend_health_animation_timer -= 1
		if extend_health_animation_timer == 0:
			#Globals.game_paused = false
			Globals.pause_nodes(true)
			$Bar.modulate = Color(1, 1, 1)

func extend_health():
	if extend_health_animation_timer >= 12: return
	if extend_health_animation_timer % 4 == 0:
		get_parent().max_health += 1
		get_parent().health += 1
		Globals.set_health += 1
		# TODO: Play sound
	$Bar.modulate = Color(1.5, 1.5, 1.5) if extend_health_animation_timer % 4 < 3 else Color(1,1,1)
