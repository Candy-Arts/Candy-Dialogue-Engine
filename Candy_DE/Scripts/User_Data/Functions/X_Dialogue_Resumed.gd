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


#* Called when a suspended dialogue is resumed (resume_dialogue()):
#? After Candy DE resumes what it paused, right before the lines carry on.
#+ Resume what x_dialogue_suspended() paused.
#! Not awaited by resume_dialogue().
@warning_ignore("unused_parameter")
func x_dialogue_resumed(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var ending = candy_args["ending"]
	@warning_ignore_restore("unused_variable")

	pass
