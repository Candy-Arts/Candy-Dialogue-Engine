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

	var bust_scene := CandyUI.get_shared().get_element(engine, self, "busts_path")
	if bust_scene != null and not CandyPlayback.get_shared().admit(engine, self, bust_scene, "busts_path", command_value.get("Take_Hold", ""), "VN_Scene"):
		return "Continue"

	CandyUI.get_shared().swap_scene(engine, self, "busts_path", command_value.get("Scene", ""), candy_de.bust_scenes_folder, "VN_Scene")
	return "Continue"
