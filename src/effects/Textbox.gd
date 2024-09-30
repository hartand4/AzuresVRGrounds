extends CanvasLayer

# Textboxes can hold 8 lines of text

# Colour constants for characters
const COLORS = ['#92BCE5', '#D8D8D8', '#EFB36E', '#D37B47', '#BE67B4', '#E29EBC',
	'#FF9E75', '#F7BE99', '#E0857D', '#A5E27C', '#E9ECF6', '#898989', '#BFDAFF',
	'#576C72', '#E0C3D8', '#A198D1', '#C18670']
# Colour constants for shadows (font_color_shadow)
const SHADOW_COLORS = ['#195DA5', '#3D3D3D', '#443626', '#442818', '#492846',
	'#49333D', '#492D22', '#44342A', '#442727', '#3A492F', '#303C51', '#352525',
	'#3F2B21', '#263033', '#4C3446', '#3C2C4C', '#3F1F1B']
# Dictionary for characters
const CHARACTER_DICT = {"azure":0, "arle":1, "bailey":2, "casey":3, "chives":4, "dexter":5,
	"eloise":6, "emelia":7, "faie":8, "glow":9, "gospelle":10, "hal":11, "lazuli":12,
	"olivia":13, "taylor":14, "valerie":15, "yui":16}
# Default text speed
const DEFAULT_SPEED = 28


var char_amt = 0
var shifting_amt = 0
var buffer = ''
var character = -1
var expression = 0
var text_speed = DEFAULT_SPEED
var line_num = 0
var timer = 0
var clearing_text = false

var is_waiting = false

var create_timer = 80
var destroy_timer = 0
var destroy_instantly = false

func init(text, instant=false, destroy_instant=false):
	if instant:
		visible = true
		create_timer = 0
	else:
		$Blackground.rect_size.y = 6
		$Blackground.rect_position.y = 213
		$Blackground.rect_position.x = 420
		$Blackground.rect_size.x = 0
		$Blackground/Portrait.visible = false
	
	buffer = text
	is_waiting = false
	text_speed = DEFAULT_SPEED
	line_num = 0
	char_amt = 0
	destroy_instantly = destroy_instant

func _ready():
	$Blackground/Margins/Label.bbcode_text = ''
	#$Blackground/Label.bbcode_text += '[img=20x20]res://assets/Sprites/Textbox Portraits/AzureNew.png[/img]'


func _process(_delta):
	if create_timer > 0:
		create_textbox_slow()
		create_timer = max(0, create_timer-1)
		if create_timer == 0:
			$Blackground/Portrait.visible = true
		return
	elif destroy_timer > 0:
		$Blackground/TextboxNextButton.visible = false
		destroy_animation()
		destroy_timer = int(max(0, destroy_timer - 1))
		if destroy_timer == 0:
			visible = false
			queue_free()
		return
	
	$Blackground/TextboxNextButton.visible = is_waiting and (timer % 60 >= 30) and shifting_amt == 0
	if shifting_amt > 0:
		$Blackground/Margins/Label.rect_size.y += 5
		$Blackground/Margins/Label.rect_position.y -= 5
		shifting_amt -= 5
		if shifting_amt == 0 and clearing_text:
			$Blackground/Margins/Label.rect_size.y = 320
			$Blackground/Margins/Label.rect_position.y = 8
			$Blackground/Margins/Label.bbcode_text = '[color=%s]' % COLORS[character]
			line_num = 0
			clearing_text = false
		return
	timer += 1
	if is_waiting:
		if advanced_textbox():
			is_waiting = false
			if buffer != '':
				shifting_amt = 40*(line_num+2) if clearing_text else 40
				line_num -= 1 if !clearing_text else 0
			else:
				destroy_textbox(destroy_instantly)
		return
	elif buffer == '':
		print('done')
		is_waiting = true
		return
	
	if timer % max(1,32-text_speed) > 0 and !Input.is_action_pressed("pause") and\
		!Input.is_action_pressed("attack") and !Input.is_action_just_pressed("jump"): return
	
	var characters_to_display = 1
	if Input.is_action_pressed("pause"): characters_to_display = 8
	elif Input.is_action_pressed("attack"): characters_to_display = 2
	elif Input.is_action_just_pressed("jump"): characters_to_display = 10000
	
	for _i in range(characters_to_display):
		if is_waiting or buffer.length() == 0: break
		
		check_special_tags()
		if clearing_text: return
		
		var buffer_next_space = find_space()
		var char_limit = 30
		if (buffer_next_space > char_limit-char_amt) or (buffer_next_space < 0 and
		buffer.length() > char_limit-char_amt):
			print('print new line')
			$Blackground/Margins/Label.bbcode_text += "\n"
			char_amt = 0
			if line_num >= 7:
				is_waiting = true
				return
			line_num += 1
			return
		
		char_amt += 1
		$Blackground/Margins/Label.bbcode_text += buffer[0]
		buffer = buffer.substr(1)

