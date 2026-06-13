#!###########################################################################################
#!																							#
#!         THIS SCRIPT CONTAINS CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS        #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                 Any unauthorized use constitutes copyright infringement.                 #
#!																							#
#!   This disclaimer must be featured at the top of any script featuring Candy Arts code,   #
#!                            and may not be removed or modified.                           #
#!																							#
#!###########################################################################################


extends Node3D

#^ Required Node Paths:
#? If you use your own custom node hierarchy, update these appropriately.
## Required
@export var label: RichTextLabel
## Required
@export var sprite: Sprite3D
## Required
@export var viewport: SubViewport

#^ Performance/Behavior Settings:
@export var y_offset = 0.0
@export var x_offset = 0.0
@export var z_offset = 0.0

@export var max_width := 256							#/ Max bubble width in pixels
@export var text_width_margin = 16						#/ Extra space on each side of the text.

## Default colors to use for spoken text and speaker names.
@export_group("Default Colors")
@export var enable_text_color: bool = true
@export var text_color = Color(0, 0, 0)					#/ Default override color - Custom spoken text color.

@export var default_z = 100

var override_color

var caller: Node



func _ready():
	#* Connect signal for clickable Lexicon words:
	#% Only used if the Lexicon is used in dialogues.
	if label is RichTextLabel:
		var callable = func(meta):
			var json_str = Marshalls.base64_to_variant(str(meta))
			var data = JSON.parse_string(json_str)
			if data is Dictionary:
				candy_de._on_lexicon_clicked(data, caller, self)
		if not label.is_connected("meta_clicked", callable):
			label.connect("meta_clicked", callable)


func show_text(spoken_text):
	self.visible = false	#/ Hide the speech bubble to prevent visual glitches while the function runs

	#% Set text color:
	label.add_theme_color_override("default_color", override_color)

	#% Reset max_width:
	label.size.x = max_width + text_width_margin

	#% Reset height (avoids extra empty lines):
	label.size.y = 0

	#% Assign text to label:
	label.text = spoken_text

	#% Get required width:
	var used_width = label.get_content_width()

	#% Apply required width:
	label.size.x = used_width + text_width_margin
	viewport.size = label.size

	await get_tree().process_frame

	#% Adjust the offset of the entire SpeechBubble based on size:
	self.position.y = y_offset + (label.size.y / 200)
	self.position.x += x_offset
	self.position.z += z_offset

	self.visible = true


#* Clear bubble:
func clear():
	self.visible = false
	label.text = ""


#* Hook function, called when writing begins:
func x_write_begun():
	pass


#* Hook function, called when writing finishes:
func x_write_finished():
	pass
