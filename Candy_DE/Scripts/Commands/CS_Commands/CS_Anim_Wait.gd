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
	var cutscene := CandyCutscene.get_shared()

	for target in cutscene.get_targets(engine, self, command_value, "Targets", "CS_Anim_Wait"):
		var node := cutscene.anim_node(engine, self, target[0], target[1], "CS_Anim_Wait")
		if node == null:
			continue
		if await cutscene.wait_node(engine, self, node, target[1], "CS_Anim_Wait") == "END":
			return "END"

	return "Continue"
