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
	#@ Step 1 - Start fades, keep blocking ones:
	var blocking: Array[Tween] = []
	for target in CandyPlayback.get_shared().get_media_targets(engine, self, command_value, "Players", ["volume_media"], "Media_Volume"):
		var fade: Tween = target[0].volume_media(target[1], target[2], target[3])
		if fade != null:
			blocking.append(fade)

	#@ Step 2 - Wait for blocking fades:
	for fade in blocking:
		var feedback: String = await CandyPlayback.get_shared().await_tween(engine, self, fade)
		if feedback == "END":
			return "END"

	return "Continue"
