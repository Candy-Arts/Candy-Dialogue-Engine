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


func execute(engine: CandyEngine, command_value: Variant, ctx: CandyContext) -> String:
	var speech: CandySpeech = engine.text_event_speech
	if speech == null:
		printerr("Write_Pause: only works in a text event", _where(ctx), ". Skipped.")
		return "Continue"
	if typeof(command_value) != TYPE_DICTIONARY or speech.write_skipped:
		return "Continue"

	var time_raw: Variant = engine.candy_ref.resolve_value(engine, engine, command_value.get("Wait_Time", "0"), candy_de.candy_ref_symbol)
	var duration: float = float(CandyPlayback.get_shared().parse_timecode(engine, self, time_raw, false)["seconds"])
	if duration <= 0.0:
		return "Continue"

	var start_time := Time.get_ticks_msec() / 1000.0
	while true:
		await engine.get_tree().process_frame

		if engine.killswitch == true:
			return "Continue"

		#% Suspended:
		if engine.dialogue_suspended == true:
			start_time += await engine._await_suspension()
			continue

		#% Skip key:
		if InputMap.has_action(engine.input_skip_dialogue) and Input.is_action_pressed(engine.input_skip_dialogue) and engine.input_enabled == true:
			break
		if engine.skip_wait:
			engine.skip_wait = false
			break

		if (Time.get_ticks_msec() / 1000.0) - start_time >= duration:
			break

	return "Continue"


#* Line location, for reports:
func _where(ctx: CandyContext) -> String:
	if ctx == null:
		return ""
	return " (in %s > %s)" % [str(ctx.conversation), str(ctx.block)]
