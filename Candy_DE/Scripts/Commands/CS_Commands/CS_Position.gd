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

	#@ Step 1 - Start every move, keeping the ones the dialogue must wait for:
	var blocking: Array = []
	for marker_entry in cutscene.get_targets(engine, self, command_value, "Markers", "CS_Position"):
		for target in cutscene.get_targets(engine, self, marker_entry[1], "Nodes", "CS_Position"):
			blocking.append_array(cutscene.move_to_marker(engine, self, target[0], marker_entry[0], target[1],
				target[2], marker_entry[2], "CS_Position"))

	#@ Step 2 - Wait:
	return await cutscene.wait_fades(engine, self, blocking)
