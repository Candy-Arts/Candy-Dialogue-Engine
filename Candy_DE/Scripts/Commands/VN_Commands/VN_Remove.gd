#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyCommand


func execute(engine: CandyEngine, command_value: Variant, _ctx: CandyContext) -> String:
	if engine.vn_mode != true:
		return "Continue"

	var targets: Array = CandyUI.get_shared().get_element_targets(engine, self, "busts_path", command_value, "Actors", ["remove_bust"], "VN_Remove", 1, true)

	#Ł Run the actors in JML_Order groups:
	await CandyUI.get_shared().run_in_order(engine, self, targets, "remove_bust")

	return "Continue"
