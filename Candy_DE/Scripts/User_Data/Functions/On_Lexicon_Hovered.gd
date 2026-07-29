#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyFunction


#& LEXICON
#* When the mouse enters or leaves a Lexicon keyword:
#? Only for clickable keywords. A keyword's "Tooltip" needs no code: Godot shows it.
#TODO: Write the hover behavior.
@warning_ignore("unused_parameter")
func _on_lexicon_hovered(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var data = candy_args["data"]
	var caller = candy_args["caller"]
	var ui = candy_args["ui"]
	var hovered = candy_args["hovered"]

	var keyword = data["keyword"]
	var keyword_data = data["keyword_click_data"]
	var keyword_variation = data["keyword_variation"]
	@warning_ignore_restore("unused_variable")

	pass
