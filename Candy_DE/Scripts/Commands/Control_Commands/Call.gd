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

	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var func_raw			= command_value.get("Function", "")
	var store_var			= command_value.get("Variable", "")
	var await_call: String	= str(cr.resolve_value(engine, engine, command_value.get("Await", "1"), sym)).strip_edges()

	#% Validate:
	if typeof(func_raw) == TYPE_STRING and func_raw.strip_edges() == "":
		push_error("Call: \"Function\" is an empty string.")
		return "Continue"

	#@ Step 1 - Prepare arguments:
	var args_value = cr.resolve_value(engine, engine, command_value.get("Arguments", ""), sym)
	if cr.last_failed:
		printerr("Call: could not evaluate Arguments → ", command_value.get("Arguments", ""))
		return "Continue"

	var args: Array = []
	if typeof(args_value) == TYPE_ARRAY:
		args = args_value
	elif not (typeof(args_value) == TYPE_STRING and args_value == ""):
		args = [args_value]

	#@ Step 2 - Find the function:
	var target = CandyTargets.get_shared().resolve_named(engine, self, func_raw)
	if cr.last_failed or typeof(target) != TYPE_CALLABLE:
		printerr("Call: not a function → ", func_raw)
		return "Continue"

	var callable: Callable = target
	if callable.is_standard():
		if not CandyTargets.get_shared()._call_arity_ok(engine, self, callable.get_object(), callable.get_method(), args, current_conversation, current_block, line_index):
			return "Continue"

	#@ Step 3 - Call:
	var result_2
	if await_call == "1" or await_call == "true":
		result_2 = await callable.callv(args)
	else:
		result_2 = callable.callv(args)

	#@ Step 4 - Store the returned value:
	if not (typeof(store_var) == TYPE_STRING and store_var.strip_edges() == ""):
		#% Awaiting function called without Await - nothing returned yet:
		if result_2 is Object and is_instance_valid(result_2) and result_2.get_class() == "GDScriptFunctionState":
			printerr("Conversation: %s Block: %s Line: %s - Call: '%s' awaits, and Await is off, so it hadn't returned when the dialogue went on: nothing was stored in '%s'. Set Await to \"1\" to store what it returns."
				% [str(current_conversation), str(current_block), str(line_index), str(func_raw), str(store_var)])
			return "Continue"
		var found := cr.resolve_target(engine, engine, store_var, sym)
		if not found["ok"] or not CandyTargets.get_shared().write_target(engine, self, found, result_2, "=", "Call"):
			printerr("Call: failed to store result in → ", store_var)

	return "Continue"
