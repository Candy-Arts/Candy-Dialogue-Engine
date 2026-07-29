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


#* General history:
#? Call this from anywhere.
func open_general_history():
	var history_ui = get_node_or_null("")	#TODO: Path to your general history scene
	if history_ui == null:
		return
	history_ui.caller = null
	history_ui.show_history()
