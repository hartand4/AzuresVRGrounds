extends Actor
class_name Enemy

var broken := false
var damage

var debris_pos
export var health_rate := 1

var hitbox_obj

# Damage data values:
# 0: Slash
# 1-3: Small to large shots
# 4+: Alt weapons?
var damage_data_chart = [3,1,2,4,2,2]

var is_invulnerable = false

# Called when the node enters the scene tree for the first time.
func _ready():
	original_pos = position

func _physics_process(_delta):
	if _player and Globals.game_paused:
		return
	_velocity = move_and_slide(_velocity, Vector2.UP, true)

func _process(_delta):
	if Globals.game_paused:
		$AnimationPlayer.playback_speed = 0
		return
	if broken:
		position = original_pos
		respawn()
		return
	elif health <= 0:
		broken = true
		call_deferred("disable_all")
		Globals.spawn_explosion(position + debris_pos)
		Globals.spawn_health(position, health_rate)
		return
	elif despawn():
		return
	
	$Sprite.visible = true
	$Collision.disabled = false
	$Sprite.flip_h = recurring_x_dir > 0
	# If it has a child called "Hitbox", enable its collision
	if find_node("Hitbox"):
		$Hitbox/Collision.disabled = false
	$Sprite.modulate = Color(2.2,1.8,2.3) if i_frames else Color(1,1,1)

# Returns the damage value for player
func get_damage():
	return damage

# Resets the enemy to its default state
func reset_values():
	state = 0
	anim_timer = 0
	health = max_health
	i_frames = 0
	$Collision.disabled = false
	$Sprite.visible = true
	broken = false
	# If it has a child called "Hitbox", enable its collision
	if find_node("Hitbox"):
		$Hitbox/Collision.disabled = false

# Only reset the enemy if camera is away from the enemy's original position
func respawn():
	if in_camera_range(original_pos): return
	reset_values()

# Despawn if enemy is far from camera (break if original position is in view)
func despawn():
	if in_camera_range(position): return false
	call_deferred("disable_all")
	if in_camera_range(original_pos):
		broken = true
	return true

# Checks if a position is within the camera's vision
func in_camera_range(pos):
	var camera_pos = Globals.get_current_camera_pos()
	return camera_pos.x - 432 - 120 < pos.x and camera_pos.x + 432 + 120 > pos.x and (
		camera_pos.y - 312 - 120 < pos.y and camera_pos.y + 312 + 120 > pos.y)

# Disables collision, hides sprite, brings it to default position
func disable_all():
	$Collision.disabled = true
	$Sprite.visible = false
	health = max_health
	position = original_pos
	# If it has a child called "Hitbox", disable its collision
	if find_node("Hitbox"):
		$Hitbox/Collision.disabled = true
