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
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var command: String	= str(cr.resolve_value(engine, engine, command_value.get("Command", ""), sym)).strip_edges()
	var data: Variant	= cr.resolve_value(engine, engine, command_value.get("Data", ""), sym)

	#@ Step 1 - Find the script:
	if not engine.custom_event_registry.has(command.to_lower()):
		printerr("Conversation: " + str(ctx.conversation) + " Block: " + str(ctx.block) + " Line: " + str(ctx.line_index) + " - Custom command: no script for the 'Command' value '" + command + "' in the Custom_Events folder.")
		return "Continue"

	#@ Step 2 - Run it:
	var event_script: CandyCustomEvent = engine.custom_event_registry[command.to_lower()]
	@warning_ignore("redundant_await")
	var outcome: String = await event_script.handle(engine, data, ctx)

	if engine.killswitch == true or outcome == "END":
		return "END"

	if outcome == "Continue" or outcome == "Return":
		return outcome

	push_warning("Candy DE: Custom command '%s' returned '%s' - expected \"Continue\", \"Return\" or \"END\"." % [command, outcome])
	return "Continue"
