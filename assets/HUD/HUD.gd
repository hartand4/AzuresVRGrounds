extends CanvasLayer

onready var _health
onready var max_health
onready var ammo
onready var max_ammo

func _process(_delta):
	_health = get_parent().health
	max_health = get_parent().max_health
	for i in range(64):
		$VisibleHealth.find_node("HealthBar"+str(i+1)).visible = _health >= i+1
	
	var bar_scale_factor = int(clamp(max_health, 1, 32))
	
	$Bar/HealthBarAlong.rect_scale.y = bar_scale_factor * 2 - 1
	$Bar/HealthBarAlong.rect_position.y = 72-2*bar_scale_factor
	$Bar/HealthBarTop.rect_position.y = 68-2*bar_scale_factor
	$Bar/BarMergeRegion.rect_position.y = 71 - 2*bar_scale_factor
	$Bar/BarMergeRegion.rect_size.y = 12 + 2*bar_scale_factor
	$Bar/BarMergeRegion/BarMerge.rect_position.y = -51 + 2*bar_scale_factor
	
	$Bar/HealthIndicator.visible = max_health > 32
	$Bar/HealthIndicator.frame = 1 if max_health == 64 else 0
	$Bar/HealthIndicator.position.y = 72.5 - 2*(max_health-32)
	
	ammo = get_parent().ammo
	max_ammo = get_parent().max_ammo
	
	for i in range(48):
		$Bar/AmmoBar.find_node("Ammo"+str(i+1)).visible = (ammo >= 2*i+1)
	$Bar/AmmoBar.visible = get_parent().current_attack != 0
	$Bar/BarMergeRegion.visible = get_parent().current_attack != 0
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
