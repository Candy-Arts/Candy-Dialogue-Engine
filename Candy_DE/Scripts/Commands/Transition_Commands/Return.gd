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
	#Ł Unpack context:
	var current_conversation = ctx.conversation
	var current_block = ctx.block
	var line_index = ctx.line_index

	var levels_str: String	= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Levels", "1"), candy_de.candy_ref_symbol)).strip_edges()

	#@ Step 1 - Validate Levels value:
	if levels_str == "":
		levels_str = "1"

	if not levels_str.is_valid_int():
		push_warning("Return: 'Levels' is not a valid integer ('%s') in %s > %s, line %s. Defaulting to 1."
			% [levels_str, current_conversation, current_block, str(line_index)])
		levels_str = "1"

	#@ Step 2 - Configure the return:
	var levels_raw := int(levels_str)
	if levels_raw == 0:
		engine.return_levels = -1					#/ Unlimited: unwind until the main Block.
		engine.return_end_on_overshoot = false
	else:
		engine.return_levels = abs(levels_raw)
		engine.return_end_on_overshoot = levels_raw < 0

	if OS.is_debug_build() and engine.debug_prints == true:
		var unwinding := str(engine.return_levels) + " Block(s)"
		if engine.return_levels == -1:
			unwinding = "to main"
		var overshoot := "stops at main"
		if engine.return_end_on_overshoot:
			overshoot = "ends dialogue"
		print("[DEBUG] Return: Levels = %d (unwinding %s, overshoot %s)." % [levels_raw, unwinding, overshoot])

	#. Hook call:
	#? "line" from the tracker: a nested line's own index is in its built line.
	#? "levels": 0 = to main, negative = may end the dialogue.
	await candy_de.run_hook("x_return", {"caller": engine, "line_data": ctx.line_data,
		"conversation": current_conversation, "block": current_block, "line": engine.line_tracker,
		"levels": levels_raw}, CandyCustomData.levels([command_value]))

	#@ Step 3 - Log the transition:
	CandyFlow.get_shared().log_transition(engine, self, "Return")

	return "Return"
