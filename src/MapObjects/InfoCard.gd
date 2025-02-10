extends CanvasLayer

var title = ''
onready var player
var player_hide = false

var ignore_pause = true

func _ready():
	$Card.visible = false
	player = get_parent().find_node('MapPlayer')

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed('dash'):
		player_hide = not player_hide
	if player_hide or Globals.game_paused:
		$Card.visible = false
		return
	
	if (not player.on_level) or player.is_moving:
		return
	if not player.on_level.level_number:
		$Card.visible = false
		return
	$Card.visible = true
	if player.on_level.level_number < 200:
		for i in range(3):
			$Card.find_node('Coin'+str(i+1)).visible = true
			$Card.find_node('Coin'+str(i+1)).frame = i if Globals.coins_collected_in_level[i] else 3
		for j in range(2):
			$Card.find_node('Goal'+str(j+1)).visible = Globals.level_flags[player.on_level.level_number][j] or (
			Globals.goal_reached_in_current_level[j] and get_parent().doing_map_events)
	else:
		for i in range(3):
			$Card.find_node('Coin'+str(i+1)).visible = false
		for j in range(2):
			$Card.find_node('Goal'+str(j+1)).visible = false
	
	
