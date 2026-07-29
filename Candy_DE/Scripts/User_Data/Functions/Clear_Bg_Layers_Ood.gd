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


#& CLEAR BG LAYERS:
#* Clear BG layers when dialogue isn't running:
#? Ignores the scene's Access setting.
func clear_bg_layers_ood(caller):
	if not caller.ui_elements_paths.has("backgrounds_path"):
		return
	var bg_root = caller.get_node_or_null(caller.ui_element_path("backgrounds_path"))
	if bg_root:
		bg_root.visible = false
		bg_root.clear_layers()
