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

	var condition_raw = command_value.get("Condition", "")
	var type_value = engine.candy_ref.resolve_value(engine, engine, command_value.get("Type", ""), candy_de.candy_ref_symbol)
	var cmd_type := ""
	if type_value != null:
		cmd_type = str(type_value).strip_edges()

	var safety_counter := 0

	#@ Step 1 - Build fake_line:
	var dialogue_commands: Dictionary = command_value.get("Commands", {})
	if dialogue_commands.is_empty():
		printerr("While: no Commands defined.")
		return "Continue"

	var fake_line := CandyFlow.get_shared().commands_to_line(engine, self, dialogue_commands)

	#@ Step 2 - Loop:
	while true:
		if candy_de.while_safety_break > 0 and safety_counter >= candy_de.while_safety_break:
			push_error("While: safety break reached (" + str(candy_de.while_safety_break) + " iterations). This limit can be modified or disabled in Candy_Properties.gd.")
			break
		safety_counter += 1

		#% False or broken condition:
		if CandyValues.get_shared().evaluate_condition(engine, self, condition_raw, "While") != 1:
			break

		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] While iteration %d, type: %s" % [safety_counter, cmd_type])

		var feedback = await CandyFlow.get_shared().run_nested_line(engine, self, fake_line, current_conversation, current_block)
		if feedback == "END":
			return "END"
		elif feedback == "Return":
			return "Return"

	return "Continue"