# UNUSED: Adds text to a textbox, with an option for a character name and a facial expression
func draw_text(text, char_name='', face=0):
	expression = face
	$Blackground/Margins/Label.remove_color_override("font_color_shadow")
	if char_name != '':
		character = CHARACTER_DICT[char_name.to_lower()]
		$Blackground/Margins/Label.add_color_override("font_color_shadow", Color(SHADOW_COLORS[character]))
		buffer = '[instant][color=%s]--%s--[/instant]\\n' % [COLORS[character], char_name.to_upper()]
		buffer += text
	else:
		character = -1
		buffer = text
		$Blackground/Margins/Label.add_color_override("font_color_shadow", Color("111111"))
	is_waiting = false
	text_speed = DEFAULT_SPEED
	line_num = 0
	char_amt = 0

# Checks if input was pressed to advance textbox
func advanced_textbox():
	return Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or\
		Input.is_action_pressed("pause")

# Checks specific tags that I made
func check_special_tags():
	var temp_substr = ''
	
	# Changes the speed value of the text
	if buffer.find('[speed=') == 0:
		temp_substr = buffer.substr(7, buffer.find(']')-buffer.find('=') - 1)
		text_speed = int(temp_substr)
		buffer = buffer.substr(buffer.find(']') + 1)
		check_special_tags()
		return
	
	# Makes the text instantly appear until the [/instant] tag
	if buffer.find('[instant]') == 0:
		temp_substr = buffer.substr(9, buffer.find('[/instant]')-9)
		$Blackground/Margins/Label.bbcode_text += temp_substr
		buffer = buffer.substr(buffer.find('[/instant]') + 10)
		char_amt += temp_substr.length()
		check_special_tags()
		return
	
	# Adds a line break
	if buffer.find('\\n') == 0:
		$Blackground/Margins/Label.bbcode_text += '\n'
		buffer = buffer.substr(2)
		line_num += 1
		char_amt = 0
		timer = 0
		check_special_tags()
		return
	
	# Waits for player input and then clears the textbox
	if buffer.find('\\c') == 0:
		buffer = buffer.substr(2)
		char_amt = 0
		timer = 0
		is_waiting = true
		clearing_text = true
		return
	
	# Changes the character portrait and face ([character=azure,0])
	if buffer.find('[character=') == 0:
		temp_substr = buffer.substr(11, buffer.find(']') - 11)
		buffer = buffer.substr(buffer.find(']') + 1)
		if temp_substr == '':
			character = -1
			$Blackground/Margins/Label.bbcode_text += '[color=#ffffff]'
			$Blackground/Margins/Label.remove_color_override("font_color_shadow")
			$Blackground/Margins/Label.add_color_override("font_color_shadow", Color("444444"))
		else:
			var temp_character_substr = temp_substr.substr(0, temp_substr.find(','))
			character = CHARACTER_DICT[temp_character_substr.to_lower()]
			$Blackground/Margins/Label.remove_color_override("font_color_shadow")
			$Blackground/Margins/Label.add_color_override("font_color_shadow", Color(SHADOW_COLORS[character]))
			buffer = ('[instant][color=%s]--%s--[/instant]\\n' % [COLORS[character],\
				temp_character_substr.to_upper()]) + buffer
			expression = int(temp_substr.substr(temp_substr.find(',')+1))
		
		check_special_tags()
		return

# Finds the index of the next space, line break or clear command, whichever first
func find_space():
	var space_pos = buffer.find(" ") if buffer.find(" ") >= 0 else 2000
	var newline_pos = buffer.find("\\n") if buffer.find("\\n") >= 0 else 2000
	var clear_pos = buffer.find("\\c") if buffer.find("\\c") >= 0 else 2000
	var min_of_the_pos = int(min(min(space_pos, newline_pos), clear_pos))
	return min_of_the_pos if min_of_the_pos < 2000 else -1

# Creates a textbox with an animation
func create_textbox_slow():
	# 28 frames of this
	if create_timer < 28:
		$Blackground.rect_size.y += 12
		$Blackground.rect_position.y -= 6
	elif create_timer == 28:
		$Blackground.rect_size.y = 6
		$Blackground.rect_position.y = 213
	else:
		$Blackground.rect_size.x += 12
		$Blackground.rect_position.x -= 6

# Destroys the textbox
func destroy_textbox(instant):
	if instant:
		queue_free()
	destroy_timer = 80

# Does the destroy animation
func destroy_animation():
	# 28 frames of this
	if destroy_timer > 52:
		$Blackground.rect_size.y -= 12
		$Blackground.rect_position.y += 6
		$Blackground/Margins.rect_position.y -= 6
		$Blackground/Portrait.position.y -= 6
	elif destroy_timer == 52:
		$Blackground.rect_size.y = 6
		$Blackground.rect_position.y = 213
		$Blackground/Margins.visible = false
		$Blackground/Portrait.visible = false
	else:
		$Blackground.rect_size.x -= 12
		$Blackground.rect_position.x += 6
		$Blackground/Margins.rect_position.x -= 6
		$Blackground/Portrait.position.x -= 6
