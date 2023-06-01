extends KinematicBody2D


var animation_timer = 0
var breaking = false
var broken = false
var original_position = Vector2.ZERO
var velocity = Vector2.ZERO

func _ready():
	original_position = position

func _process(delta: float) -> void:
	if Globals.game_paused: return
	elif broken:
		respawn()
	elif not breaking: return
	if animation_timer:
		animation_timer -= 1
	if animation_timer == 28:
		# warning-ignore:unused_variable
		for i in range(3):
			Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakingPlatform/MiniDebris2.png"),
			position + Vector2(0, -24))
	elif animation_timer == 0:
		velocity.y += 60*delta
		velocity.y = min(3000, velocity.y)
		position += velocity
		

func respawn():
	var camera_pos = Globals.find_player().find_node('Camera2D').get_camera_screen_center()
	if camera_pos.x - 420 - 120 < original_position.x and camera_pos.x +420 + 120 > original_position.x and (
		camera_pos.y - 300 - 120 < original_position.y and camera_pos.y + 300 + 120 > original_position.y): return
	position = original_position
	$Collision.disabled = false
	$Sprite.visible = true
	$PlayerCheckArea/Collision.disabled = false
	broken = false
	breaking = false
	velocity = Vector2.ZERO
	animation_timer = 33


func _on_PlayerCheckArea_area_entered(area: Area2D) -> void:
	if not area.get_collision_layer_bit(1) or breaking or broken: return
	animation_timer = 33
	breaking = true

func disable_collision():
	$Collision.disabled = true
	$PlayerCheckArea/Collision.disabled = true

func _on_BreakCheckArea_body_entered(body: Node) -> void:
	if not body.get_collision_layer_bit(0): return
	if body == self or broken: return
	broken = true
	velocity = Vector2.ZERO
	breaking = false
	$Sprite.visible = false
	call_deferred("disable_collision")
	Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakingPlatform/Debris3.png"),
		position + Vector2(0, -24))
	Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakingPlatform/Debris4.png"),
		position + Vector2(0, -24))
