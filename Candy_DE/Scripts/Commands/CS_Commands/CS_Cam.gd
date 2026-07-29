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
	for target in CandyCutscene.get_shared().get_targets(engine, self, command_value, "Targets", "CS_Cam"):
		var cam: Node = target[0]
		if cam.has_method("make_current"):
			cam.make_current()
		elif "current" in cam:
			cam.current = true
		else:
			printerr("CS_Cam: not a camera → ", target[2])

	return "Continue"
