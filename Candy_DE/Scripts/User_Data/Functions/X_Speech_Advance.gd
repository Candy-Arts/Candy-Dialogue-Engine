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


#* Called when a Spoken_Line is advanced, by the player or by auto-advance:
#? After the displaying node's own x_speech_advance(), voice stop and history.
#? Not for undisplayed lines, or when the dialogue was stopped while the line waited.
@warning_ignore("unused_parameter")
func x_speech_advance(candy_args: Dictionary, user_args: Array, custom_data: Array):
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var line_data = candy_args["line_data"]
	var speech: CandySpeech = candy_args["speech"]
	@warning_ignore_restore("unused_variable")

	pass
