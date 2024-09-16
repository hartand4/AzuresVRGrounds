extends StaticBody2D

var anim_timer := 0
export var max_timer := 500
var block_list = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_timer = 0
	Globals.vswitch_timer = 0
	for child in Globals.get_current_scene().get_children():
		if child.has_method("vswitch_change_state"):
			block_list += [child]


# warning-ignore:unused_argument
func _process(delta: float) -> void:
	
	$Sprite.frame = 1 if Globals.vswitch_timer > 0 else 0
	
	if Globals.game_paused or not (Globals.vswitch_timer > 0 or anim_timer > 0): return
	
	if anim_timer:
		$Sprite.position += Vector2(0,abs(anim_timer-10)*(-1 if anim_timer > 10 else 1)/4)
		anim_timer -= 1
	if not anim_timer: $Sprite.position = Vector2.ZERO
	
	Globals.vswitch_timer -= 1
	if not Globals.vswitch_timer:
		switch()

func switch():
	for block in block_list:
		block.vswitch_change_state()



func _on_PlayerAttackCheck_area_entered(area: Area2D) -> void:
	if not (area.get_collision_layer_bit(4) or area.get_collision_layer_bit(11)): return
	if anim_timer: $Sprite.position = Vector2.ZERO
	anim_timer = 20
	if Globals.vswitch_timer > 0:
		Globals.vswitch_timer = 0
	else:
		Globals.vswitch_timer = max_timer
	switch()

func _on_PlayerJumpCheck_area_entered(area: Area2D) -> void:
	if not area.get_collision_layer_bit(1): return
	if anim_timer: $Sprite.position = Vector2.ZERO
	anim_timer = 20
	if Globals.vswitch_timer > 0:
		Globals.vswitch_timer = 0
	else:
		Globals.vswitch_timer = max_timer
	switch()
