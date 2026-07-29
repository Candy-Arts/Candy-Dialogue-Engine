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


#* Called by the Return command, before it leaves the current Block:
#? Not when a bridged Block returns by reaching its last line.
#? Also for the Return a choice's Finish transition or an If runs.
@warning_ignore("unused_parameter")
func x_return(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var line_data = candy_args["line_data"]		#/ Transition or If: the line Candy DE built
	var conversation = candy_args["conversation"]
	var block = candy_args["block"]
	var line = candy_args["line"]		#/ Transition or If: the line holding it
	var levels = candy_args["levels"]
	@warning_ignore_restore("unused_variable")

	pass
