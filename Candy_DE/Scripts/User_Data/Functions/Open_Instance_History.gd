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


#* Dialogue engine instance history:
#? Pass the right engine instance as 'caller'.
func open_instance_history(caller):
	if not caller.ui_elements_paths.has("history_display_path"):
		return
	var history_ui = caller.get_node_or_null(caller.ui_element_path("history_display_path"))
	if history_ui == null:
		return
	history_ui.caller = caller
	history_ui.show_history()
