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

	var targets: Array = CandyUI.get_shared().get_element_targets(engine, self, "busts_path", command_value, "Actors", ["play_effect", "wait_effect"], "VN_Effect_Play", 2, true)

	#@ Step 1 - Start every effect:
	#? Only playback hooks are awaited, so targets start together.
	var started: Array = []
	for target in targets:
		if await target[0].play_effect(target[1], target[2], target[3]):
			started.append(target)

	#@ Step 2 - Wait on each effect in turn:
	#? Sequential waits end with the last target.
	for target in started:
		var feedback: String = await target[0].wait_effect(target[1], target[2], target[3])
		if feedback == "END":
			return "END"

	return "Continue"
