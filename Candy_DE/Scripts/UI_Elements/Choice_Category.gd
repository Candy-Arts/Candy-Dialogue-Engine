#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################

extends Control

## REQUIRED: Parent for choice buttons.
@export var button_list: Node
## OPTIONAL: Node for displaying the category title.
@export var title_node: Node
## OPTIONAL: Node for displaying the category prompt.
@export var prompt_node: Node

var caller: Node

var parent_menu

var general_title = ""
var category_title = ""

var general_prompt = ""
var category_prompt = ""

var tags = ""



#* READY:
func _ready() -> void:
	pass


#* Setup:
@warning_ignore("unused_parameter")
func setup(custom_data: Array = []) -> void:
	_set_category_title()
	_set_category_prompt()


#* Redisplay texts in the current language, here and on every button:
func refresh_language():
	_set_category_title()
	_set_category_prompt()

	if button_list != null:
		for button in button_list.get_children():
			if button.has_method("refresh_language"):
				button.refresh_language()


#* Display the category title:
func _set_category_title():
	if title_node != null:
		#Ł Translate:
		title_node.text = CandyWriting.get_shared().translate(caller, self, str(category_title), "choice_category_titles")
		#Ł Hidden when empty, so it leaves no gap:
		title_node.visible = title_node.text != ""


#* Display the category prompt:
func _set_category_prompt():
	if prompt_node != null:
		#Ł Translate:
		prompt_node.text = CandyWriting.get_shared().translate(caller, self, str(category_prompt), "choice_category_prompts")
		#Ł Hidden when empty, so it leaves no gap:
		prompt_node.visible = prompt_node.text != ""
