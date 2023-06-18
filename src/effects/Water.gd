extends Area2D

const visibility_value := 0.5

func _ready() -> void:
	$Sprite.visible = true
	$Sprite.scale.x = 999999
	$Sprite.modulate.a = visibility_value
	$Collision.shape.extents = Vector2(999999, 10000)
	$Collision.set_position($Collision.get_position() + Vector2(0,9964))
	$ColorRect.set_size(Vector2(999999,9999))
	$ColorRect.modulate.a = visibility_value
	$ColorRect.set_position($ColorRect.get_position() + Vector2(0,72))
