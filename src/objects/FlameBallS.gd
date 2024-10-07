extends Projectile

export var direction := true
export var player_attack_type := 1
export var active := true
export var dash_flame := false
var active_timer = 0

var enemy_hit_last_frame = null 

const SMALL = 1
const MEDIUM = 2
const LARGE = 3

func _ready():
	$Sprite.flip_h = direction
	$Sprite.frame = 0


func _process(_delta):
	$AnimationPlayer.playback_speed = 0 if Globals.game_paused else 1
	if Globals.game_paused: return
	
	animation_timer = max(animation_timer-1, 0)
	$Sprite.flip_h = direction
	if active:
		active_timer += 1
		if !(player_attack_type == SMALL or dash_flame) and active_timer < 6:
			$Sprite.frame = 0
			self.position += Vector2(1,0)*(1 if direction else -1)
		else:
			$AnimationPlayer.play("Flame")
			self.position += Vector2(15,0)*(1 if direction else -1)
	
	if !enemy_hit_last_frame or !is_instance_valid(enemy_hit_last_frame): return
	
	var health = enemy_hit_last_frame.get("health")
	if health == null and enemy_hit_last_frame.get_parent():
		health = enemy_hit_last_frame.get_parent().get("health")
	
	if health and health > 0:
		call_deferred("do_burst")
	enemy_hit_last_frame = null

func _on_FlameBall_area_entered(area):
	if not check_hittable_obj(area): return
	elif animation_timer: return
	if player_attack_type == SMALL or dash_flame:
		animation_timer = 40
		call_deferred("do_burst")
		return
	
	var health = area.get("health")
	if health == null and area.get_parent(): health = area.get_parent().get("health")
	if health == null:
		if area.get_collision_layer_bit(10):
			call_deferred("do_burst")
		return
	
	enemy_hit_last_frame = area

func do_burst():
	$AnimationPlayer.stop()
	animation_timer = 40
	$AnimationPlayer.play("Burst")
	$Collision.disabled = true
	active = false

func check_hittable_obj(area):
	if area.get_collision_layer_bit(3) and !area.get_collision_layer_bit(10): return false
	if area.get("health") != null or (area.get_parent() and area.get_parent().get("health") != null): 
		return true
	if area.get_collision_layer_bit(10): return true
	return false
