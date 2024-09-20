extends CanvasLayer

onready var _health
onready var max_health
onready var ammo
onready var max_ammo

onready var health_meter := $VisibleHealth
onready var health_bar := $VisibleHealth/HealthMeter

# warning-ignore:unused_argument
func _process(delta):
	_health = get_parent().health
	max_health = get_parent().max_health
	health_meter.set_size(Vector2(20.0, _health*4))
	health_meter.set_position(Vector2(22,14 + 4*(max_health-_health)))
	health_bar.set_position(Vector2(health_bar.get_position().x, -4*(max_health-_health)))
	
	ammo = get_parent().ammo
	max_ammo = get_parent().max_ammo
	
	for i in range(48):
		$Bar/AmmoBar.find_node("Ammo"+str(i+1)).visible = (ammo >= 2*i+1)
	$Bar/AmmoBar.visible = get_parent().current_attack != 0
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
