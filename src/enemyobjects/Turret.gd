extends Area2D

var animation_timer = 0
var broken = false
var state = 0
export var damage = 3
var health = 3

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if Globals.game_paused:
		$AnimationPlayer.stop(false)
		return
	elif broken and animation_timer:
		$Collision.disabled = true
		$Sprite.visible = false
		if animation_timer == 1:
			Globals.spawn_debris(load("res://assets/Sprites/Turret/Debris1.png"),
			position + Vector2(12, -12).rotated(rotation))
			Globals.spawn_debris(load("res://assets/Sprites/Turret/Debris2.png"),
			position + Vector2(-12, -12).rotated(rotation))
			Globals.spawn_debris(load("res://assets/Sprites/Turret/Debris3.png"),
			position + Vector2(0, -16).rotated(rotation))
			
			Globals.spawn_health(position)
			Globals.spawn_explosion(position + Vector2(0,-12).rotated(rotation))
			
		animation_timer -= 1
		$Visibility.process_parent = false
		return
	elif broken:
		respawn()
		return
	
	if state == 0:
		$AnimationPlayer.play("Idle")
		if animation_timer == 40:
			spawn_bullets()
		elif animation_timer == 0:
			animation_timer = 49
			state = 1
	else:
		$AnimationPlayer.play("Turn")
		if animation_timer == 0:
			state = 0
			animation_timer = 60
	if animation_timer: animation_timer -= 1

func respawn():
	var camera_pos = Globals.get_current_camera().get_camera_screen_center()
	if camera_pos.x - 420 - 120 < position.x and camera_pos.x + 420 + 120 > position.x and (
		camera_pos.y - 300 - 120 < position.y and camera_pos.y + 300 + 120 > position.y): return
	$Collision.disabled = false
	$Sprite.visible = true
	broken = false
	state = 0
	health = 3
	$Visibility.process_parent = true


func _on_Turret_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(4):
		health -= 3
	elif area.get_collision_layer_bit(11):
		health -= 1
	if health <= 0:
		broken = true
		animation_timer = 3

func spawn_bullets():
	var scene = load("res://src/enemyobjects/Bullet.tscn")
	var spawn1 := scene.instance() as Node2D
	add_child(spawn1)
	spawn1.set_as_toplevel(true)
	spawn1.global_position = position + Vector2(-24,-32).rotated(rotation)
	spawn1.velocity = Vector2(-300,-300).rotated(rotation)
	
	var spawn2 := scene.instance() as Node2D
	add_child(spawn2)
	spawn2.set_as_toplevel(true)
	spawn2.global_position = position + Vector2(24,-32).rotated(rotation)
	spawn2.velocity = Vector2(300,-300).rotated(rotation)

func get_damage():
	return damage
