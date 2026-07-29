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


#& CLEAR VN BUSTS:
#* Clear VN busts when dialogue isn't running:
#? 'method' as in UI_Clear: 1 = clear silently, 2 = play each actor's Leave effect first.
func clear_busts_ood(caller, method: int = 1):
	if method != 1 and method != 2:
		printerr("clear_busts_ood(): invalid method (%s) - expected 1 or 2. Treated as 1." % str(method))
		method = 1

	#? Ignores the scene's Access setting:
	if caller.ui_elements_paths.has("busts_path"):
		var busts_root = caller.get_node_or_null(caller.ui_element_path("busts_path"))
		if busts_root:
			#% Hide first only when clearing silently:
			if method == 1:
				busts_root.visible = false
			await busts_root.clear_busts({"caller": caller}, method == 2)
			busts_root.visible = false
