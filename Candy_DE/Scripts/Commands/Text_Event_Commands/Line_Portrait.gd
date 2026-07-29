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
		printerr("Line_Portrait: only works in a text event", _where(ctx), ". Skipped.")
		return "Continue"
	if typeof(command_value) != TYPE_DICTIONARY:
		return "Continue"

	var display_node: Node = speech.display_node
	if display_node == null or not is_instance_valid(display_node):
		return "Continue"

	var custom_data: Array = CandyCustomData.levels([command_value])
	var action := _value(engine, command_value, "Action", "", ctx).to_lower()
	var portraits: Array = []
	if display_node.has_method("portrait_nodes"):
		portraits = display_node.portrait_nodes()

	match action:
		"show":
			if not display_node.has_method("show_line_portrait"):
				printerr("Line_Portrait: '", display_node.name, "' has no show_line_portrait() function, so it can't show another portrait", _where(ctx), ".")
				return "Continue"
			speech.portrait_raw = _value(engine, command_value, "Portrait", speech.portrait_raw, ctx, false)
			speech.sprite_frames_raw = _value(engine, command_value, "Sprite_Frames_File", speech.sprite_frames_raw, ctx, false)
			speech.play_portrait = _value(engine, command_value, "Portrait_Play", speech.play_portrait, ctx)
			speech.portrait_stop = _value(engine, command_value, "Portrait_Stop", speech.portrait_stop, ctx)
			@warning_ignore("redundant_await")
			await display_node.show_line_portrait(engine, speech, custom_data)

		"pause":
			for portrait in portraits:
				CandyPortrait.get_shared().pause_portrait(engine, self, portrait)

		"resume":
			for portrait in portraits:
				CandyPortrait.get_shared().resume_portrait(engine, self, portrait)

		"stop":
			var stop_frame := CandyPortrait.stop_frame_of(_value(engine, command_value, "Frame", speech.portrait_stop, ctx))
			var on_removed := Callable()
			if stop_frame == CandyPortrait.STOP_REMOVE and display_node.has_method("no_portrait"):
				on_removed = display_node.no_portrait
			for portrait in portraits:
				CandyPortrait.get_shared().stop_portrait(engine, self, portrait, stop_frame, on_removed)

		"frame":
			var frame_text := _value(engine, command_value, "Frame", "", ctx)
			if not frame_text.is_valid_int() or int(frame_text) == 0 or int(frame_text) < CandyPortrait.STOP_LAST:
				printerr("Line_Portrait: 'Frame' can't be '", frame_text, "' - expected a frame number from 1, or -1 for the last", _where(ctx), ". Skipped.")
				return "Continue"
			for portrait in portraits:
				CandyPortrait.get_shared().seek_portrait(engine, self, portrait, int(frame_text))

		_:
			printerr("Line_Portrait: 'Action' can't be '", action, "' - expected Show, Pause, Resume, Stop or Frame", _where(ctx), ". Skipped.")

	return "Continue"


#* A key's value as text, or 'fallback' if "null":
func _value(engine: CandyEngine, command_value: Dictionary, key: String, fallback: String, ctx: CandyContext, evaluate: bool = true) -> String:
	var raw: Variant = command_value.get(key, "null")
	if CandySettings.is_not_set(raw):
		return fallback
	if not evaluate:
		return str(raw)		#/ ¢ expression kept: CandyPortrait evaluates it
	var value = engine.candy_ref.resolve_value(engine, engine, raw, candy_de.candy_ref_symbol)
	if engine.candy_ref.last_failed:
		printerr("Line_Portrait: could not resolve '", key, "' → ", raw, _where(ctx), ". Using ", var_to_str(fallback), ".")
		return fallback
	return str(value).strip_edges()


#* Line location, for reports:
func _where(ctx: CandyContext) -> String:
	if ctx == null:
		return ""
	return " (in %s > %s)" % [str(ctx.conversation), str(ctx.block)]
