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


#* Called when a dialogue starts, right before its first line runs:
#? After change_game_state() runs and the engine is shown. Not called by a Jump (see x_jump()).
#! The dialogue only counts as running once this returns: interrupt_dialogue() can't stop it before.
@warning_ignore("unused_parameter")
func x_dialogue_start(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var conversation = candy_args["conversation"]
	var block = candy_args["block"]
	var line = candy_args["line"]
	@warning_ignore_restore("unused_variable")

	pass
