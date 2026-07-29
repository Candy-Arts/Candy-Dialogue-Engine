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

	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var condition_raw = command_value.get("Condition", "")
	var type_value = cr.resolve_value(engine, engine, command_value.get("Type", ""), sym)
	var cmd_type := ""
	if type_value != null:
		cmd_type = str(type_value).strip_edges()

	#@ Step 1 - Parse "<var> in <iterable>":
	#? e.g. "item in ¢globals.inventory". Split at the first " in " (names have no spaces).
	var condition_expr := str(condition_raw)
	if condition_expr.find(" in ") == -1:
		push_error("For: invalid condition syntax, expected \"<variable> in <iterable>\" → " + condition_expr)
		return "Continue"

	var parts = condition_expr.split(" in ", false, 1)
	var loop_var: String = parts[0].strip_edges()
	var iterable_raw: String = parts[1].strip_edges()

	if not iterable_raw.begins_with(sym):
		push_error("For: the iterable is plain text. Start it with " + sym + " to evaluate it → " + iterable_raw)
		return "Continue"

	#@ Step 2 - Evaluate the iterable:
	var iterable_value = cr.resolve_value(engine, engine, iterable_raw, sym)
	if cr.last_failed:
		push_error("For: could not evaluate the iterable → " + iterable_raw)
		return "Continue"

	var iterable: Array = []
	match typeof(iterable_value):
		TYPE_ARRAY:
			iterable = iterable_value
		TYPE_DICTIONARY:
			iterable = iterable_value.keys()
		TYPE_INT:
			#% 3 → 0, 1, 2:
			iterable = range(iterable_value)
		_:
			if typeof(iterable_value) >= TYPE_PACKED_BYTE_ARRAY and typeof(iterable_value) < TYPE_MAX:
				iterable = Array(iterable_value)
			else:
				push_error("For: the iterable is not an Array, Dictionary or number → " + str(iterable_value))
				return "Continue"

	#@ Step 3 - Add the loop variable:
	if not engine.for_.has(loop_var):
		engine.for_[loop_var] = null

	#@ Step 4 - Build fake_line:
	var dialogue_commands: Dictionary = command_value.get("Commands", {})
	if dialogue_commands.is_empty():
		printerr("For: no Commands defined.")
		return "Continue"

	var fake_line := CandyFlow.get_shared().commands_to_line(engine, self, dialogue_commands)

	#@ Step 5 - Loop:
	for val in iterable:
		engine.for_[loop_var] = val
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] For iteration: %s = %s, type: %s" % [loop_var, str(val), cmd_type])
		var feedback = await CandyFlow.get_shared().run_nested_line(engine, self, fake_line, current_conversation, current_block)
		if feedback == "END":
			return "END"
		elif feedback == "Return":
			return "Return"

	return "Continue"
