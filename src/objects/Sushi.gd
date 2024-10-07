extends Actor

export var sushi_number := 0
var effect_timer = 0

func _ready():
	if Globals.hearts_obtained[sushi_number]:
		call_deferred("disable_all")

func _process(_delta):
	if !Globals.game_paused:
		$AnimationPlayer.playback_speed = 1
		$AnimationPlayer.play("Idle")
		_velocity = move_and_slide(_velocity, Vector2.UP, true)
		$Sprite.position.y = 4*sin(float(Globals.timer)/15) -22
		return
	
	$AnimationPlayer.playback_speed = 0
	if effect_timer == 0: return
	effect_timer -= 1
	if effect_timer == 12:
		_player.find_node("HUD").extend_health_animation_timer = 12
		Globals.hearts_obtained[sushi_number] = true
	elif effect_timer <= 1:
		call_deferred("disable_all")

func disable_all():
	$Collision.disabled = true
	$Hitbox/Collision.disabled = true
	queue_free()

func _on_Hitbox_area_entered(area):
	if area.get_collision_layer_bit(1):
		effect_timer = 90
		Globals.game_paused = true
		$Sprite.visible = false
		# TODO: Play sound effect
