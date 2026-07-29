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
	var bg_scene := CandyUI.get_shared().get_element(engine, self, "backgrounds_path")
	if bg_scene != null and not CandyPlayback.get_shared().admit(engine, self, bg_scene, "backgrounds_path", command_value.get("Take_Hold", ""), "BG_Scene"):
		return "Continue"

	CandyUI.get_shared().swap_scene(engine, self, "backgrounds_path", command_value.get("Scene", ""), candy_de.bg_scenes_folder, "BG_Scene")
	return "Continue"
