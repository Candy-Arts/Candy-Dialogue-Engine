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


#* Called when a new command is processed:
@warning_ignore("unused_parameter")
func x_command_start(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var line_data = candy_args["line_data"]
	var command = candy_args["command"]
	var command_value = candy_args["command_value"]
	@warning_ignore_restore("unused_variable")

	pass
