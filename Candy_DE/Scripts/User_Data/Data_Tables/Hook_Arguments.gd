#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyDataTable


#^ Hook Arguments:
#? Your own arguments for each hook, on top of Candy DE's.
#?
#? Every hook receives 'candy_args' (Candy DE's values), 'user_args' (built from its entry below)
#? and 'custom_data' (the calling line's Custom Data). Adding an argument here is all it takes.
#?
#? Keys are hook names, values are Arrays (no entry = empty Array). Entries are used as written,
#? unless they start with the CandyRef symbol (default '¢'): then they're evaluated on every call.
#! In order: 'user_args[0]' is the first entry, 'user_args[1]' the second, and so on.

#/ Example:
#/	"x_new_line": [
#/		"my literal value",		#/ used as-is        -> user_args[0]
#/		"¢globals.player_hp",	#/ evaluated on call -> user_args[1]
#/		"¢€score",				#/ a dialogue variable
#/	],

var hook_arguments = {

}
