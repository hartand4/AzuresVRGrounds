extends CanvasLayer


onready var transition_layer := $TransitionTexture
onready var border_bottom := $TransitionBottom
onready var border_top := $TransitionTop
onready var border_left := $TransitionLeft
onready var border_right := $TransitionRight

var fade_position := Vector2(0,0)
var is_transitioning = false
var is_transitioning_backward = false

export var start_black = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if start_black:
		transition_layer.set_scale(Vector2.ZERO)
		transition_layer.visible = false
		border_bottom.visible = true
		border_top.visible = true
		border_left.visible = true
		border_right.visible = true
		border_right.set_position(Vector2.ZERO)
	else:
		transition_layer.set_scale(Vector2(4,4))
		transition_layer.visible = false
		border_bottom.visible = false
		border_top.visible = false
		border_left.visible = false
		border_right.visible = false
	
	border_bottom.set_scale(Vector2(1,1))
	border_top.set_scale(Vector2(1,1))
	border_left.set_scale(Vector2(1,1))
	border_right.set_scale(Vector2(1,1))
	transition_layer.set_pivot_offset(transition_layer.get_size()/2)
	is_transitioning = false
	is_transitioning_backward = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if not (is_transitioning or is_transitioning_backward): return
	elif transition_layer.get_scale().x < 0.01 and is_transitioning:
		is_transitioning = false
		return
	elif transition_layer.get_scale().x > 3.99 and is_transitioning_backward:
		is_transitioning_backward = false
		return
	transition_layer.set_position(fade_position - Vector2(500, 500))
	transition_layer.visible = true
	border_bottom.visible = true
	border_top.visible = true
	border_left.visible = true
	border_right.visible = true
	
	if is_transitioning:
		transition_layer.set_scale(transition_layer.get_scale() + Vector2(-0.07,-0.07))
	elif is_transitioning_backward:
		transition_layer.set_scale(transition_layer.get_scale() + Vector2(0.07,0.07))
	transition_layer.set_scale(Vector2(max(0, transition_layer.get_scale().x),
		max(0, transition_layer.get_scale().y)))
	transition_layer.set_scale(Vector2(min(4, transition_layer.get_scale().x),
		min(4, transition_layer.get_scale().y)))
	
	rotate_about_mid(transition_layer, PI/30)
	set_transition_position()

func rotate_about_mid(obj, angle):
	var midpoint = obj.get_size()*obj.get_scale()/2
	midpoint.rotated(obj.get_rotation())
	obj.set_rotation(obj.get_rotation() + angle)

func set_transition_position():
	border_bottom.set_position(Vector2(0, transition_layer.get_position().y + 500 +
		(transition_layer.get_size()*transition_layer.get_scale()/2).y - 170*transition_layer.get_scale().y))
	
	border_top.set_position(Vector2(0, -600 + transition_layer.get_position().y + 500 -
		(transition_layer.get_size()*transition_layer.get_scale()/2).y + 170*transition_layer.get_scale().y))
	
	border_left.set_position(Vector2(-840 + transition_layer.get_position().x + 500 -
		(transition_layer.get_size()*transition_layer.get_scale()/2).x + 170*transition_layer.get_scale().x, 0))
	
	border_right.set_position(Vector2(transition_layer.get_position().x + 500 +
		(transition_layer.get_size()*transition_layer.get_scale()/2).x - 170*transition_layer.get_scale().x, 0))

func start_transition(pos, forward):
	fade_position = pos
	if forward:
		is_transitioning = true
		is_transitioning_backward = false
		return
	is_transitioning_backward = true
	is_transitioning = false
	transition_layer.set_scale(Vector2(0,0))
