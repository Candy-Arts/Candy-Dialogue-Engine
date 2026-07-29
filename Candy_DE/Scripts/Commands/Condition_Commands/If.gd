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

	var type_value = engine.candy_ref.resolve_value(engine, engine, command_value.get("Type", ""), candy_de.candy_ref_symbol)
	var cmd_type := ""
	if type_value != null:
		cmd_type = str(type_value).strip_edges()

	#@ Step 1 - Pad if_array to depth:
	while engine.if_array.size() < engine.nesting_depth:
		engine.if_array.append(-1)

	#@ Step 2 - Evaluate the condition (1 = true, 0 = false, IF_ERROR = broken):
	#? Broken keeps Elif and Else out of the chain.
	var chain_state := CandyValues.get_shared().evaluate_condition(engine, self, command_value.get("Condition", ""), "If")

	#@ Step 3 - Replace this depth's chain:
	if engine.if_array.size() > engine.nesting_depth:
		engine.if_array.remove_at(engine.nesting_depth)
	engine.if_array.insert(engine.nesting_depth, chain_state)

	if chain_state == CandyEngine.IF_ERROR:
		return "Continue"
	var cond_result := chain_state == 1

	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] If chain at depth %d → if_array=%s" % [engine.nesting_depth, str(engine.if_array)])

	if cond_result:
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] If condition TRUE at depth %d, type: %s" % [engine.nesting_depth, cmd_type])

		var dialogue_commands: Dictionary = command_value.get("Commands", {})
		if dialogue_commands.is_empty():
			printerr("If: condition TRUE but no Commands defined.")
			return "Continue"

		#Ł Build and run fake_line:
		var fake_line := CandyFlow.get_shared().commands_to_line(engine, self, dialogue_commands)

		var feedback = await CandyFlow.get_shared().run_nested_line(engine, self, fake_line, current_conversation, current_block)
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Exiting If body at depth %d → if_array=%s" % [engine.nesting_depth, str(engine.if_array)])

		return feedback

	else:
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] If condition FALSE at depth %d" % engine.nesting_depth)

	return "Continue"
