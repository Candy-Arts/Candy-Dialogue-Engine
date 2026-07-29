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
	var targets: Array = CandyPlayback.get_shared().get_media_targets(engine, self, command_value, "Players", ["wait_media"], "Media_Wait")

	#@ Step 1 - Wait on each player:
	for target in targets:
		var feedback: String = await target[0].wait_media(target[1], target[2], target[3])
		if feedback == "END":
			return "END"

	#@ Step 2 - Apply "Box":
	for target in targets:
		if target[2].has("Box") and target[0].has_method("ui_media"):
			target[0].ui_media(target[1], target[2], target[3])

	return "Continue"
