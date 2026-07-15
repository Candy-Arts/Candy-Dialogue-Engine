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


extends Node

## Required: Displays spoken text
@export var dialogue_node: Node
## Required: Displays speaker name
@export var speaker_node: Node

## Default colors to use for spoken text and speaker names.
@export_group("Default Colors")
@export var enable_text_color: bool = true
@export var text_color = Color(1, 1, 1)
@export var enable_speaker_color: bool = true
@export var speaker_color = Color(1, 1, 1)

@export var default_z = 100

var caller: Node

func _ready():
	self.z_index = default_z

	#@ Connect signal for clickable Lexicon words:
	#% Only used if the Lexicon is used in dialogues.
	if dialogue_node is RichTextLabel:
		var callable = func(meta):
			var json_str = Marshalls.base64_to_variant(str(meta))
			var data = JSON.parse_string(json_str)
			if data is Dictionary:
				candy_de._on_lexicon_clicked(data, caller, self)
		if not dialogue_node.is_connected("meta_clicked", callable):
			dialogue_node.connect("meta_clicked", callable)


#* Hook function, called when writing begins:
func x_write_begun():
	pass


#* Hook function, called when writing finishes:
func x_write_finished():
	pass