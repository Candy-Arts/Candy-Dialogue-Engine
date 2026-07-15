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

var general_custom = ""
var category_custom = ""

var tags = ""



#* READY:
func _ready() -> void:
	_set_category_title()
	_set_category_prompt()

#* Display the caregory's title:
func _set_category_title():
	var language = candy_de.language
	
	if title_node != null:
		if candy_de.choice_category_titles.has(category_title) and candy_de.choice_category_titles[category_title].has(language):
			title_node.text = candy_de.choice_category_titles[category_title][language]

		#% If translation missing from the localizations dictionary, use default value instead:
		else:
			title_node.text = category_title


#* Display a prompt for the category:
func _set_category_prompt():
	var language = candy_de.language
	
	if prompt_node != null:
		if candy_de.choice_category_prompts.has(category_prompt) and candy_de.choice_category_prompts[category_prompt].has(language):
			prompt_node.text = candy_de.choice_category_prompts[category_prompt][language]

		#% If translation missing from the localizations dictionary, use default value instead:		
		else:
			prompt_node.text = category_prompt