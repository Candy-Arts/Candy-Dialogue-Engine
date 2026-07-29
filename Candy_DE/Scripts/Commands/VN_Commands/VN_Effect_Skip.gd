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

	for target in CandyUI.get_shared().get_element_targets(engine, self, "busts_path", command_value, "Actors", ["skip_effect"], "VN_Effect_Skip", 2, true):
		target[0].skip_effect(target[1], target[2], target[3])

	return "Continue"
