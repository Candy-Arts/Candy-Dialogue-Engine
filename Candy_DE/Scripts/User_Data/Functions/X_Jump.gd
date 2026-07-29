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


#* Called by the Jump command, before it leaves the current Block:
#? Only once its target is found.
#? Also for the Jump a choice's Finish transition or an If runs.
@warning_ignore("unused_parameter")
func x_jump(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var line_data = candy_args["line_data"]		#/ Transition or If: the line Candy DE built
	var conversation = candy_args["conversation"]
	var block = candy_args["block"]
	var line = candy_args["line"]		#/ Transition or If: the line holding it
	var new_conversation = candy_args["new_conversation"]
	var new_block = candy_args["new_block"]
	var new_line = candy_args["new_line"]
	@warning_ignore_restore("unused_variable")

	pass
