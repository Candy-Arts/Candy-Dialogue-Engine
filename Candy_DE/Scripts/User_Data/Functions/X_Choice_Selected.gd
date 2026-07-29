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


#* Called when a choice is selected, by the player or by a timer's Timer_Choices:
#? Before navigating to another category or running the Finish transition.
#? Not for inactive choices. The menu's timers are paused meanwhile.
@warning_ignore("unused_parameter")
func x_choice_selected(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var menu = candy_args["menu"]
	var category = candy_args["category"]
	var choice = candy_args["choice"]
	var button = candy_args["button"]
	var choice_data = candy_args["choice_data"]
	@warning_ignore_restore("unused_variable")

	pass
