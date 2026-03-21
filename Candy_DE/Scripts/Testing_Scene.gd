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


extends Control

@export var dialogue = "test_dialogue"
@export var conversation = "Conversation_1"
@export var block = "Block_1"
@export var line = "0"


func _ready() -> void:
	test_start()

func test_start() -> void:
	#@ Run dialogue:
	candy_ui.load_scripted_dialogue(dialogue)
	candy_ui.start_dialogue(conversation, block, line)

