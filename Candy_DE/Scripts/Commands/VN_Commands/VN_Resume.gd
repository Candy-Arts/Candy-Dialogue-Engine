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

	#@ Step 1 - Resume every bust, keeping the fades the dialogue must wait for:
	var blocking: Array[Tween] = []
	for target in CandyUI.get_shared().get_element_targets(engine, self, "busts_path", command_value, "Actors", ["resume_bust"], "VN_Resume", 1, true):
		var fade: Variant = await target[0].resume_bust(target[1], target[2], target[3])
		if fade is Tween:
			blocking.append(fade)

	#@ Step 2 - Wait on each in turn:
	for fade in blocking:
		var feedback: String = await CandyPlayback.get_shared().await_tween(engine, self, fade)
		if feedback == "END":
			return "END"

	return "Continue"
