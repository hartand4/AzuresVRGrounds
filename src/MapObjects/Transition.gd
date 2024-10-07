extends CanvasLayer


onready var transition_layer := $TransitionTexture
onready var border_bottom := $TransitionBottom
onready var border_top := $TransitionTop
onready var border_left := $TransitionLeft
onready var border_right := $TransitionRight

var fade_position := Vector2(0,0)
var is_transitioning = false
var transition_type = 0

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta: float) -> void:
	if not is_transitioning: return
	elif transition_layer.get_scale().x < 0.01 and transition_type == 1:
		is_transitioning = false
		transition_layer.visible = false
		return
	elif transition_layer.get_scale().x > 3.99 and transition_type == 2:
		is_transitioning = false
		transition_layer.visible = false
		return
	transition_layer.set_position(fade_position - Vector2(500, 500))
	border_bottom.visible = true
	border_top.visible = true
	border_left.visible = true
	border_right.visible = true
	
	# Iris transition types
	if transition_type in [1,2]:
		transition_layer.visible = true
		if transition_type == 1:
			transition_layer.set_scale(transition_layer.get_scale() + Vector2(-0.07,-0.07))
		elif transition_type == 2:
			transition_layer.set_scale(transition_layer.get_scale() + Vector2(0.07,0.07))
		transition_layer.set_scale(Vector2(max(0, transition_layer.get_scale().x),
			max(0, transition_layer.get_scale().y)))
		transition_layer.set_scale(Vector2(min(4, transition_layer.get_scale().x),
			min(4, transition_layer.get_scale().y)))
	
		rotate_about_mid(transition_layer, PI/30)
		set_transition_position()
	
	# Black borders on top and bottom
	elif transition_type in [3,4]:
		var speed = 10
		if transition_type == 4:
			speed *= -1
		border_top.set_position(border_top.get_position() + Vector2(0,speed))
		border_bottom.set_position(border_bottom.get_position() + Vector2(0,-speed))
		
		if transition_type == 3 and border_top.get_position().y >= 312:
			is_transitioning = false
		elif transition_type == 4 and border_bottom.get_position().y >= 624:
			is_transitioning = false
	
	# Fade in/out
	elif transition_type in [5,6]:
		var speed = 0.02
		if transition_type == 6: speed *= -1
		border_top.modulate.a += speed
		
		if transition_type == 5 and border_top.modulate.a >= 1: is_transitioning = false
		elif transition_type == 6 and border_top.modulate.a <= 0: is_transitioning = false

func rotate_about_mid(obj, angle):
	var midpoint = obj.get_size()*obj.get_scale()/2
	midpoint.rotated(obj.get_rotation())
	obj.set_rotation(obj.get_rotation() + angle)

func set_transition_position():
	border_bottom.set_position(Vector2(0, transition_layer.get_position().y + 500 +
		(transition_layer.get_size()*transition_layer.get_scale()/2).y - 170*transition_layer.get_scale().y))
	
	border_top.set_position(Vector2(0, -624 + transition_layer.get_position().y + 500 -
		(transition_layer.get_size()*transition_layer.get_scale()/2).y + 170*transition_layer.get_scale().y))
	
	border_left.set_position(Vector2(-864 + transition_layer.get_position().x + 500 -
		(transition_layer.get_size()*transition_layer.get_scale()/2).x + 170*transition_layer.get_scale().x, 0))
	
	border_right.set_position(Vector2(transition_layer.get_position().x + 500 +
		(transition_layer.get_size()*transition_layer.get_scale()/2).x - 170*transition_layer.get_scale().x, 0))

func start_transition(pos, transition_num):
	fade_position = pos
	is_transitioning = true
	transition_type = transition_num
	border_top.modulate.a = 1
	# Start small
	if transition_type in [2]:
		transition_layer.set_scale(Vector2(0,0))
	elif transition_type in [3]:
		border_top.set_position(Vector2(0,-624))
		border_bottom.set_position(Vector2(0,624))
	elif transition_type in [4]:
		border_top.set_position(Vector2(0,-312))
		border_bottom.set_position(Vector2(0,312))
	elif transition_type in [5,6]:
		border_top.set_position(Vector2.ZERO)
		if transition_type == 5: border_top.modulate.a = 0
	elif transition_type in [7]:
		# No transition, instant visibility
		transition_layer.set_scale(Vector2(4,4))
		border_bottom.set_position(Vector2(0,624))
		border_top.set_position(Vector2(0,-640))
		border_left.set_position(Vector2(-884,0))
		border_right.set_position(Vector2(864,0))
		is_transitioning = false
