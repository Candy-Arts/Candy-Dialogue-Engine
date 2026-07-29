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
	var time_raw: Variant		= engine.candy_ref.resolve_value(engine, engine, command_value.get("Wait_Time", 0.0), candy_de.candy_ref_symbol)

	var duration: float = float(CandyPlayback.get_shared().parse_timecode(engine, self, time_raw, false)["seconds"])

	#@ Step 1 - Nothing to wait for:
	#Ł Clear pending skip:
	if duration <= 0.0:
		engine.skip_wait = false
		return "Continue"

	#@ Step 2 - Wait loop:
	var start_time := Time.get_ticks_msec() / 1000.0
	while true:
		await engine.get_tree().process_frame

		#% Killswitch:
		if engine.killswitch == true:
			engine.skip_wait = false
			return "END"

		#% Suspended:
		if engine.dialogue_suspended == true:
			#Ł Push the deadline back:
			start_time += await engine._await_suspension()
			continue

		#% Skip:
		if engine.skip_wait:
			engine.skip_wait = false
			break

		var elapsed := (Time.get_ticks_msec() / 1000.0) - start_time
		if elapsed >= duration:
			break

	return "Continue"
