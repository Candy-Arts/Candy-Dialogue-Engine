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

	#@ Step 1 - Start every change, keeping the fades the dialogue must wait for:
	var blocking: Array = []
	for target in cutscene.get_targets(engine, self, command_value, "Targets", "CS_Light"):
		var light: Node = target[0]
		if not (light is Light2D or light is Light3D):
			printerr("CS_Light: not a Light2D / Light3D → ", target[2])
			continue
		blocking.append_array(cutscene.change_light(engine, self, light, target[1], "CS_Light"))

	#@ Step 2 - Wait:
	return await cutscene.wait_fades(engine, self, blocking)
