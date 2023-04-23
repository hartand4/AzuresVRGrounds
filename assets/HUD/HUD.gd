extends CanvasLayer

onready var _health = get_parent().health

onready var health_meter := $VisibleHealth
onready var health_bar := $VisibleHealth/HealthMeter

# warning-ignore:unused_argument
func _process(delta):
	_health = get_parent().health
	health_meter.set_size(Vector2(20.0, _health*4))
	health_meter.set_position(Vector2(22,14 + 4*(32-_health)))
	health_bar.set_position(Vector2(health_bar.get_position().x, -4*(32-_health)))
