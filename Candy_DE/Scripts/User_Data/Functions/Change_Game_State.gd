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


#* Change game state when dialogue starts or ends:
@warning_ignore("unused_parameter")
func change_game_state(candy_args: Dictionary, user_args: Array, custom_data: Array):
	var caller = candy_args["caller"]
	var method = candy_args["method"]	#/ "start" or "end"

	var game_state		#/ Placeholder: replace with your own (e.g. global.game_state)
	var previous_state	#/ Placeholder: replace with your own (e.g. global.previous_state)

	#@ Step 1 - Setup:
	#Ł	Whether your game uses a game state tracker variable:
	var use_game_state = false		#TODO: Switch to true.

	#% No game state tracker:
	if use_game_state == false:
		return

	#% Only for the main Candy_UI:
	if caller.engine_mode != "UI":
		return

	#@ Step 2 - The value that represents "dialogue" in your game state tracker:
	var dialogue_state_value = "dialogue"	#TODO: your dialogue state value.

	#% If your game uses a game state tracker:
	if use_game_state == true:
		#¦ 1. When dialogue starts:
		if method == "start":
			#Ł Store the previous game state:
			@warning_ignore("unassigned_variable")
			previous_state = game_state	#TODO: replace both variables with your own.

			#Ł Set the dialogue state:
			game_state = dialogue_state_value	#TODO: replace global.game_state with your own.

		#¦ 2. When dialogue ends:
		if method == "end":
			#Ł Revert to the previous game state:
			game_state = previous_state	#TODO: replace both variables with your own.

			#+ To not revert when dialogue ends, change global.previous_state before it ends
			#+ (e.g. with the Call command), or modify the "end" code above.
