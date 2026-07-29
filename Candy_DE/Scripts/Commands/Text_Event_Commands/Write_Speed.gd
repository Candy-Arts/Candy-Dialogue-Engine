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
		printerr("Write_Speed: only works in a text event", _where(ctx), ". Skipped.")
		return "Continue"
	if typeof(command_value) != TYPE_DICTIONARY:
		return "Continue"

	var raw: Variant = command_value.get("Writing_Speed", "null")
	if CandySettings.is_not_set(raw):
		return "Continue"

	var value = engine.candy_ref.resolve_value(engine, engine, raw, candy_de.candy_ref_symbol)
	if engine.candy_ref.last_failed:
		printerr("Write_Speed: could not resolve 'Writing_Speed' → ", raw, _where(ctx), ". Skipped.")
		return "Continue"

	var text := str(value).strip_edges()
	if text.to_lower() == "reset":
		speech.write_speed = -1.0
		return "Continue"
	if not text.is_valid_float() or float(text) < 0.0:
		printerr("Write_Speed: 'Writing_Speed' can't be ", var_to_str(raw), " - expected a speed of 0 or more, or \"Reset\"", _where(ctx), ". Skipped.")
		return "Continue"

	speech.write_speed = float(text)
	return "Continue"


#* Line location, for reports:
func _where(ctx: CandyContext) -> String:
	if ctx == null:
		return ""
	return " (in %s > %s)" % [str(ctx.conversation), str(ctx.block)]
