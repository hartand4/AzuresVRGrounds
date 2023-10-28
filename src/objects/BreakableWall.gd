extends StaticBody2D


export var health = 3
var animation_timer = 0


func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if health <= 0:
		call_deferred("disable_all")
	$Sprite.modulate = Color(1,1,1)
	if animation_timer:
		animation_timer -= 1
		$Sprite.modulate = Color(2, 2, 2)

func disable_all():
	$Collision.disabled = true
	$AttackArea/AttackCollision.disabled = true
	$Sprite.visible = false
	animation_timer -= 1
	if animation_timer <= 0:
		Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakableWall/Debris1.png"),
		position + Vector2(-12, -24))
		Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakableWall/Debris2.png"),
		position + Vector2(12, -24))
		Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakableWall/Debris3.png"),
		position + Vector2(-12, 24))
		Globals.spawn_debris(load("res://assets/Sprites/Debris/BreakableWall/Debris4.png"),
		position + Vector2(12, 24))
		queue_free()

func _on_AttackArea_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(4):
		health -= 1
		if health > 0: animation_timer = 6
		else: animation_timer = 3
