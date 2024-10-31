extends Projectile

export var player_attack_type := 4
var active = true # To help player

func _ready():
	$Sprite.frame = 0


func _process(_delta):
	$AnimationPlayer.playback_speed = 0 if Globals.game_paused else 1
	if Globals.game_paused: return
	
	$Sprite.flip_h = velocity.x < 0
	$AnimationPlayer.play("Spin")
	
	self.position += velocity/60.0
	velocity.y += gravity/6000.0
