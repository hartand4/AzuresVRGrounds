extends Node
class_name StateMachine

var state = null
var prev_state = null

var states = {}

onready var parent = get_parent()

func _physics_process(_delta):
	if state != null:
		_state_logic()
		var transition = _get_transition()
		if transition != null:
			set_state(transition)


func _state_logic():
	pass

func _get_transition():
	return null

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _enter_state(new_state, old_state):
	pass

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _exit_state(old_state, new_state):
	pass

func set_state(new_state):
	prev_state = state
	state = new_state
	
	if prev_state != null:
		_exit_state(prev_state, new_state)
	if new_state != null:
		_enter_state(new_state, prev_state)

func add_state(state_name):
	states[state_name] = states.size()
