#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node
## Dialogue file to load.
@export var dialogue = "test_dialogue"
## Conversation to start at.
@export var conversation = "Conversation_1"
## Block to start at.
@export var block = "Block_1"
## Line to start at.[br][br]
## Can be a line index or an LM reference.
@export var line = "0"


func _ready() -> void:
	test_start()


func test_start() -> void:
	#Ł Run dialogue:
	candy_ui.load_scripted_dialogue(dialogue)
	candy_ui.start_dialogue(conversation, block, line)


func _on_button_3_pressed() -> void:
	candy_ui.interrupt_dialogue()

func _on_button_2_pressed() -> void:
	candy_ui.resume_dialogue()

func _on_button_pressed() -> void:
	candy_ui.suspend_dialogue()