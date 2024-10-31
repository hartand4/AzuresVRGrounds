extends Projectile

export var direction := true
export var player_attack_type := 5
var active := true # For player
var sparking = false

func _ready():
	$Sprite.flip_h = direction
	$Sprite.frame = 5


func _process(_delta):
	$AnimationPlayer.playback_speed = 0 if Globals.game_paused else 1
	if Globals.game_paused: return
	
	$Sprite.flip_h = direction
	
	if !sparking:
		$AnimationPlayer.play("Move")
		self.position += Vector2(12,0)*(1 if direction else -1)
		return
	
	if animation_timer == 0:
		queue_free()
	if animation_timer % 9 == 8:
		call_deferred("swap_collision")
	$Sprite.modulate = Color(1,1,1)*(0.1*sin(PI*animation_timer/6.0) + 1.0)
	$Sprite.modulate.a = 0.1*sin(PI*animation_timer/12.0) + 0.7

func _on_SparkBlast_area_entered(area):
	if not check_hittable_obj(area): return
	elif sparking: return
	call_deferred("do_spark")

func do_spark():
	$AnimationPlayer.stop()
	animation_timer = 54
	$AnimationPlayer.play("Blast")
	$Collision.disabled = true
	$Spark1/Collision.disabled = false
	
	sparking = true

func check_hittable_obj(area):
	if area.get_collision_layer_bit(3) and !area.get_collision_layer_bit(10): return false
	if area.get("health") != null or (area.get_parent() and area.get_parent().get("health") != null): 
		return true
	if area.get_collision_layer_bit(10): return true
	if area.get_collision_layer_bit(2): return true
	return false

func _on_SparkBlast_body_entered(body):
	if !(body.get_collision_layer_bit(0) or body.get_collision_layer_bit(6)) or sparking: return
	call_deferred("do_spark")

func swap_collision():
	$Spark1/Collision.disabled = !$Spark1/Collision.disabled
	$Spark2/Collision.disabled = !$Spark2/Collision.disabled
